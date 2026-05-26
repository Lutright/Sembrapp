import '../models/producto.dart';

/// Extra para abrir detalle de producto desde una tienda (carrito multi-ítem).
class ProductoDetalleExtra {
  ProductoDetalleExtra({
    this.producto,
    required this.onAgregarAlPedido,
  });

  final Producto? producto;
  final void Function(Producto producto, double cantidad) onAgregarAlPedido;
}
