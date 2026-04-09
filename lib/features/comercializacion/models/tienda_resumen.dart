import 'producto.dart';

/// Vista de un campesino como “tienda” para el comprador.
class TiendaResumen {
  const TiendaResumen({
    required this.campesinoId,
    this.nombre,
    required this.cantidadProductos,
    this.destacado = false,
  });

  final String campesinoId;
  final String? nombre;
  final int cantidadProductos;
  final bool destacado;

  static List<TiendaResumen> agruparDesdeProductos(
    List<Producto> productos, {
    required Set<String> campesinosDestacados,
  }) {
    final byCampesino = <String, List<Producto>>{};
    for (final p in productos) {
      byCampesino.putIfAbsent(p.campesinoId, () => []).add(p);
    }
    final list = byCampesino.entries.map((e) {
      final first = e.value.first;
      final nombre = first.campesinoNombre;
      return TiendaResumen(
        campesinoId: e.key,
        nombre: nombre,
        cantidadProductos: e.value.length,
        destacado: campesinosDestacados.contains(e.key),
      );
    }).toList();
    list.sort((a, b) {
      if (a.destacado && !b.destacado) return -1;
      if (!a.destacado && b.destacado) return 1;
      return (a.nombre ?? '').toLowerCase().compareTo((b.nombre ?? '').toLowerCase());
    });
    return list;
  }

  /// Misma prioridad que las tiendas: productos de campesinos con beneficio vigente primero.
  static List<Producto> ordenarProductosPorVisibilidad(
    List<Producto> productos,
    Set<String> campesinosDestacados,
  ) {
    final out = List<Producto>.from(productos);
    out.sort((a, b) {
      final ad = campesinosDestacados.contains(a.campesinoId);
      final bd = campesinosDestacados.contains(b.campesinoId);
      if (ad && !bd) return -1;
      if (!ad && bd) return 1;
      final n = a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      if (n != 0) return n;
      return a.id.compareTo(b.id);
    });
    return out;
  }
}
