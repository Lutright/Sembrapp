-- Al cancelar un pedido, elimina solicitudes de ayuda y mensajes asociados
-- (para que desaparezcan de "Creadas por mí" / "Aceptadas por mí" para ambos campesinos).

create or replace function public.eliminar_solicitudes_ayuda_al_cancelar_pedido(p_orden_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_campesino uuid;
  v_estado text;
begin
  if auth.uid() is null then
    return json_build_object('ok', false, 'error', 'no_auth');
  end if;

  select o.campesino_id, lower(o.estado::text)
    into v_campesino, v_estado
  from public.ordenes o
  where o.id = p_orden_id;

  if v_campesino is null then
    return json_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_campesino <> auth.uid() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  if v_estado is distinct from 'cancelada' then
    return json_build_object('ok', false, 'error', 'order_not_cancelled');
  end if;

  delete from public.ayuda_mensajes m
  using public.orden_ayuda_solicitud s
  where m.solicitud_id = s.id and s.orden_id = p_orden_id;

  delete from public.orden_ayuda_solicitud s
  where s.orden_id = p_orden_id;

  return json_build_object('ok', true);
end;
$$;

grant execute on function public.eliminar_solicitudes_ayuda_al_cancelar_pedido(uuid) to authenticated;
