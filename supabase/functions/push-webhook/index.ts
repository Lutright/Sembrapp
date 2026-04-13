// @ts-nocheck
// Webhook Database (INSERT): ordenes | orden_ayuda_solicitud | orden_mensajes | ayuda_mensajes → FCM.
// Preferido: FCM HTTP v1 — secret FCM_SERVICE_ACCOUNT_JSON (JSON completo de “Generar clave privada”).
// Alternativa obsoleta: FCM_SERVER_KEY (API legacy; Google la retira y la consola suele fallar).
// También: SUPABASE_SERVICE_ROLE_KEY (auto), opcional PUSH_WEBHOOK_SECRET + header x-webhook-secret.
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v5.9.6/index.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
};

function trunc(s: string, n: number): string {
  const t = s.trim();
  if (t.length <= n) return t;
  return t.slice(0, n - 1) + "…";
}

/** Cache de access_token OAuth2 (misma instancia caliente de la función). */
let _fcmAccess: { token: string; expMs: number } | null = null;

async function getGoogleAccessTokenForFcm(saJson: string): Promise<string> {
  const now = Date.now();
  if (_fcmAccess && _fcmAccess.expMs > now + 60_000) {
    return _fcmAccess.token;
  }
  const sa = JSON.parse(saJson) as {
    client_email: string;
    private_key: string;
  };
  const key = await importPKCS8(sa.private_key, "RS256");
  const iat = Math.floor(now / 1000);
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(iat)
    .setExpirationTime(iat + 3600)
    .sign(key);

  const tr = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const tok = await tr.json();
  if (!tr.ok) {
    throw new Error(`oauth token: ${JSON.stringify(tok)}`);
  }
  const accessToken = tok.access_token as string;
  const expiresIn = (tok.expires_in as number) ?? 3600;
  _fcmAccess = {
    token: accessToken,
    expMs: now + expiresIn * 1000 - 120_000,
  };
  return accessToken;
}

async function sendFcmV1(
  saJson: string,
  deviceTokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  const sa = JSON.parse(saJson) as { project_id?: string };
  const projectId =
    sa.project_id ?? Deno.env.get("FCM_PROJECT_ID") ?? "";
  if (!projectId) {
    console.error("push-webhook: falta project_id en FCM_SERVICE_ACCOUNT_JSON");
    return;
  }
  let accessToken: string;
  try {
    accessToken = await getGoogleAccessTokenForFcm(saJson);
  } catch (e) {
    console.error("push-webhook:", e);
    return;
  }
  const dataPayload: Record<string, string> = {
    ...data,
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  };
  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  for (const token of deviceTokens) {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: dataPayload,
          android: { priority: "HIGH" },
        },
      }),
    });
    if (!res.ok) {
      console.error("push-webhook FCM v1:", res.status, await res.text());
    }
  }
}

async function sendFcmLegacy(
  key: string,
  registrationIds: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  const chunkSize = 800;
  for (let i = 0; i < registrationIds.length; i += chunkSize) {
    const chunk = registrationIds.slice(i, i + chunkSize);
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        registration_ids: chunk,
        notification: { title, body },
        data: {
          ...data,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      }),
    });
    if (!res.ok) {
      console.error("push-webhook FCM legacy:", res.status, await res.text());
    }
  }
}

async function sendPushToTokens(
  deviceTokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  if (deviceTokens.length === 0) return;
  const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  const legacyKey = Deno.env.get("FCM_SERVER_KEY");
  if (saJson) {
    await sendFcmV1(saJson, deviceTokens, title, body, data);
  } else if (legacyKey) {
    await sendFcmLegacy(legacyKey, deviceTokens, title, body, data);
  } else {
    console.warn(
      "push-webhook: define FCM_SERVICE_ACCOUNT_JSON (recomendado) o FCM_SERVER_KEY",
    );
  }
}

const EARTH_RADIUS_KM = 6371;

function distanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Misma idea que RedComunitariaScreen: distancia al punto de la solicitud ≤ radio del campesino. */
async function campesinoIdsNearAyudaSolicitud(
  supabase: ReturnType<typeof createClient>,
  solLat: number,
  solLng: number,
  solicitanteId: string,
  defaultRadiusKm: number,
): Promise<string[]> {
  const { data: profiles, error: pe } = await supabase
    .from("profiles")
    .select("id, last_map_lat, last_map_lng, last_map_at, red_comunitaria_radius_km")
    .eq("role", "campesino");
  if (pe || !profiles?.length) {
    if (pe) console.error("push-webhook profiles campesinos:", pe.message);
    return [];
  }

  const { data: prods, error: prodE } = await supabase
    .from("productos")
    .select("campesino_id, lat, lng")
    .not("lat", "is", null)
    .not("lng", "is", null);
  if (prodE) console.error("push-webhook productos:", prodE.message);

  type Acc = { n: number; slat: number; slng: number };
  const centroid = new Map<string, Acc>();
  for (const row of prods ?? []) {
    const cid = String((row as { campesino_id?: string }).campesino_id ?? "");
    const la = Number((row as { lat?: number }).lat);
    const ln = Number((row as { lng?: number }).lng);
    if (!cid || Number.isNaN(la) || Number.isNaN(ln)) continue;
    const cur = centroid.get(cid) ?? { n: 0, slat: 0, slng: 0 };
    cur.n++;
    cur.slat += la;
    cur.slng += ln;
    centroid.set(cid, cur);
  }

  const now = Date.now();
  const mapMaxAgeMs = 30 * 86400 * 1000;
  const out: string[] = [];

  for (const p of profiles as Record<string, unknown>[]) {
    const id = String(p.id ?? "");
    if (!id || id === solicitanteId) continue;

    let radius = Number(p.red_comunitaria_radius_km);
    if (!Number.isFinite(radius) || radius < 1) radius = defaultRadiusKm;
    if (radius > 50) radius = 50;

    let refLat: number | null = null;
    let refLng: number | null = null;

    const lmLat = p.last_map_lat != null ? Number(p.last_map_lat) : NaN;
    const lmLng = p.last_map_lng != null ? Number(p.last_map_lng) : NaN;
    const lmAtRaw = p.last_map_at;
    const lmAt = lmAtRaw ? Date.parse(String(lmAtRaw)) : NaN;
    if (
      Number.isFinite(lmLat) &&
      Number.isFinite(lmLng) &&
      Number.isFinite(lmAt) &&
      now - lmAt <= mapMaxAgeMs
    ) {
      refLat = lmLat;
      refLng = lmLng;
    } else {
      const c = centroid.get(id);
      if (c != null && c.n > 0) {
        refLat = c.slat / c.n;
        refLng = c.slng / c.n;
      }
    }
    if (refLat == null || refLng == null) continue;
    if (distanceKm(refLat, refLng, solLat, solLng) <= radius) {
      out.push(id);
    }
  }
  return out;
}

