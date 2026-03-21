-- Permitir al comprador insertar items en sus propias órdenes
create policy "Comprador inserta items en su orden"
  on public.orden_items for insert
  with check (
    exists (
      select 1 from public.ordenes o
      where o.id = orden_id and o.comprador_id = auth.uid()
    )
  );

-- Chat por orden (RF-CO-03)
create table if not exists public.orden_mensajes (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references public.ordenes (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  mensaje text not null,
  created_at timestamptz default now()
);

alter table public.orden_mensajes enable row level security;

create policy "Comprador y campesino ven mensajes de su orden"
  on public.orden_mensajes for select
  using (
    exists (
      select 1 from public.ordenes o
      where o.id = orden_id and (o.comprador_id = auth.uid() or o.campesino_id = auth.uid())
    )
  );

create policy "Comprador y campesino envían mensajes en su orden"
  on public.orden_mensajes for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.ordenes o
      where o.id = orden_id and (o.comprador_id = auth.uid() or o.campesino_id = auth.uid())
    )
  );

-- RF-CCOM-01: permitir ver otros perfiles (red campesina)
create policy "Ver perfiles para red campesina"
  on public.profiles for select
  using (true);
