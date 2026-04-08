-- Stock no obligatorio al publicar: NULL = disponibilidad variable / se coordina con el comprador.
alter table public.productos
  alter column cantidad_disponible drop not null;

alter table public.productos
  drop constraint if exists productos_cantidad_disponible_check;

alter table public.productos
  add constraint productos_cantidad_disponible_nonneg
  check (cantidad_disponible is null or cantidad_disponible >= 0);

-- Si no hay stock declarado, no modificar la columna al crear ítems de orden.
create or replace function public.decrementar_stock_al_agregar_item()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.productos
  set
    cantidad_disponible = case
      when cantidad_disponible is null then null
      else greatest(0::numeric, cantidad_disponible - NEW.cantidad)
    end,
    updated_at = now()
  where id = NEW.producto_id;
  return NEW;
end;
$$;
