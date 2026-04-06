import '../models/producto.dart';

/// Argumentos opcionales al abrir la tienda de un campesino.
class TiendaCampesinoExtra {
  const TiendaCampesinoExtra({
    this.nombreTienda,
    this.productoInicial,
    this.cantidadInicial = 1.0,
  });

  final String? nombreTienda;
  /// Si viene del listado de productos, se añade al carrito al cargar la tienda.
  final Producto? productoInicial;
  final double cantidadInicial;
}