async function tokensForUsers(
  supabase: ReturnType<typeof createClient>,
  userIds: string[],
): Promise<string[]> {
  if (userIds.length === 0) return [];
  const uniq = [...new Set(userIds)];
  const { data, error } = await supabase
    .from("user_push_tokens")
    .select("fcm_token")
    .in("user_id", uniq);
  if (error) {
    console.error("push-webhook tokens:", error.message);
    return [];
  }
  return [...new Set((data ?? []).map((r: { fcm_token: string }) => r.fcm_token))];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  const hookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (hookSecret) {
    const h = req.headers.get("x-webhook-secret");
    if (h !== hookSecret) {
      return new Response(JSON.stringify({ ok: false, error: "unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceKey);

  let raw: Record<string, unknown>;
  try {
    raw = await req.json();
  } catch {
    return new Response(JSON.stringify({ ok: false, error: "invalid json" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const payload =
    typeof raw.body === "object" && raw.body != null
      ? (raw.body as Record<string, unknown>)
      : raw;

  const type = (payload.type ?? payload.eventType) as string | undefined;
  const table = (payload.table ?? payload.table_name) as string | undefined;
  const record = payload.record as Record<string, unknown> | undefined;

  if (String(type).toUpperCase() !== "INSERT" || !table || !record) {
    return new Response(JSON.stringify({ ok: true, skipped: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    if (table === "ordenes") {
      const ordenId = String(record.id ?? "");
      const campesinoId = String(record.campesino_id ?? "");
      const compradorId = String(record.comprador_id ?? "");
      if (!ordenId || !campesinoId) {
        return new Response(JSON.stringify({ ok: true, skipped: "no ids" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const tokens = await tokensForUsers(supabase, [campesinoId]);
      await sendPushToTokens(
        tokens,
        "Nueva orden",
        "Tienes un nuevo pedido en Sembrapp.",
        {
          route: "orden_detail",
          orden_id: ordenId,
          comprador_id: compradorId,
        },
      );
      return new Response(JSON.stringify({ ok: true, sent: tokens.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (table === "orden_ayuda_solicitud") {
      const estado = String(record.estado ?? "");
      if (estado !== "abierta") {
        return new Response(JSON.stringify({ ok: true, skipped: "not abierta" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const solicitudId = String(record.id ?? "");
      const solicitanteId = String(record.solicitante_id ?? "");
      const solLat = Number(record.lat);
      const solLng = Number(record.lng);
      if (
        !solicitudId || !solicitanteId || !Number.isFinite(solLat) ||
        !Number.isFinite(solLng)
      ) {
        return new Response(JSON.stringify({ ok: true, skipped: "bad solicitud" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const rawKm = Deno.env.get("AYUDA_NOTIF_FALLBACK_KM");
      const parsedKm = rawKm ? parseInt(rawKm, 10) : 25;
      const defaultRadiusKm =
        Number.isFinite(parsedKm) && parsedKm >= 1 && parsedKm <= 50 ? parsedKm : 25;
      const recipientIds = await campesinoIdsNearAyudaSolicitud(
        supabase,
        solLat,
        solLng,
        solicitanteId,
        defaultRadiusKm,
      );
      if (recipientIds.length === 0) {
        return new Response(
          JSON.stringify({ ok: true, sent: 0, skipped: "no recipients" }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      const tokens = await tokensForUsers(supabase, recipientIds);
      await sendPushToTokens(
        tokens,
        "Pedido de ayuda cercano",
        "Un productor necesita apoyo con parte de un pedido en tu zona.",
        {
          route: "red_comunitaria",
          solicitud_id: solicitudId,
        },
      );
      return new Response(JSON.stringify({ ok: true, sent: tokens.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (table === "orden_mensajes") {
      const ordenId = String(record.orden_id ?? "");
      const senderId = String(record.sender_id ?? "");
      const texto = trunc(String(record.mensaje ?? ""), 120);
      if (!ordenId || !senderId) {
        return new Response(JSON.stringify({ ok: true, skipped: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const { data: orden, error: e1 } = await supabase
        .from("ordenes")
        .select("comprador_id, campesino_id")
        .eq("id", ordenId)
        .maybeSingle();
      if (e1 || !orden) {
        console.error("push-webhook orden:", e1?.message);
        return new Response(JSON.stringify({ ok: false, error: "orden" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const compradorId = String(orden.comprador_id ?? "");
      const campesinoId = String(orden.campesino_id ?? "");
      let recipient: string | null = null;
      if (senderId === compradorId) recipient = campesinoId;
      else if (senderId === campesinoId) recipient = compradorId;
      if (!recipient || recipient === senderId) {
        return new Response(JSON.stringify({ ok: true, skipped: "no recipient" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const tokens = await tokensForUsers(supabase, [recipient]);
      await sendPushToTokens(
        tokens,
        "Mensaje en el pedido",
        texto || "Nuevo mensaje en el chat del pedido.",
        {
          route: "orden_detail",
          orden_id: ordenId,
        },
      );
      return new Response(JSON.stringify({ ok: true, sent: tokens.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (table === "ayuda_mensajes") {
      const solicitudId = String(record.solicitud_id ?? "");
      const senderId = String(record.sender_id ?? "");
      const texto = trunc(String(record.mensaje ?? ""), 120);
      if (!solicitudId || !senderId) {
        return new Response(JSON.stringify({ ok: true, skipped: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const { data: sol, error: e2 } = await supabase
        .from("orden_ayuda_solicitud")
        .select("solicitante_id, ayudante_id, estado")
        .eq("id", solicitudId)
        .maybeSingle();
      if (e2 || !sol) {
        console.error("push-webhook solicitud:", e2?.message);
        return new Response(JSON.stringify({ ok: false, error: "solicitud" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const solicitanteId = String(sol.solicitante_id ?? "");
      const ayudanteId = sol.ayudante_id != null
        ? String(sol.ayudante_id)
        : "";
      if (sol.estado !== "cerrada" || !ayudanteId) {
        return new Response(JSON.stringify({ ok: true, skipped: "ayuda no activa" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      let recipient: string | null = null;
      if (senderId === solicitanteId) recipient = ayudanteId;
      else if (senderId === ayudanteId) recipient = solicitanteId;
      if (!recipient) {
        return new Response(JSON.stringify({ ok: true, skipped: "no recipient" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const tokens = await tokensForUsers(supabase, [recipient]);
      await sendPushToTokens(
        tokens,
        "Mensaje (ayuda entre campesinos)",
        texto || "Nuevo mensaje en el chat de ayuda.",
        {
          route: "ayuda_chat",
          solicitud_id: solicitudId,
        },
      );
      return new Response(JSON.stringify({ ok: true, sent: tokens.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, skipped: "table" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("push-webhook:", msg);
    return new Response(JSON.stringify({ ok: false, error: msg }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
