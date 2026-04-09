// @ts-nocheck
// Edge Function: sincroniza indicadores económicos desde SIPSA (DANE)
// hacia la tabla info_mercado. RF-C-05, RF-C-06.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Max-Age": "86400",
};

interface IndicadorEntrada {
  producto_tipo: string;
  precio_promedio: number;
  rango_min?: number;
  rango_max?: number;
  unidad?: string;
  fuente?: string;
}

const SIPSA_WSDL_ENDPOINT =
  "https://appweb.dane.gov.co:443/sipsaWS/SrvSipsaUpraBeanService";
const SIPSA_TNS = "http://servicios.sipsa.co.gov.dane/";
// Nota: `promediosSipsaParcial` suele devolver un XML muy grande y tarda demasiado.
// Para el prototipo usamos `promediosSipsaSemanaMadr`, que en pruebas toma ~20s.
const SIPSA_OPERATION = "promediosSipsaSemanaMadr";

function toNumber(v: string | null): number | null {
  if (v == null) return null;
  const s = v.trim();
  if (!s) return null;
  // En caso de que venga con coma decimal.
  const normalized = s.replace(",", ".");
  const n = Number(normalized);
  return Number.isFinite(n) ? n : null;
}

function firstChildText(el: Element, tagName: string): string | null {
  const child =
    el.getElementsByTagNameNS("*", tagName)[0] ??
    el.getElementsByTagName(tagName)[0];
  return child?.textContent ?? null;
}

function normalizeProductoKey(s: string): string {
  // Normaliza tildes para mejorar el match con los nombres de SIPSA.
  const lower = s.trim().toLowerCase();
  return lower
    .replace(/[áàäâ]/g, "a")
    .replace(/[éèëê]/g, "e")
    .replace(/[íìïî]/g, "i")
    .replace(/[óòöô]/g, "o")
    .replace(/[úùüû]/g, "u")
    .replace(/[ñ]/g, "n");
}

async function fetchSipsaMayoristasParcial(): Promise<IndicadorEntrada[]> {
  // operación: SIPSA_OPERATION
  const soapBody = `
    <soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tns="${SIPSA_TNS}">
      <soapenv:Header/>
      <soapenv:Body>
        <tns:${SIPSA_OPERATION}/>
      </soapenv:Body>
    </soapenv:Envelope>
  `.trim();

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000); // evita que el navegador se quede colgado
  const res = await fetch(SIPSA_WSDL_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": `application/soap+xml; charset=utf-8; action="${SIPSA_OPERATION}"`,
      SOAPAction: SIPSA_OPERATION,
      Accept: "application/soap+xml",
    },
    body: soapBody,
    signal: controller.signal,
  }).finally(() => clearTimeout(timeout));

  if (!res.ok) {
    throw new Error(`SIPSA respondió con ${res.status}`);
  }

  const xml = await res.text();

  // Parsing rápido (evita DOMParser con XML grande).
  // Extraemos bloques <return> y dentro capturamos solo los campos necesarios.
  const reReturn = /<(?:\w+:)?return>([\s\S]*?)<\/(?:\w+:)?return>/g;
  const reArtiNombre =
    /<(?:\w+:)?artiNombre>([^<]*)<\/(?:\w+:)?artiNombre>/;
  const rePromedioKg =
    /<(?:\w+:)?promedioKg>([^<]*)<\/(?:\w+:)?promedioKg>/;
  const reMinimoKg =
    /<(?:\w+:)?minimoKg>([^<]*)<\/(?:\w+:)?minimoKg>/;
  const reMaximoKg =
    /<(?:\w+:)?maximoKg>([^<]*)<\/(?:\w+:)?maximoKg>/;

  // Para que el sync sea rápido en web, limitamos por defecto a productos clave.
  // Puedes sobreescribirlo con env: INDICADORES_PRODUCTOS="Maíz,Fríjol,Papa,..."
  const productosEnv = Deno.env.get("INDICADORES_PRODUCTOS") ?? "";
  const allowedListRaw =
    productosEnv.trim().length > 0
      ? productosEnv
      : "Maíz,Fríjol,Papa,Plátano,Café pergamino";
  const allowedTokens = new Set(
    allowedListRaw
      .split(",")
      .map((s) => normalizeProductoKey(s))
      .filter(Boolean)
  );

  type Acc = { sum: number; count: number; min: number | null; max: number | null };
  const accByProducto = new Map<string, Acc>();

  let matchCount = 0;
  const MAX_RETURN_MATCHES = 15000; // evita recorrer XML completo si no coincide nombres
  for (const m of xml.matchAll(reReturn)) {
    matchCount += 1;
    if (matchCount > MAX_RETURN_MATCHES) break;
    const block = m[1];
    if (!block) continue;

    const a = reArtiNombre.exec(block);
    const producto = a?.[1]?.trim();
    if (!producto) continue;

    // Si está fuera de la lista permitida, saltar (mejora tiempo).
    const keyLower = normalizeProductoKey(producto);
    const tokenMatched = Array.from(allowedTokens).some((t) =>
      keyLower.includes(t)
    );
    if (!tokenMatched) continue;

    const promedio = toNumber(rePromedioKg.exec(block)?.[1] ?? null);
    const minimo = toNumber(reMinimoKg.exec(block)?.[1] ?? null);
    const maximo = toNumber(reMaximoKg.exec(block)?.[1] ?? null);

    const acc = accByProducto.get(producto) ?? {
      sum: 0,
      count: 0,
      min: null,
      max: null,
    };

    if (promedio != null) {
      acc.sum += promedio;
      acc.count += 1;
    }
    if (minimo != null) acc.min = acc.min == null ? minimo : Math.min(acc.min, minimo);
    if (maximo != null) acc.max = acc.max == null ? maximo : Math.max(acc.max, maximo);

    accByProducto.set(producto, acc);
    if (accByProducto.size >= 25) break; // límite para que sea rápido
  }

  if (accByProducto.size === 0) {
    throw new Error("SIPSA: no se extrajeron indicadores (lista permitida puede no coincidir con artiNombre)");
  }

  const indicadores: IndicadorEntrada[] = [];
  for (const [producto, acc] of accByProducto.entries()) {
    const precioPromedio = acc.count > 0 ? acc.sum / acc.count : null;
    if (precioPromedio == null) continue;
    indicadores.push({
      producto_tipo: producto,
      precio_promedio: precioPromedio,
      rango_min: acc.min ?? undefined,
      rango_max: acc.max ?? undefined,
      unidad: "kg",
      fuente: "SIPSA (mayoristas - promedios semanales)",
    });
  }

  return indicadores;
}

