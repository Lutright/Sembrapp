import '../models/producto.dart';

/// Argumentos opcionales al abrir la tienda de un campesino.
class TiendaCampesinoExtra {
  const TiendaCampesinoExtra({
    this.nombreTienda,
    this.productoInicial,
    this.cantidadInicial = 1.0,
    this.isDestacado = false,
  });

  final String? nombreTienda;
  /// Si viene del listado de productos, se añade al carrito al cargar la tienda.
  final Producto? productoInicial;
  final double cantidadInicial;
  /// Indica si el productor tiene un beneficio de visibilidad activo.
  final bool isDestacado;
}
