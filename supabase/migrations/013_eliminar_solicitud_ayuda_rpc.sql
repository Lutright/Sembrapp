-- Permite al solicitante eliminar su propia solicitud de ayuda (mensajes + fila),
-- sin exponer DELETE genérico en RLS (evita problemas con CASCADE y políticas en ayuda_mensajes).

create or replace function public.eliminar_mi_solicitud_ayuda(p_solicitud_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_solicitante uuid;
begin
  if auth.uid() is null then
    return json_build_object('ok', false, 'error', 'no_auth');
  end if;

  select s.solicitante_id
    into v_solicitante
  from public.orden_ayuda_solicitud s
  where s.id = p_solicitud_id;

  if v_solicitante is null then
    return json_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_solicitante <> auth.uid() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  delete from public.ayuda_mensajes m where m.solicitud_id = p_solicitud_id;
  delete from public.orden_ayuda_solicitud s where s.id = p_solicitud_id;

  return json_build_object('ok', true);
end;
$$;

grant execute on function public.eliminar_mi_solicitud_ayuda(uuid) to authenticated;
