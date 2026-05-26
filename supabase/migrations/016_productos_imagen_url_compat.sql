-- Compatibilidad entre esquemas antiguos (columna "imagen")
-- y esquema actual esperado por la app ("imagen_url").

alter table public.productos
  add column if not exists imagen_url text;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'productos'
      and column_name = 'imagen'
  ) then
    execute '
      update public.productos
      set imagen_url = coalesce(imagen_url, imagen)
      where imagen_url is null and imagen is not null
    ';
  end if;
end $$;
