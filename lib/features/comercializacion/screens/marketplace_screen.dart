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
    if (q.isEmpty) return _productosCercanos;
    return _productosCercanos
        .where((p) => p.nombre.toLowerCase().contains(q))
        .toList();
  }

  void _anadirAlCarritoEIrATienda(Producto p) {
    if (p.cantidadDisponible < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto no tiene stock suficiente')),
      );
      return;
    }
    final cant = p.cantidadDisponible >= 1.0 ? 1.0 : p.cantidadDisponible;
    context.push(
      '/comercializacion/tienda/${p.campesinoId}',
      extra: TiendaCampesinoExtra(
        nombreTienda: p.campesinoNombre,
        productoInicial: p,
        cantidadInicial: cant,
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

      final destacados = await _beneficiosRepo.getCampesinosConBeneficioVigente();

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
      final destacados = await _beneficiosRepo.getCampesinosConBeneficioVigente();

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
    return Center(
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
    );
  }

  Widget _buildListaProductos(BuildContext context) {
    if (_locationError != null) {
      return _emptyMarketplace(context, _locationError!);
    }
    final list = _productosFiltrados();
    if (_productosCercanos.isEmpty) {
      return _emptyMarketplace(
        context,
        _query.isEmpty
            ? 'No hay productos en tu radio'
            : 'Ningún producto coincide',
      );
    }
    if (list.isEmpty) {
      return _emptyMarketplace(context, 'Ningún producto coincide');
    }
    return ListView.separated(
      padding: AppPagePadding.screen.copyWith(bottom: 24),
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppPagePadding.tileGap),
      itemBuilder: (context, i) {
        final p = list[i];
        final prod = p.campesinoNombre?.trim().isNotEmpty == true
            ? p.campesinoNombre!.trim()
            : 'Productor';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.nombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${p.precio.toStringAsFixed(0)} \$ / ${p.unidad} · '
                    'Disponible: ${p.cantidadDisponible} ${p.unidad}\n$prod',
                  ),
                  isThreeLine: true,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '/comercializacion/producto/${p.id}',
                          extra: p,
                        ),
                        child: const Text('Ver detalle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _anadirAlCarritoEIrATienda(p),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Añadir al carrito'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaTiendas(BuildContext context) {
    if (_locationError != null) {
      return _emptyMarketplace(context, _locationError!);
    }
    if (_tiendas.isEmpty) {
      return _emptyMarketplace(
        context,
        _query.isEmpty
            ? 'No hay tiendas en tu radio'
            : 'Ninguna tienda tiene ese producto',
      );
    }
    return ListView.separated(
      padding: AppPagePadding.screen,
      itemCount: _tiendas.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppPagePadding.tileGap),
      itemBuilder: (context, i) {
        final t = _tiendas[i];
        return BigNavTile(
          icon: Icons.storefront_rounded,
          title: t.nombre?.trim().isNotEmpty == true
              ? t.nombre!.trim()
              : 'Productor',
          subtitle:
              '${t.cantidadProductos} producto${t.cantidadProductos != 1 ? 's' : ''} cerca de ti'
              '${t.destacado ? ' · Destacado' : ''}',
          onTap: () => context.push(
            '/comercializacion/tienda/${t.campesinoId}',
            extra: TiendaCampesinoExtra(nombreTienda: t.nombre),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comercialización'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => context.push('/comercializacion/ordenes'),
            tooltip: 'Mis pedidos',
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => context.push('/profile'),
            tooltip: 'Mi perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SegmentedButton<int>(
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
              onSelectionChanged: (Set<int> s) {
                setState(() => _seccion = s.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: _seccion == 0
                  ? 'Buscar producto'
                  : 'Buscar producto (filtra tiendas)',
              leading: const Icon(Icons.search_rounded),
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _reconstruirTiendas();
                });
              },
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distancia máxima',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '$_selectedDistanceKm km',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                Slider(
                  min: 1,
                  max: 50,
                  divisions: 49,
                  value: _selectedDistanceKm.toDouble(),
                  label: '$_selectedDistanceKm km',
                  onChanged: (v) {
                    setState(() => _selectedDistanceKm = v.round());
                  },
                  onChangeEnd: (v) async {
                    final km = v.round();
                    await _saveDistance(km);
                    await _reloadSoloDistancia();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _seccion == 0
                    ? _buildListaProductos(context)
                    : _buildListaTiendas(context),
          ),
        ],
      ),
    );
  }
}
