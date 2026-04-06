-- Evita recursión infinita en RLS: INSERT en orden_ayuda_solicitud valida FK → lee ordenes →
-- política de ordenes hacía EXISTS (SELECT … orden_ayuda_solicitud) con RLS → bucle 42P17.

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

drop policy if exists "Campesinos ven órdenes con ayuda abierta" on public.ordenes;
create policy "Campesinos ven órdenes con ayuda abierta"
  on public.ordenes for select
  using (
    exists (
      select 1 from public.profiles pr
      where pr.id = auth.uid() and pr.role = 'campesino'
    )
    and public.orden_tiene_ayuda_abierta(ordenes.id)
  );

drop policy if exists "Ayudante ve orden tras aceptar" on public.ordenes;
create policy "Ayudante ve orden tras aceptar"
  on public.ordenes for select
  using (
    public.es_ayudante_asignado_en_orden(ordenes.id, auth.uid())
  );

drop policy if exists "Campesinos ven ítems de órdenes con ayuda abierta" on public.orden_items;
create policy "Campesinos ven ítems de órdenes con ayuda abierta"
  on public.orden_items for select
  using (
    exists (
      select 1 from public.profiles pr
      where pr.id = auth.uid() and pr.role = 'campesino'
    )
    and public.orden_tiene_ayuda_abierta(orden_items.orden_id)
  );

drop policy if exists "Ayudante ve ítems de orden asignada" on public.orden_items;
create policy "Ayudante ve ítems de orden asignada"
  on public.orden_items for select
  using (
    public.es_ayudante_asignado_en_orden(orden_items.orden_id, auth.uid())
  );
