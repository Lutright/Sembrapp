-- Ajuste catálogo: más caro = 24 h, intermedio = 12 h, más barato = 6 h.
-- Productos y tiendas en marketplace usan el mismo conjunto de campesinos con beneficio vigente.

update public.beneficios set
  nombre = 'Visibilidad premium (24 h)',
  descripcion = 'Tus productos y tu tienda aparecen primero durante 24 horas.',
  puntos_requeridos = 250,
  duracion_horas = 24,
  orden_prioridad = 1
where id = 'destacado_1sem';

update public.beneficios set
  nombre = 'Visibilidad media (12 h)',
  descripcion = 'Tus productos y tu tienda aparecen primero durante 12 horas.',
  puntos_requeridos = 120,
  duracion_horas = 12,
  orden_prioridad = 2
where id = 'destacado_3d';

update public.beneficios set
  nombre = 'Visibilidad básica (6 h)',
  descripcion = 'Tus productos y tu tienda aparecen primero durante 6 horas.',
  puntos_requeridos = 50,
  duracion_horas = 6,
  orden_prioridad = 3
where id = 'destacado_24h';
