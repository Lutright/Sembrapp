-- Al crear ítems de una orden, descontar la cantidad del producto.
create or replace function public.decrementar_stock_al_agregar_item()
returns trigger as $$
begin
  update public.productos
  set cantidad_disponible = greatest(0, cantidad_disponible - NEW.cantidad),
      updated_at = now()
  where id = NEW.producto_id;
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_orden_items_decrementar_stock on public.orden_items;
create trigger trg_orden_items_decrementar_stock
  after insert on public.orden_items
  for each row execute function public.decrementar_stock_al_agregar_item();

-- Habilitar Realtime para el chat (mensajes nuevos en tiempo real)
alter publication supabase_realtime add table public.orden_mensajes;
