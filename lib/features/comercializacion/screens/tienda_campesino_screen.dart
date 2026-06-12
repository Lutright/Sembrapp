import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../models/producto.dart';
import '../repositories/ordenes_repository.dart';
import '../repositories/productos_repository.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/tonalist_gradient_button.dart';
import '../../../core/widgets/tonalist_screen_header.dart';
import '../widgets/producto_imagen_de_url.dart';

// ─── Carrito ─────────────────────────────────────────────────────────────────
class _CarritoLinea {
  _CarritoLinea(this.producto, this.cantidad);
  final Producto producto;
  double cantidad;
}

// ═════════════════════════════════════════════════════════════════════════════
// TiendaCampesinoScreen — Vitrina Premium
// ═════════════════════════════════════════════════════════════════════════════
class TiendaCampesinoScreen extends StatefulWidget {
  const TiendaCampesinoScreen({
    super.key,
    required this.campesinoId,
    this.nombreTienda,
    this.productoInicial,
    this.cantidadInicial = 1.0,
    this.isDestacado = false,
  });

  final String campesinoId;
  final String? nombreTienda;
  final Producto? productoInicial;
  final double cantidadInicial;
  final bool isDestacado;

  static const String _prefsKeyDistanceKm = 'marketplace_distance_km';

  @override
  State<TiendaCampesinoScreen> createState() => _TiendaCampesinoScreenState();
}

