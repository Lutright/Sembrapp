-- Ubicación y radio de la red comunitaria (sync desde la app) para notificaciones
-- de nuevas solicitudes de ayuda: misma lógica de distancia que [RedComunitariaScreen].
--
-- Tras migrar: en Supabase Dashboard > Database > Webhooks, añade un webhook
-- INSERT en public.orden_ayuda_solicitud que invoque la Edge Function push-webhook
-- (mismo patrón que ordenes / orden_mensajes / ayuda_mensajes).

alter table public.profiles
  add column if not exists last_map_lat double precision,
  add column if not exists last_map_lng double precision,
  add column if not exists last_map_at timestamptz,
  add column if not exists red_comunitaria_radius_km int not null default 25
    check (red_comunitaria_radius_km >= 1 and red_comunitaria_radius_km <= 50);

comment on column public.profiles.last_map_lat is 'Última posición GPS al usar red comunitaria / mapa (para notificaciones cercanas)';
comment on column public.profiles.red_comunitaria_radius_km is 'Radio km guardado con marketplace_distance_km (1–50)';
