-- Catálogo de beneficios por puntos (visibilidad temporal)
create table if not exists public.beneficios (
  id text primary key,
  nombre text not null,
  descripcion text,
  puntos_requeridos int not null check (puntos_requeridos > 0),
  duracion_horas int not null check (duracion_horas > 0),
  orden_prioridad int not null default 0
);

alter table public.beneficios enable row level security;

create policy "Todos pueden leer beneficios"
  on public.beneficios for select
  using (true);

-- Beneficios activados por campesinos (gasto de puntos)
create table if not exists public.beneficios_activos (
  id uuid primary key default gen_random_uuid(),
  campesino_id uuid not null references public.profiles (id) on delete cascade,
  beneficio_id text not null references public.beneficios (id) on delete restrict,
  puntos_gastados int not null check (puntos_gastados > 0),
  activado_at timestamptz not null default now(),
  expira_at timestamptz not null
);

alter table public.beneficios_activos enable row level security;

create policy "Campesino ve sus beneficios activos"
  on public.beneficios_activos for select
  using (auth.uid() = campesino_id);

create policy "Campesino inserta sus beneficios activos"
  on public.beneficios_activos for insert
  with check (auth.uid() = campesino_id);

-- Compradores y campesinos pueden ver qué campesinos tienen beneficio activo (para ordenar)
create policy "Todos pueden leer beneficios activos para visibilidad"
  on public.beneficios_activos for select
  using (true);

-- Datos iniciales de beneficios
insert into public.beneficios (id, nombre, descripcion, puntos_requeridos, duracion_horas, orden_prioridad)
values
  ('destacado_1sem', 'Visibilidad premium (24 h)', 'Tus productos y tu tienda aparecen primero durante 24 horas.', 250, 24, 1),
  ('destacado_3d', 'Visibilidad media (12 h)', 'Tus productos y tu tienda aparecen primero durante 12 horas.', 120, 12, 2),
  ('destacado_24h', 'Visibilidad básica (6 h)', 'Tus productos y tu tienda aparecen primero durante 6 horas.', 50, 6, 3)
on conflict (id) do nothing;
