import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../navigation/tienda_campesino_extra.dart';
import '../repositories/ordenes_repository.dart';
import '../repositories/productos_repository.dart';

class ProductoDetalleScreen extends StatelessWidget {
  const ProductoDetalleScreen({
    super.key,
    this.producto,
    this.productoId,
    this.onAgregarAlPedido,
  });

  final Producto? producto;
  final String? productoId;
  /// Si no es null (viene desde una tienda), agrega al carrito y hace pop.
  final void Function(Producto producto, double cantidad)? onAgregarAlPedido;

  @override
  Widget build(BuildContext context) {
    if (producto != null) {
      return _ProductoDetalleBody(
        producto: producto!,
        onAgregarAlPedido: onAgregarAlPedido,
      );
    }
    if (productoId != null) {
      return _ProductoDetalleFuture(
        productoId: productoId!,
        onAgregarAlPedido: onAgregarAlPedido,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Producto')),
      body: const Center(child: Text('Producto no especificado')),
    );
  }
}

class _ProductoDetalleFuture extends StatelessWidget {
  const _ProductoDetalleFuture({
    required this.productoId,
    this.onAgregarAlPedido,
  });

  final String productoId;
  final void Function(Producto producto, double cantidad)? onAgregarAlPedido;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Producto?>(
      future: ProductosRepository(Supabase.instance.client)
          .obtenerProducto(productoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Producto')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Producto')),
            body: const Center(child: Text('No encontrado')),
          );
        }
        return _ProductoDetalleBody(
          producto: p,
          onAgregarAlPedido: onAgregarAlPedido,
        );
      },
    );
  }
}

class _ProductoDetalleBody extends StatefulWidget {
  const _ProductoDetalleBody({
    required this.producto,
    this.onAgregarAlPedido,
  });

  final Producto producto;
  final void Function(Producto producto, double cantidad)? onAgregarAlPedido;

  @override
  State<_ProductoDetalleBody> createState() => _ProductoDetalleBodyState();
}

class _ProductoDetalleBodyState extends State<_ProductoDetalleBody> {
  double _cantidad = 1;
  bool _procesando = false;

  Future<void> _crearOrdenUnSoloProducto() async {
    final p = widget.producto;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_cantidad > p.limiteSuperiorPedido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad no disponible')),
      );
      return;
    }
    setState(() => _procesando = true);
    try {
      final ordenId = await OrdenesRepository(Supabase.instance.client)
          .crearOrden(
        compradorId: user.id,
        campesinoId: p.campesinoId,
        items: [
          {
            'producto_id': p.id,
            'cantidad': _cantidad,
            'precio_unitario': p.precio,
          },
        ],
      );
      if (!mounted) return;
      context.push('/comercializacion/orden/$ordenId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido creado. Usa el chat para acordar el punto de encuentro.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el pedido: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _agregarAlPedidoYVolver() {
    final p = widget.producto;
    if (_cantidad > p.limiteSuperiorPedido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad no disponible')),
      );
      return;
    }
    widget.onAgregarAlPedido!(p, _cantidad);
    if (mounted) context.pop();
  }

  void _anadirCarritoEIrATienda() {
    final p = widget.producto;
    final cap = p.limiteSuperiorPedido;
    if (cap < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin stock suficiente')),
      );
      return;
    }
    var cant = _cantidad;
    if (cant < 0.5) cant = 0.5;
    if (cant > cap) cant = cap;
    context.push(
      '/comercializacion/tienda/${p.campesinoId}',
      extra: TiendaCampesinoExtra(
        nombreTienda: p.campesinoNombre,
        productoInicial: p,
        cantidadInicial: cant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'comprador';
    final isCampesino = role == 'campesino';
    final desdeTienda = widget.onAgregarAlPedido != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: AppPagePadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(p.descripcion!),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Precio: ${p.precio.toStringAsFixed(0)} \$ / ${p.unidad}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      p.tieneStockDeclarado
                          ? 'Cantidad disponible (referencia): ${p.cantidadDisponible} ${p.unidad}'
                          : 'Disponibilidad: variable — se acuerda por chat o con ayuda entre productores.',
                    ),
                    Text(
                      'Productor: ${p.campesinoNombre ?? "—"}',
                    ),
                  ],
                ),
              ),
            ),
            if (!isCampesino) ...[
              const SizedBox(height: 24),
              Text('Cantidad', style: Theme.of(context).textTheme.titleSmall),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_cantidad > 0.5) setState(() => _cantidad -= 0.5);
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: _cantidad.clamp(0.5, p.limiteSuperiorPedido),
                      min: 0.5,
                      max: p.limiteSuperiorPedido,
                      divisions: p.tieneStockDeclarado
                          ? ((p.cantidadDisponible! * 2).round().clamp(1, 10000))
                          : null,
                      label: _cantidad.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _cantidad = v),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_cantidad < p.limiteSuperiorPedido) {
                        setState(() => _cantidad += 0.5);
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Text(
                '${_cantidad.toStringAsFixed(1)} ${p.unidad} · '
                'Total: ${(p.precio * _cantidad).toStringAsFixed(0)} \$',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (desdeTienda)
                FilledButton(
                  onPressed: _procesando ? null : _agregarAlPedidoYVolver,
                  child: const Text('Agregar al pedido'),
                )
              else ...[
                FilledButton.icon(
                  onPressed: _procesando ? null : _anadirCarritoEIrATienda,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Añadir al carrito y ver tienda'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => context.push(
                    '/comercializacion/tienda/${p.campesinoId}',
                    extra: TiendaCampesinoExtra(nombreTienda: p.campesinoNombre),
                  ),
                  child: const Text('Ver tienda del productor'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _procesando ? null : _crearOrdenUnSoloProducto,
                  child: _procesando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Pedir solo este producto'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para varios productos del mismo productor, entra a su tienda.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
