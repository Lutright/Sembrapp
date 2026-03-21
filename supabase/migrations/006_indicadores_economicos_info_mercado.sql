-- Indicadores económicos: preparar info_mercado para sincronización (SIPSA/DANE por Edge Function)
-- RF-C-05, RF-C-06: información de mercado y actualización periódica

-- Columnas opcionales para mejor UX
alter table public.info_mercado
  add column if not exists unidad text default 'kg',
  add column if not exists fuente text;

-- Índice único para upsert por producto_tipo
create unique index if not exists idx_info_mercado_producto_tipo
  on public.info_mercado (producto_tipo);

-- Política para que la Edge Function (service role) pueda hacer upsert
-- Los usuarios solo leen (policy existente "Todos pueden leer info de mercado")
