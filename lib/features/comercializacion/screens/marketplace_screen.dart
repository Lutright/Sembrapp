import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../models/tienda_resumen.dart';
import '../navigation/tienda_campesino_extra.dart';
import '../repositories/beneficios_repository.dart';
import '../repositories/productos_repository.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/tonalist_screen_header.dart';
import '../widgets/producto_imagen_de_url.dart';

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 36, color: cs.onPrimary),
            const SizedBox(height: 6),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// Comprador: productos cercanos y tiendas (campesinos) en el mismo radio.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  static const String _prefsKeyDistanceKm = 'marketplace_distance_km';
  int _selectedDistanceKm = 25;

  final ProductosRepository _repo =
      ProductosRepository(Supabase.instance.client);
  final BeneficiosRepository _beneficiosRepo =
      BeneficiosRepository(Supabase.instance.client);

  List<Producto> _productosCercanos = [];
  List<TiendaResumen> _tiendas = [];
  Set<String> _campesinosDestacados = {};
  bool _loading = true;
  String _query = '';
  String? _locationError;
  final _searchController = TextEditingController();
  double? _buyerLat;
  double? _buyerLng;

  /// 0 = productos, 1 = tiendas
  int _seccion = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadSavedDistance();
    await _load();
  }

  Future<void> _loadSavedDistance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefsKeyDistanceKm);
      if (saved != null && saved >= 1 && saved <= 50 && mounted) {
        setState(() => _selectedDistanceKm = saved);
      }
    } catch (_) {}
  }

  Future<void> _saveDistance(int km) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyDistanceKm, km);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reconstruirTiendas() {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _productosCercanos
        : _productosCercanos
            .where((p) => p.nombre.toLowerCase().contains(q))
            .toList();
    _tiendas = TiendaResumen.agruparDesdeProductos(
      filtered,
      campesinosDestacados: _campesinosDestacados,
    );
  }

  List<Producto> _productosFiltrados() {
    final q = _query.trim().toLowerCase();
    final raw = q.isEmpty
        ? _productosCercanos
        : _productosCercanos
            .where((p) => p.nombre.toLowerCase().contains(q))
            .toList();
    return TiendaResumen.ordenarProductosPorVisibilidad(
      raw,
      _campesinosDestacados,
    );
  }

  void _anadirAlCarritoEIrATienda(Producto p) {
    if (p.limiteSuperiorPedido < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Este producto no tiene stock suficiente')),
      );
      return;
    }
    final cap = p.limiteSuperiorPedido;
    final cant = cap >= 1.0 ? 1.0 : cap;
    context.push(
      '/comercializacion/tienda/${p.campesinoId}',
      extra: TiendaCampesinoExtra(
        nombreTienda: p.campesinoNombre,
        productoInicial: p,
        cantidadInicial: cant,
        isDestacado: _campesinosDestacados.contains(p.campesinoId),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_buyerLat == null || _buyerLng == null) {
        final buyerPos = await LocationService.instance.getLastKnownOrFetch();
        if (buyerPos == null) {
          if (mounted) {
            setState(() {
              _productosCercanos = [];
              _tiendas = [];
              _locationError = 'Activa ubicación para ver tiendas cercanas';
              _loading = false;
            });
          }
          return;
        }
        _buyerLat = buyerPos.latitude;
        _buyerLng = buyerPos.longitude;
      }

      final list = await _repo.listarProductosCercanos(
        buyerLat: _buyerLat!,
        buyerLng: _buyerLng!,
        maxDistanceKm: _selectedDistanceKm.toDouble(),
      );

      final destacados =
          await _beneficiosRepo.getCampesinosConBeneficioVigente();

      if (mounted) {
        setState(() {
          _productosCercanos = list;
          _campesinosDestacados = destacados;
          _reconstruirTiendas();
          _loading = false;
          _locationError = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadSoloDistancia() async {
    if (_buyerLat == null || _buyerLng == null) {
      await _load();
      return;
    }

    setState(() => _loading = true);
    try {
      final list = await _repo.listarProductosCercanos(
        buyerLat: _buyerLat!,
        buyerLng: _buyerLng!,
        maxDistanceKm: _selectedDistanceKm.toDouble(),
      );
      final destacados =
          await _beneficiosRepo.getCampesinosConBeneficioVigente();

      if (mounted) {
        setState(() {
          _productosCercanos = list;
          _campesinosDestacados = destacados;
          _reconstruirTiendas();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _productosCercanos = [];
          _tiendas = [];
          _loading = false;
        });
      }
    }
  }

  Widget _emptyMarketplace(BuildContext context, String message) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: AppPagePadding.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.my_location),
                label: const Text('Actualizar ubicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaProductos(BuildContext context) {
    if (_locationError != null)
      return _emptyMarketplace(context, _locationError!);
    final list = _productosFiltrados();
    if (_productosCercanos.isEmpty) {
      return _emptyMarketplace(
        context,
        _query.isEmpty
            ? 'No hay productos en tu radio'
            : 'Ningún producto coincide',
      );
    }
    if (list.isEmpty)
      return _emptyMarketplace(context, 'Ningún producto coincide');

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.55),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final p = list[i];
            final cs = Theme.of(context).colorScheme;
            final prod = p.campesinoNombre?.trim().isNotEmpty == true
                ? p.campesinoNombre!.trim()
                : 'Productor';
            final esDestacado = _campesinosDestacados.contains(p.campesinoId);
            return Card(
              elevation: 4,
              shadowColor: cs.shadow.withValues(alpha: 0.2),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          return ProductoImagenDeUrl(
                            url: p.imagenUrl,
                            width: c.maxWidth,
                            height: c.maxHeight,
                            borderRadius: BorderRadius.zero,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (esDestacado) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 4, top: 2),
                                  child: Icon(Icons.star_rounded,
                                      size: 16, color: cs.tertiary),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  p.nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.precio.toStringAsFixed(0)} \$ / ${p.unidad}',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${p.tieneStockDeclarado ? 'Ref: ${p.cantidadDisponible} ${p.unidad}' : 'Disponibilidad variable'}\n'
                                '${esDestacado ? '⭐ Tienda destacada · ' : ''}$prod',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.2),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                padding: EdgeInsets.zero,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _anadirAlCarritoEIrATienda(p),
                              child: const Text('Añadir'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildListaTiendas(BuildContext context) {
    if (_locationError != null)
      return _emptyMarketplace(context, _locationError!);
    if (_tiendas.isEmpty) {
      return _emptyMarketplace(
        context,
        _query.isEmpty
            ? 'No hay tiendas en tu radio'
            : 'Ninguna tienda tiene ese producto',
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final t = _tiendas[i];
            final cs = Theme.of(context).colorScheme;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                tileColor: cs.surfaceTint.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.storefront_rounded,
                      color: cs.onPrimaryContainer, size: 28),
                ),
                title: Text(
                  t.nombre?.trim().isNotEmpty == true
                      ? t.nombre!.trim()
                      : 'Productor',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${t.cantidadProductos} producto${t.cantidadProductos != 1 ? 's' : ''} cerca\n'
                  '${t.destacado ? '⭐ Destacado' : ''}',
                ),
                isThreeLine: true,
                onTap: () => context.push(
                  '/comercializacion/tienda/${t.campesinoId}',
                  extra: TiendaCampesinoExtra(
                    nombreTienda: t.nombre,
                    isDestacado: t.destacado,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
            );
          },
          childCount: _tiendas.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: Stack(
        children: [
          TonalistHeaderBackground(
            height: TonalistHeaderMetrics.marketplaceHeight,
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Órdenes',
                          onTap: () =>
                              context.push('/comercializacion/ordenes'),
                        ),
                        _HeaderAction(
                          icon: Icons.person_rounded,
                          label: 'Perfil',
                          onTap: () => context.push('/profile'),
                        ),
                        _HeaderAction(
                          icon: Icons.logout_rounded,
                          label: 'Salir',
                          onTap: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 42, 16, 16),
                    child: Card(
                      elevation: 4,
                      shadowColor: cs.shadow.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      color: cs.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment<int>(
                                  value: 0,
                                  label: Text('Productos'),
                                  icon: Icon(Icons.inventory_2_outlined),
                                ),
                                ButtonSegment<int>(
                                  value: 1,
                                  label: Text('Tiendas'),
                                  icon: Icon(Icons.storefront_outlined),
                                ),
                              ],
                              selected: {_seccion},
                              onSelectionChanged: (s) =>
                                  setState(() => _seccion = s.first),
                            ),
                            const SizedBox(height: 16),
                            SearchBar(
                              controller: _searchController,
                              elevation: const WidgetStatePropertyAll(0),
                              backgroundColor: WidgetStatePropertyAll(cs
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4)),
                              hintText: _seccion == 0
                                  ? 'Buscar producto'
                                  : 'Buscar (filtra prod. en tienda)',
                              leading: const Icon(Icons.search_rounded),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 16)),
                              onChanged: (v) {
                                setState(() {
                                  _query = v;
                                  _reconstruirTiendas();
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Distancia máxima:',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '$_selectedDistanceKm km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Slider(
                              min: 5,
                              max: 50,
                              divisions: 9, // Salto táctil de 5km
                              activeColor: cs.primary,
                              value: _selectedDistanceKm
                                  .toDouble()
                                  .clamp(5.0, 50.0),
                              label: '$_selectedDistanceKm km',
                              onChanged: (v) => setState(
                                  () => _selectedDistanceKm = v.round()),
                              onChangeEnd: (v) async {
                                await _saveDistance(v.round());
                                await _reloadSoloDistancia();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Center(
                      child: Text(
                        _seccion == 0
                            ? 'Productos Disponibles'
                            : 'Productores Locales',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  letterSpacing: -0.5,
                                ),
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _seccion == 0
                      ? _buildListaProductos(context)
                      : _buildListaTiendas(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
