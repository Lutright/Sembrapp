import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../repositories/ordenes_repository.dart';
import '../repositories/productos_repository.dart';

class ProductoDetalleScreen extends StatelessWidget {
  const ProductoDetalleScreen({
    super.key,
    this.producto,
    this.productoId,
  });

  final Producto? producto;
  final String? productoId;

  @override
  Widget build(BuildContext context) {
    if (producto != null) {
      return _ProductoDetalleBody(producto: producto!);
    }
    if (productoId != null) {
      return _ProductoDetalleFuture(productoId: productoId!);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Producto')),
      body: const Center(child: Text('Producto no especificado')),
    );
  }
}

class _ProductoDetalleFuture extends StatelessWidget {
  const _ProductoDetalleFuture({required this.productoId});

  final String productoId;

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
        return _ProductoDetalleBody(producto: p);
      },
    );
  }
}

class _ProductoDetalleBody extends StatefulWidget {
  const _ProductoDetalleBody({required this.producto});

  final Producto producto;

  @override
  State<_ProductoDetalleBody> createState() => _ProductoDetalleBodyState();
}

class _ProductoDetalleBodyState extends State<_ProductoDetalleBody> {
  double _cantidad = 1;
  bool _creandoOrden = false;

  Future<void> _crearOrdenYIrAlChat() async {
    final p = widget.producto;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final compradorId = user.id;
    if (p.cantidadDisponible < _cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad no disponible')),
      );
      return;
    }
    setState(() => _creandoOrden = true);
    try {
      final ordenId = await OrdenesRepository(Supabase.instance.client)
          .crearOrden(
        compradorId: compradorId,
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
          content: Text('Orden creada. Usa el chat para acordar el punto de encuentro.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la orden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creandoOrden = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'comprador';
    final isCampesino = role == 'campesino';
    final disponible = p.cantidadDisponible;
    final puedeSeleccionarCantidad = !isCampesino && disponible >= 0.5;

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
                      'Cantidad disponible: ${p.cantidadDisponible} ${p.unidad}',
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
              if (!puedeSeleccionarCantidad) ...[
                const SizedBox(height: 8),
                Text(
                  disponible <= 0
                      ? 'Sin stock disponible.'
                      : 'Stock insuficiente para seleccionar (mínimo 0.5).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_cantidad > 0.5) setState(() => _cantidad -= 0.5);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          const min = 0.5;
                          final max = disponible;
                          final value = _cantidad.clamp(min, max).toDouble();
                          final steps = ((max - min) / 0.5).round();
                          final divisions = steps > 0 ? steps : null;
                          return Slider(
                            value: value,
                            min: min,
                            max: max,
                            divisions: divisions,
                            label: value.toStringAsFixed(1),
                            onChanged: (v) => setState(() => _cantidad = v),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_cantidad < disponible) {
                          setState(() => _cantidad += 0.5);
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Text(
                  '${_cantidad.clamp(0.5, disponible).toStringAsFixed(1)} ${p.unidad} · '
                  'Total: ${(p.precio * _cantidad.clamp(0.5, disponible)).toStringAsFixed(0)} \$',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    (_creandoOrden || !puedeSeleccionarCantidad) ? null : _crearOrdenYIrAlChat,
                child: _creandoOrden
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear orden e ir al chat'),
              ),
              const SizedBox(height: 8),
              Text(
                'Al confirmar se abrirá un chat con el productor para acordar punto de encuentro.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
