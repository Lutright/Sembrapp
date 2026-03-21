-- Sembrapp: esquema inicial para el prototipo
-- Ejecutar en Supabase Dashboard > SQL Editor

-- Perfiles (extiende auth.users, RF-G-07, RF-G-08)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null check (role in ('campesino', 'comprador')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS
alter table public.profiles enable row level security;

create policy "Usuarios ven su propio perfil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Usuarios actualizan su propio perfil"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Usuarios insertan su propio perfil"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger: crear perfil al registrarse (con role desde user_metadata)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'campesino')
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Productos agrícolas (RF-CV-01, RF-C-02, RF-C-03)
create table if not exists public.productos (
  id uuid primary key default gen_random_uuid(),
  campesino_id uuid not null references public.profiles (id) on delete cascade,
  nombre text not null,
  descripcion text,
  precio decimal(12,2) not null check (precio >= 0),
  cantidad_disponible decimal(12,2) not null check (cantidad_disponible >= 0),
  unidad text default 'kg',
  lat double precision,
  lng double precision,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.productos enable row level security;

create policy "Todos pueden ver productos"
  on public.productos for select
  using (true);

create policy "Campesinos gestionan sus productos"
  on public.productos for all
  using (auth.uid() = campesino_id);

-- Progreso alfabetización (RF-A-09, RF-A-08)
create table if not exists public.alfabetizacion_progreso (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  modulo text not null,
  nivel int not null default 1,
  leccion_id text,
  puntos int not null default 0,
  completado_at timestamptz,
  created_at timestamptz default now(),
  unique (user_id, modulo, nivel, leccion_id)
);

alter table public.alfabetizacion_progreso enable row level security;

create policy "Usuarios ven y actualizan su progreso"
  on public.alfabetizacion_progreso for all
  using (auth.uid() = user_id);

-- Órdenes (RF-CO-01, RF-CO-02)
create table if not exists public.ordenes (
  id uuid primary key default gen_random_uuid(),
  comprador_id uuid not null references public.profiles (id) on delete cascade,
  campesino_id uuid not null references public.profiles (id) on delete cascade,
  estado text not null default 'pendiente' check (estado in ('pendiente', 'confirmada', 'entregada', 'cancelada')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.orden_items (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references public.ordenes (id) on delete cascade,
  producto_id uuid not null references public.productos (id) on delete restrict,
  cantidad decimal(12,2) not null check (cantidad > 0),
  precio_unitario decimal(12,2) not null
);

alter table public.ordenes enable row level security;
alter table public.orden_items enable row level security;

create policy "Comprador y campesino ven sus órdenes"
  on public.ordenes for select
  using (auth.uid() = comprador_id or auth.uid() = campesino_id);

create policy "Comprador crea órdenes"
  on public.ordenes for insert
  with check (auth.uid() = comprador_id);

create policy "Ver items de órdenes propias"
  on public.orden_items for select
  using (
    exists (
      select 1 from public.ordenes o
      where o.id = orden_id and (o.comprador_id = auth.uid() or o.campesino_id = auth.uid())
    )
  );

-- Información de mercado (RF-C-05, RF-C-06) – referencia para precios
create table if not exists public.info_mercado (
  id uuid primary key default gen_random_uuid(),
  producto_tipo text not null,
  precio_promedio decimal(12,2),
  rango_min decimal(12,2),
  rango_max decimal(12,2),
  updated_at timestamptz default now()
);

alter table public.info_mercado enable row level security;

create policy "Todos pueden leer info de mercado"
  on public.info_mercado for select
  using (true);