async function sincronizarIndicadores(): Promise<{
  actualizados: number;
  fuente: string;
}> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const apiUrl = Deno.env.get("INDICADORES_API_URL");

  let indicadores: IndicadorEntrada[] = [];
  let fuente = "SIPSA";

  // Prioridad: si se configura INDICADORES_API_URL, se usa; si no, SIPSA.
  if (apiUrl && apiUrl.trim() !== "") {
    const res = await fetch(apiUrl.trim(), {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) {
      throw new Error(`Fuente externa respondió con ${res.status}`);
    }
    const data = await res.json();
    const arr = Array.isArray(data)
      ? data
      : data.indicadores ?? data.data ?? [];
    if (!Array.isArray(arr) || arr.length === 0) {
      throw new Error("La fuente externa no devolvió indicadores");
    }
    indicadores = arr as IndicadorEntrada[];
    fuente = "API externa";
  } else {
    indicadores = await fetchSipsaMayoristasParcial();
  }

  const filas = indicadores.map((ind) => ({
    producto_tipo: String(ind.producto_tipo).trim(),
    precio_promedio: Number(ind.precio_promedio) || null,
    rango_min: ind.rango_min != null ? Number(ind.rango_min) : null,
    rango_max: ind.rango_max != null ? Number(ind.rango_max) : null,
    unidad: ind.unidad ?? "kg",
    fuente: ind.fuente ?? "SIPSA / Datos abiertos",
    updated_at: new Date().toISOString(),
  }));

  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  const { error } = await supabase.from("info_mercado").upsert(filas, {
    onConflict: "producto_tipo",
    ignoreDuplicates: false,
  });
  if (error) {
    throw new Error(error.message);
  }

  return { actualizados: filas.length, fuente };
}

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: { ...corsHeaders, "Content-Type": "text/plain" },
      });
    }

    let wait = false;
    if (req.method === "POST") {
      try {
        const body = await req.json();
        wait = body?.wait === true;
      } catch (_) {
        wait = false;
      }
    }

    // Modo sincrónico para botón manual: devuelve éxito/error real.
    if (wait) {
      const { actualizados, fuente } = await sincronizarIndicadores();
      return new Response(
        JSON.stringify({
          ok: true,
          started: false,
          actualizados,
          fuente,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Devolver respuesta inmediata para evitar timeouts en web/cron.
    void (async () => {
      try {
        await sincronizarIndicadores();
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        console.error("sync-indicadores background error:", message);
      }
    })();

    return new Response(
      JSON.stringify({
        ok: true,
        started: true,
        actualizados: 0,
        fuente: "SIPSA",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("sync-indicadores request error:", message);
    return new Response(
      JSON.stringify({ ok: false, error: `request_failed: ${message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
