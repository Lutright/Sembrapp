import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../navigation/producto_detalle_extra.dart';
import '../repositories/ordenes_repository.dart';
import '../repositories/productos_repository.dart';

class _CarritoLinea {
  _CarritoLinea(this.producto, this.cantidad);
  final Producto producto;
  double cantidad;
}

/// Tienda de un campesino: varios productos en un solo pedido.
class TiendaCampesinoScreen extends StatefulWidget {
  const TiendaCampesinoScreen({
    super.key,
    required this.campesinoId,
    this.nombreTienda,
    this.productoInicial,
    this.cantidadInicial = 1.0,
  });

  final String campesinoId;
  final String? nombreTienda;
  /// Semilla al entrar desde el listado de productos del marketplace.
  final Producto? productoInicial;
  final double cantidadInicial;

  static const String _prefsKeyDistanceKm = 'marketplace_distance_km';

  @override
  State<TiendaCampesinoScreen> createState() => _TiendaCampesinoScreenState();
}

class _TiendaCampesinoScreenState extends State<TiendaCampesinoScreen> {
  final _repo = ProductosRepository(Supabase.instance.client);
  final _searchController = TextEditingController();
  final Map<String, _CarritoLinea> _carrito = {};

  List<Producto> _productos = [];
  bool _loading = true;
  String? _error;
  bool _semillaAplicada = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await LocationService.instance.getLastKnownOrFetch();
      if (pos == null) {
        setState(() {
          _loading = false;
          _error = 'Activa ubicación para ver esta tienda';
          _productos = [];
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final km = prefs.getInt(TiendaCampesinoScreen._prefsKeyDistanceKm);
      final radio =
          (km ?? 25).toDouble().clamp(1.0, 50.0).toDouble();

      final cercanos = await _repo.listarProductosCercanos(
        buyerLat: pos.latitude,
        buyerLng: pos.longitude,
        maxDistanceKm: radio,
        busqueda: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text,
      );
      final deTienda =
          cercanos.where((p) => p.campesinoId == widget.campesinoId).toList();

      if (mounted) {
        setState(() {
          _productos = deTienda;
          _loading = false;
          _carrito.removeWhere(
            (id, linea) => !deTienda.any((p) => p.id == id),
          );
        });
        _aplicarSemillaCarrito();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar la tienda';
        });
      }
    }
  }

  void _aplicarSemillaCarrito() {
    if (_semillaAplicada) return;
    final seed = widget.productoInicial;
    if (seed == null) return;
    if (seed.campesinoId != widget.campesinoId) return;
    _semillaAplicada = true;

    final mismo = _productos.where((x) => x.id == seed.id).toList();
    final prod = mismo.isNotEmpty ? mismo.first : seed;
    if (prod.cantidadDisponible < 0.5) return;

    const minC = 0.5;
    var cant = widget.cantidadInicial;
    if (cant < minC) cant = minC;
    if (cant > prod.cantidadDisponible) cant = prod.cantidadDisponible;

    _ajustarCantidad(prod, cant);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${prod.nombre}» añadido al pedido. Puedes seguir comprando aquí.',
          ),
        ),
      );
    }
  }

  void _ajustarCantidad(Producto p, double nueva) {
    if (nueva <= 0) {
      _carrito.remove(p.id);
    } else {
      final max = p.cantidadDisponible;
      final c = nueva.clamp(0.5, max);
      _carrito[p.id] = _CarritoLinea(p, c);
    }
    setState(() {});
  }

  double get _totalPrecio {
    var t = 0.0;
    for (final e in _carrito.values) {
      t += e.producto.precio * e.cantidad;
    }
    return t;
  }

  int get _totalLineas => _carrito.length;

  Future<void> _confirmarPedido() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_carrito.isEmpty) return;

    for (final e in _carrito.values) {
      if (e.cantidad > e.producto.cantidadDisponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '«${e.producto.nombre}» ya no tiene esa cantidad disponible',
            ),
          ),
        );
        return;
      }
    }

    final items = _carrito.values
        .map(
          (e) => {
            'producto_id': e.producto.id,
            'cantidad': e.cantidad,
            'precio_unitario': e.producto.precio,
          },
        )
        .toList();

    try {
      final ordenId = await OrdenesRepository(Supabase.instance.client)
          .crearOrden(
        compradorId: user.id,
        campesinoId: widget.campesinoId,
        items: items,
      );
      if (!mounted) return;
      setState(() => _carrito.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido creado. Un solo chat para acordar la entrega.',
          ),
        ),
      );
      context.push('/comercializacion/orden/$ordenId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el pedido: $e')),
        );
      }
    }
  }

  void _mostrarResumenPedido() {
    if (_carrito.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final lines = _carrito.values.toList();
        final maxH = MediaQuery.sizeOf(ctx).height * 0.45;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(ctx).bottom + 20,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu pedido',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = lines[i];
                    final sub = e.producto.precio * e.cantidad;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.producto.nombre),
                      subtitle: Text(
                        '${e.cantidad.toStringAsFixed(1)} ${e.producto.unidad} × '
                        '${e.producto.precio.toStringAsFixed(0)} \$',
                      ),
                      trailing: Text(
                        '${sub.toStringAsFixed(0)} \$',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ${_totalPrecio.toStringAsFixed(0)} \$',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmarPedido();
                },
                child: const Text('Confirmar pedido y abrir chat'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.nombreTienda?.trim().isNotEmpty == true
        ? widget.nombreTienda!.trim()
        : 'Tienda';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar en esta tienda',
              leading: const Icon(Icons.search_rounded),
              onSubmitted: (_) => _cargar(),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _cargar,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: AppPagePadding.screen,
                          child: Text(
                            'No hay productos de esta tienda en tu radio o con ese nombre.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: _productos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppPagePadding.tileGap),
                        itemBuilder: (context, i) {
                          final p = _productos[i];
                          final enCarrito = _carrito[p.id];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      p.nombre,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    subtitle: Text(
                                      '${p.precio.toStringAsFixed(0)} \$ / ${p.unidad} · '
                                      'Disponible: ${p.cantidadDisponible} ${p.unidad}',
                                    ),
                                    trailing: TextButton(
                                      onPressed: () {
                                        context.push(
                                          '/comercializacion/producto/${p.id}',
                                          extra: ProductoDetalleExtra(
                                            producto: p,
                                            onAgregarAlPedido: (prod, cant) {
                                              _ajustarCantidad(prod, cant);
                                            },
                                          ),
                                        );
                                      },
                                      child: const Text('Ver'),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text('Cantidad'),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () {
                                          final base = enCarrito?.cantidad ?? 0;
                                          if (base > 0.5) {
                                            _ajustarCantidad(p, base - 0.5);
                                          }
                                        },
                                        icon: const Icon(Icons.remove_circle_outline),
                                      ),
                                      Text(
                                        enCarrito == null
                                            ? '—'
                                            : enCarrito.cantidad
                                                .toStringAsFixed(1),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          final base = enCarrito?.cantidad ?? 0;
                                          final next = base <= 0 ? 0.5 : base + 0.5;
                                          _ajustarCantidad(p, next);
                                        },
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _carrito.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _mostrarResumenPedido,
                  child: Text(
                    'Revisar pedido ($_totalLineas · ${_totalPrecio.toStringAsFixed(0)} \$)',
                  ),
                ),
              ),
            ),
    );
  }
}
