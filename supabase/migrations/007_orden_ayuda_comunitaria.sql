-- Ayuda entre campesinos: solicitud cuando no pueden cubrir ítems del pedido,
-- aceptación atómica y chat entre solicitante y ayudante.

create table if not exists public.orden_ayuda_solicitud (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references public.ordenes (id) on delete cascade,
  solicitante_id uuid not null references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  nota text,
  item_ids uuid[] not null default '{}',
  estado text not null default 'abierta'
    check (estado in ('abierta', 'cerrada')),
  ayudante_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz default now(),
  aceptada_at timestamptz,
  constraint orden_ayuda_solicitud_item_ids_nonempty check (cardinality(item_ids) >= 1)
);

create unique index if not exists orden_ayuda_solicitud_orden_abierta_unique
  on public.orden_ayuda_solicitud (orden_id)
  where (estado = 'abierta');

create index if not exists orden_ayuda_solicitud_estado_idx
  on public.orden_ayuda_solicitud (estado);

alter table public.orden_ayuda_solicitud enable row level security;

create policy "Campesinos ven solicitudes abiertas o propias"
  on public.orden_ayuda_solicitud for select
  using (
    solicitante_id = auth.uid()
    or ayudante_id = auth.uid()
    or (
      estado = 'abierta'
      and exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role = 'campesino'
      )
    )
  );

create policy "Campesino dueño de la orden crea solicitud"
  on public.orden_ayuda_solicitud for insert
  with check (
    auth.uid() = solicitante_id
    and exists (
      select 1 from public.ordenes o
      where o.id = orden_id and o.campesino_id = auth.uid()
    )
  );

create policy "Solicitante cancela solicitud abierta"
  on public.orden_ayuda_solicitud for update
  using (solicitante_id = auth.uid() and estado = 'abierta')
  with check (
    solicitante_id = auth.uid()
    and estado = 'cerrada'
    and ayudante_id is null
  );

-- Consultas sin RLS para políticas de ordenes/orden_items (evita recursión 42P17 al INSERT solicitud).
create or replace function public.orden_tiene_ayuda_abierta(p_orden_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.orden_ayuda_solicitud s
    where s.orden_id = p_orden_id and s.estado = 'abierta'
  );
$$;

create or replace function public.es_ayudante_asignado_en_orden(p_orden_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.orden_ayuda_solicitud s
    where s.orden_id = p_orden_id
      and s.estado = 'cerrada'
      and s.ayudante_id is not null
      and s.ayudante_id = p_user_id
  );
$$;

-- Chat solo entre campesinos tras aceptación
create table if not exists public.ayuda_mensajes (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references public.orden_ayuda_solicitud (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  mensaje text not null,
  created_at timestamptz default now()
);

create index if not exists ayuda_mensajes_solicitud_idx
  on public.ayuda_mensajes (solicitud_id, created_at);

alter table public.ayuda_mensajes enable row level security;

create policy "Participantes leen mensajes de ayuda"
  on public.ayuda_mensajes for select
  using (
    exists (
      select 1 from public.orden_ayuda_solicitud s
      where s.id = ayuda_mensajes.solicitud_id
        and s.estado = 'cerrada'
        and s.ayudante_id is not null
        and (s.solicitante_id = auth.uid() or s.ayudante_id = auth.uid())
    )
  );

create policy "Participantes envían mensajes de ayuda"
  on public.ayuda_mensajes for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.orden_ayuda_solicitud s
      where s.id = solicitud_id
        and s.estado = 'cerrada'
        and s.ayudante_id is not null
        and (s.solicitante_id = auth.uid() or s.ayudante_id = auth.uid())
    )
  );

-- Ver pedido ajeno solo si hay solicitud abierta (campesinos); usa SECURITY DEFINER arriba.
create policy "Campesinos ven órdenes con ayuda abierta"
  on public.ordenes for select
  using (
    exists (
      select 1 from public.profiles pr
      where pr.id = auth.uid() and pr.role = 'campesino'
    )
    and public.orden_tiene_ayuda_abierta(ordenes.id)
  );

create policy "Ayudante ve orden tras aceptar"
  on public.ordenes for select
  using (
    public.es_ayudante_asignado_en_orden(ordenes.id, auth.uid())
  );

create policy "Campesinos ven ítems de órdenes con ayuda abierta"
  on public.orden_items for select
  using (
    exists (
      select 1 from public.profiles pr
      where pr.id = auth.uid() and pr.role = 'campesino'
    )
    and public.orden_tiene_ayuda_abierta(orden_items.orden_id)
  );

create policy "Ayudante ve ítems de orden asignada"
  on public.orden_items for select
  using (
    public.es_ayudante_asignado_en_orden(orden_items.orden_id, auth.uid())
  );

-- Aceptación atómica (otro campesino, no el solicitante)
create or replace function public.aceptar_solicitud_ayuda(p_solicitud_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  if auth.uid() is null then
    return json_build_object('ok', false, 'error', 'no_auth');
  end if;

  update public.orden_ayuda_solicitud s
  set
    estado = 'cerrada',
    ayudante_id = auth.uid(),
    aceptada_at = now()
  where s.id = p_solicitud_id
    and s.estado = 'abierta'
    and s.solicitante_id is distinct from auth.uid();

  get diagnostics n = row_count;
  if n = 0 then
    return json_build_object('ok', false, 'error', 'no_disponible');
  end if;

  return json_build_object('ok', true);
end;
$$;

grant execute on function public.aceptar_solicitud_ayuda(uuid) to authenticated;