class _TiendaCampesinoScreenState extends State<TiendaCampesinoScreen> {
  final _repo = ProductosRepository(Supabase.instance.client);
  final _searchController = TextEditingController();
  final Map<String, _CarritoLinea> _carrito = {};

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
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
    _searchController.addListener(_filtrarProductos);
    _cargar();
  }

  // ─── Normalización y filtrado en tiempo real ───────────────────────────────

  /// Elimina tildes/acentos para búsqueda insensible.
  static String _normalizar(String s) {
    const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑ';
    const sinAcento = 'aaaaaeeeeiiiiooooouuuunAAAAAEEEEIIIIOOOOOUUUUN';
    var out = s;
    for (var i = 0; i < conAcento.length; i++) {
      out = out.replaceAll(conAcento[i], sinAcento[i]);
    }
    return out.toLowerCase();
  }

  void _filtrarProductos() {
    final q = _normalizar(_searchController.text.trim());
    if (q.isEmpty) {
      setState(() => _productosFiltrados = List.from(_productos));
    } else {
      setState(() {
        _productosFiltrados =
            _productos.where((p) => _normalizar(p.nombre).contains(q)).toList();
      });
    }
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

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
      final radio = (km ?? 25).toDouble().clamp(1.0, 50.0).toDouble();

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
          _productosFiltrados = List.from(deTienda);
          _loading = false;
          _carrito.removeWhere(
            (id, linea) => !deTienda.any((p) => p.id == id),
          );
        });
        _filtrarProductos();
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
    if (prod.limiteSuperiorPedido < 0.5) return;

    const minC = 0.5;
    var cant = widget.cantidadInicial;
    if (cant < minC) cant = minC;
    if (cant > prod.limiteSuperiorPedido) cant = prod.limiteSuperiorPedido;

    _ajustarCantidad(prod, cant);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${prod.nombre}» añadido al pedido. Puedes seguir comprando aquí.',
          ),
          backgroundColor: TonalistColors.azulHorizonte,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _ajustarCantidad(Producto p, double nueva) {
    if (nueva <= 0) {
      _carrito.remove(p.id);
    } else {
      final max = p.limiteSuperiorPedido;
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
      if (e.producto.tieneStockDeclarado &&
          e.cantidad > e.producto.cantidadDisponible!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '«${e.producto.nombre}» supera la cantidad referenciada',
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
      final ordenId =
          await OrdenesRepository(Supabase.instance.client).crearOrden(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                    ),
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
                      title: Text(
                        e.producto.nombre,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${e.cantidad.toStringAsFixed(1)} ${e.producto.unidad} × '
                        '${e.producto.precio.toStringAsFixed(0)} \$',
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                      trailing: Text(
                        '${sub.toStringAsFixed(0)} \$',
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              color: TonalistColors.azulHorizonte,
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ${_totalPrecio.toStringAsFixed(0)} \$',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TonalistGradientButton(
                label: 'Confirmar pedido y abrir chat',
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmarPedido();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDestacado = widget.isDestacado;
    final titulo = widget.nombreTienda?.trim().isNotEmpty == true
        ? widget.nombreTienda!.trim()
        : 'Tienda';
    final nombreProductor = titulo;

    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: Stack(
        children: [
          // 1. Contenido scrolleable
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Espacio para el header
                SliverToBoxAdapter(
                  child: const SizedBox(
                    height: TonalistHeaderMetrics.contentTopPadding,
                  ),
                ),

                // Barra de búsqueda
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Buscar en esta tienda...',
                          hintStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey[400]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.grey[500], size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // Error
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Contenido principal
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(
                        child:
                            CircularProgressIndicator(color: TonalistColors.azulHorizonte)),
                  )
                else if (_productos.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos de esta tienda en tu radio.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Lista de productos premium
                  _productosFiltrados.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Sin resultados para tu búsqueda.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                // Separador de 12px entre tarjetas
                                if (i.isOdd) {
                                  return const SizedBox(height: 12);
                                }
                                final idx = i ~/ 2;
                                final p = _productosFiltrados[idx];
                                final enCarrito = _carrito[p.id];
                                return _buildProductCard(context, p, enCarrito);
                              },
                              childCount: _productosFiltrados.length * 2 - 1,
                            ),
                          ),
                        ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: TonalistHeaderMetrics.standardHeight,
            child: const IgnorePointer(
              ignoring: true,
              child: TonalistHeaderWave(
                height: TonalistHeaderMetrics.standardHeight,
              ),
            ),
          ),

          // 3. Controles del header
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: TonalistHeaderMetrics.standardHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 4,
                      child: SafeArea(
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            nombreProductor,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tienda · Productos disponibles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar: Revisar pedido ──────────────────────────────────────
      bottomNavigationBar: _carrito.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TonalistGradientButton(
                  label:
                      'Revisar pedido ($_totalLineas · ${_totalPrecio.toStringAsFixed(0)} \$)',
                  onPressed: _mostrarResumenPedido,
                ),
              ),
            ),
    );
  }

  // ─── Tarjeta de Producto Premium ───────────────────────────────────────────

  Widget _buildProductCard(
      BuildContext context, Producto p, _CarritoLinea? enCarrito) {
    // Detectar si es "Nuevo" (creado en los últimos 3 días)
    final bool esNuevo = p.createdAt != null &&
        DateTime.now().difference(p.createdAt!).inDays < 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ── Row principal: Imagen + Info ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen / Placeholder
                  _buildProductImage(p, esNuevo),
                  const SizedBox(width: 14),

                  // Contenido central — más ancho sin botón info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre en negrita
                        Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Precio en Azul Horizonte
                        Text(
                          '\$${p.precio.toStringAsFixed(0)} / ${p.unidad}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TonalistColors.azulHorizonte,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Referencia de peso/stock
                        Text(
                          p.tieneStockDeclarado
                              ? 'Ref: ${p.cantidadDisponible?.toStringAsFixed(1) ?? "—"} ${p.unidad}'
                              : 'Disponibilidad variable',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Fila inferior: descripción parcial + controles de cantidad ──
              Row(
                children: [
                  // Descripción truncada si existe
                  if (p.descripcion?.isNotEmpty == true)
                    Expanded(
                      child: Text(
                        p.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  // Controles de cantidad en cápsula
                  _buildQuantityControls(p, enCarrito),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Imagen del producto con badge ─────────────────────────────────────────

  Widget _buildProductImage(Producto p, bool esNuevo) {
    return Stack(
      children: [
        ProductoImagenDeUrl(
          url: p.imagenUrl,
          width: 85,
          height: 85,
          borderRadius: BorderRadius.circular(14),
          placeholderColor: const Color(0xFFF2F7F2),
          placeholderIcon: Icons.eco_rounded,
        ),
        // Badge "Nuevo"
        if (esNuevo)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TonalistColors.rojoManta,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NUEVO',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Controles de cantidad (cápsula) ───────────────────────────────────────

  Widget _buildQuantityControls(Producto p, _CarritoLinea? enCarrito) {
    final base = enCarrito?.cantidad ?? 0;
    final cantidadTexto = base <= 0 ? '0' : base.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón menos — hitbox generoso
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 22,
              onPressed: () {
                final c = enCarrito?.cantidad ?? 0;
                if (c > 0.5) {
                  _ajustarCantidad(p, c - 0.5);
                }
              },
              icon: Opacity(
                opacity: base <= 0 ? 0.4 : 1,
                child: const Icon(Icons.remove_rounded, color: TonalistColors.azulHorizonte),
              ),
            ),
          ),

          // Cantidad en negrita
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              cantidadTexto,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),

          // Botón más — hitbox generoso
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 22,
              onPressed: () {
                final c = enCarrito?.cantidad ?? 0;
                final next = c <= 0 ? 0.5 : c + 0.5;
                _ajustarCantidad(p, next);
              },
              icon: const Icon(Icons.add_rounded, color: TonalistColors.azulHorizonte),
            ),
          ),
        ],
      ),
    );
  }
}
