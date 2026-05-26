import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../models/producto.dart';
import '../navigation/tienda_campesino_extra.dart';
import '../repositories/orden_ayuda_repository.dart';
import '../repositories/productos_repository.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
const Color _crema = Color(0xFFFBF9F1);
const Color _rojoManta = Color(0xFFD34836);

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.06,
        0,
        size.height * 0.78,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

List<String> _asUuidList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

/// Red comunitaria: productores y pedidos de ayuda cercanos (misma lógica de radio que comercialización).
class RedComunitariaScreen extends StatefulWidget {
  const RedComunitariaScreen({super.key});

  static const String _prefsKeyDistanceKm = 'marketplace_distance_km';

  @override
  State<RedComunitariaScreen> createState() => _RedComunitariaScreenState();
}

class _RedComunitariaScreenState extends State<RedComunitariaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ayudaRepo = OrdenAyudaRepository(Supabase.instance.client);
  final _productoRepo = ProductosRepository(Supabase.instance.client);

  int _selectedDistanceKm = 25;
  double? _buyerLat;
  double? _buyerLng;
  String? _locationError;

  List<_CampesinoCercano> _campesinos = [];
  List<Map<String, dynamic>> _solicitudesFiltradas = [];
  List<Map<String, dynamic>> _misSolicitudesCreadas = [];
  List<Map<String, dynamic>> _misSolicitudesAceptadas = [];
  Map<String, String> _nombresSolicitantes = {};
  Map<String, String> _nombresMisSolicitudes = {};

  bool _loadingCampesinos = true;
  bool _loadingSolicitudes = true;
  bool _loadingMisSolicitudes = true;
  RealtimeChannel? _solicitudesChannel;
  RealtimeChannel? _productosChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _init();
    _suscribirRealtime();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  Future<void> _init() async {
    await _loadSavedDistance();
    await _loadUbicacionYDatos();
  }

  Future<void> _loadSavedDistance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(RedComunitariaScreen._prefsKeyDistanceKm);
      if (saved != null && saved >= 1 && saved <= 50 && mounted) {
        setState(() => _selectedDistanceKm = saved);
      }
    } catch (_) {}
  }

  Future<void> _saveDistance(int km) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(RedComunitariaScreen._prefsKeyDistanceKm, km);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_solicitudesChannel != null) {
      Supabase.instance.client.removeChannel(_solicitudesChannel!);
    }
    if (_productosChannel != null) {
      Supabase.instance.client.removeChannel(_productosChannel!);
    }
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _suscribirRealtime() {
    _solicitudesChannel = Supabase.instance.client
        .channel('red_comunitaria_solicitudes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orden_ayuda_solicitud',
          callback: (_) {
            if (mounted) _refreshDataRealtime();
          },
        )
        .subscribe();

    _productosChannel = Supabase.instance.client
        .channel('red_comunitaria_productos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'productos',
          callback: (_) {
            if (mounted) _refreshDataRealtime();
          },
        )
        .subscribe();
  }

  Future<void> _refreshDataRealtime() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (_buyerLat == null || _buyerLng == null) {
      await _loadUbicacionYDatos();
      return;
    }
    await Future.wait([
      _loadCampesinos(uid),
      _loadSolicitudes(uid),
      _loadMisSolicitudes(uid),
    ]);
  }

  Future<void> _loadUbicacionYDatos() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    setState(() {
      _loadingCampesinos = true;
      _loadingSolicitudes = true;
      _loadingMisSolicitudes = true;
      _locationError = null;
    });

    await _loadMisSolicitudes(uid);

    final pos = await LocationService.instance.getLastKnownOrFetch();
    if (pos == null) {
      if (mounted) {
        setState(() {
          _locationError = 'Activa ubicación para ver la red cercana';
          _campesinos = [];
          _solicitudesFiltradas = [];
          _loadingCampesinos = false;
          _loadingSolicitudes = false;
        });
      }
      return;
    }
    _buyerLat = pos.latitude;
    _buyerLng = pos.longitude;

    await Future.wait([_loadCampesinos(uid), _loadSolicitudes(uid)]);
    await _syncMapAnchorToProfile(uid);
  }

  /// Ancla GPS + radio en `profiles` para que el webhook de push filtre como esta pantalla.
  Future<void> _syncMapAnchorToProfile(String? uid) async {
    if (uid == null || _buyerLat == null || _buyerLng == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'last_map_lat': _buyerLat,
        'last_map_lng': _buyerLng,
        'last_map_at': DateTime.now().toUtc().toIso8601String(),
        'red_comunitaria_radius_km': _selectedDistanceKm,
      }).eq('id', uid);
    } catch (_) {}
  }

  Future<void> _loadCampesinos(String? uid) async {
    if (_buyerLat == null || _buyerLng == null) return;
    try {
      final list = await _productoRepo.listarProductosCercanos(
        buyerLat: _buyerLat!,
        buyerLng: _buyerLng!,
        maxDistanceKm: _selectedDistanceKm.toDouble(),
      );
      final by = <String, List<Producto>>{};
      for (final p in list) {
        by.putIfAbsent(p.campesinoId, () => []).add(p);
      }
      final otros = by.entries.where((e) => uid == null || e.key != uid).toList();
      final enriched = otros.map((e) {
        var minD = double.infinity;
        for (final p in e.value) {
          if (p.lat != null && p.lng != null) {
            final d = distanceKm(
              lat1: _buyerLat!,
              lng1: _buyerLng!,
              lat2: p.lat!,
              lng2: p.lng!,
            );
            if (d < minD) minD = d;
          }
        }
        final nombre = e.value.first.campesinoNombre?.trim().isNotEmpty == true
            ? e.value.first.campesinoNombre!.trim()
            : 'Productor';
        return _CampesinoCercano(
          id: e.key,
          nombre: nombre,
          cantidadProductos: e.value.length,
          distanciaKm: minD.isFinite ? minD : 0,
        );
      }).toList();
      enriched.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
      if (mounted) {
        setState(() {
          _campesinos = enriched;
          _loadingCampesinos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCampesinos = false);
    }
  }

  Future<void> _loadSolicitudes(String? uid) async {
    if (_buyerLat == null || _buyerLng == null) return;
    try {
      final all = await _ayudaRepo.listarSolicitudesAbiertas();
      final maxKm = _selectedDistanceKm.toDouble();
      final filtradas = <Map<String, dynamic>>[];
      for (final s in all) {
        final sid = s['solicitante_id'] as String?;
        if (sid != null && sid == uid) continue;
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final d = distanceKm(
          lat1: _buyerLat!,
          lng1: _buyerLng!,
          lat2: lat,
          lng2: lng,
        );
        if (d <= maxKm) {
          filtradas.add({...s, '_dist_km': d});
        }
      }
      final ids = filtradas
          .map((s) => s['solicitante_id'] as String?)
          .whereType<String>()
          .toSet();
      final nombres = await _ayudaRepo.nombresCampesinos(ids);
      if (mounted) {
        setState(() {
          _solicitudesFiltradas = filtradas;
          _nombresSolicitantes = nombres;
          _loadingSolicitudes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSolicitudes = false);
    }
  }

  Future<void> _onDistanceChangedEnd(double v) async {
    final km = v.round();
    await _saveDistance(km);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await Supabase.instance.client.from('profiles').update({
          'red_comunitaria_radius_km': km,
        }).eq('id', uid);
      } catch (_) {}
    }
    await _loadUbicacionYDatos();
  }

  Future<void> _mostrarDetalleSolicitud(Map<String, dynamic> s) async {
    final solicitudId = s['id'] as String? ?? '';
    final ordenId = s['orden_id'] as String? ?? '';
    final itemIds = _asUuidList(s['item_ids']);
    final nota = s['nota'] as String?;
    final solicitanteId = s['solicitante_id'] as String?;
    final nombreSol =
        solicitanteId != null ? _nombresSolicitantes[solicitanteId] : null;

    List<Map<String, dynamic>> items = [];
    try {
      final client = Supabase.instance.client;
      final List<dynamic> res;
      if (itemIds.isEmpty) {
        res = await client
            .from('orden_items')
            .select('id, cantidad, precio_unitario, productos(nombre, unidad)')
            .eq('orden_id', ordenId);
      } else {
        res = await client
            .from('orden_items')
            .select('id, cantidad, precio_unitario, productos(nombre, unidad)')
            .eq('orden_id', ordenId)
            .inFilter('id', itemIds);
      }
      items = List<Map<String, dynamic>>.from(res);
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) {
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
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pedido de ayuda',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                nombreSol != null
                    ? '$nombreSol necesita apoyo con parte de un pedido.'
                    : 'Un productor necesita apoyo con parte de un pedido.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: _azulHorizonte,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (nota != null && nota.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Nota:',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  nota,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Productos:',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.35,
                ),
                child: items.isEmpty
                    ? const Text('No se pudieron cargar los ítems.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final row = items[i];
                          final cant =
                              (row['cantidad'] as num?)?.toDouble() ?? 0;
                          final p = row['productos'];
                          String nombre = 'Producto';
                          String u = '';
                          if (p is Map) {
                            nombre = p['nombre'] as String? ?? nombre;
                            u = p['unidad'] as String? ?? '';
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _azulHorizonte.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(nombre)),
                                Text(
                                  '${cant.toStringAsFixed(cant == cant.roundToDouble() ? 0 : 1)} $u',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final ok = await _ayudaRepo.aceptarSolicitud(solicitudId);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        if (ok) {
                          await _loadUbicacionYDatos();
                          if (mounted) {
                            context.push('/comercializacion/ayuda-chat/$solicitudId');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ya no está disponible u otro productor la aceptó.',
                              ),
                            ),
                          );
                          await _loadUbicacionYDatos();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _rojoManta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Aceptar y abrir chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: Column(
                children: [
                  Container(
                    color: _crema,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        _TabPill(
                          label: 'Productores',
                          selected: _tabController.index == 0,
                          onTap: () => _tabController.animateTo(0),
                        ),
                        const SizedBox(width: 8),
                        _TabPill(
                          label: 'Ayuda',
                          selected: _tabController.index == 1,
                          onTap: () => _tabController.animateTo(1),
                        ),
                        const SizedBox(width: 8),
                        _TabPill(
                          label: 'Mis solicitudes',
                          selected: _tabController.index == 2,
                          onTap: () => _tabController.animateTo(2),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Distancia máxima',
                                style: TextStyle(
                                  color: _azulHorizonte,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$_selectedDistanceKm km',
                                style: const TextStyle(
                                  color: _azulHorizonte,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _azulHorizonte,
                              thumbColor: _azulHorizonte,
                            ),
                            child: Slider(
                              min: 1,
                              max: 50,
                              divisions: 49,
                              value: _selectedDistanceKm.toDouble(),
                              label: '$_selectedDistanceKm km',
                              onChanged: (v) =>
                                  setState(() => _selectedDistanceKm = v.round()),
                              onChangeEnd: _onDistanceChangedEnd,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabCampesinos(),
                        _buildTabSolicitudes(),
                        _buildTabMisSolicitudes(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: _azulHorizonte),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Red comunitaria',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Productores cerca de ti',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCampesinos() {
    if (_loadingCampesinos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_locationError != null) {
      return _emptyState(_locationError!, showRefresh: true);
    }
    if (_campesinos.isEmpty) {
      return _emptyState(
        'No hay otros productores con oferta en tu radio.',
        showRefresh: true,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _azulHorizonte.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: _azulHorizonte),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estos son los productores dentro de tu radio seleccionado. '
                    'Toca uno para ver sus productos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _azulHorizonte.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _campesinos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = _campesinos[i];
              return _CommunityCard(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: _azulHorizonte.withValues(alpha: 0.10),
                  child: Text(
                    _iniciales(c.nombre),
                    style: const TextStyle(
                      color: _azulHorizonte,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: c.nombre,
                subtitle:
                    '${c.cantidadProductos} producto${c.cantidadProductos != 1 ? 's' : ''} · '
                    '${c.distanciaKm.toStringAsFixed(1)} km',
                onTap: () => context.push(
                  '/comercializacion/tienda/${c.id}',
                  extra: TiendaCampesinoExtra(nombreTienda: c.nombre),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabSolicitudes() {
    if (_loadingSolicitudes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_locationError != null) {
      return _emptyState(_locationError!, showRefresh: true);
    }
    if (_solicitudesFiltradas.isEmpty) {
      return _emptyState(
        'No hay pedidos de ayuda en tu radio. '
        'Cuando un colega no pueda cubrir un producto, lo publicará desde su pedido.',
        showRefresh: true,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _solicitudesFiltradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _solicitudesFiltradas[i];
        final sid = s['solicitante_id'] as String?;
        final nombre = sid != null ? _nombresSolicitantes[sid] : null;
        final d = (s['_dist_km'] as double?) ?? 0;
        final nItems = _asUuidList(s['item_ids']).length;
        return _CommunityCard(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: _azulHorizonte.withValues(alpha: 0.10),
            child: const Icon(
              Icons.handshake_outlined,
              color: _azulHorizonte,
              size: 24,
            ),
          ),
          title: nombre ?? 'Productor',
          subtitle:
              '$nItems producto${nItems != 1 ? 's' : ''} · ${d.toStringAsFixed(1)} km',
          onTap: () => _mostrarDetalleSolicitud(s),
        );
      },
    );
  }

  Widget _emptyState(String message, {bool showRefresh = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
            ),
            if (showRefresh) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _loadUbicacionYDatos,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Actualizar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return 'P';
    if (partes.length == 1) {
      return partes.first.characters.take(2).toString().toUpperCase();
    }
    return (partes.first.characters.first + partes[1].characters.first)
        .toUpperCase();
  }

  Future<void> _loadMisSolicitudes(String? uid) async {
    if (uid == null) {
      if (mounted) {
        setState(() {
          _misSolicitudesCreadas = [];
          _misSolicitudesAceptadas = [];
          _nombresMisSolicitudes = {};
          _loadingMisSolicitudes = false;
        });
      }
      return;
    }

    try {
      final creadas = await _ayudaRepo.listarSolicitudesCreadasPorUsuario(uid);
      final aceptadas =
          await _ayudaRepo.listarSolicitudesAceptadasPorUsuario(uid);
      final otrosIds = <String>{};

      for (final s in creadas) {
        final ayudanteId = s['ayudante_id'] as String?;
        if (ayudanteId != null && ayudanteId.isNotEmpty) {
          otrosIds.add(ayudanteId);
        }
      }
      for (final s in aceptadas) {
        final solicitanteId = s['solicitante_id'] as String?;
        if (solicitanteId != null && solicitanteId.isNotEmpty) {
          otrosIds.add(solicitanteId);
        }
      }

      final nombres = await _ayudaRepo.nombresCampesinos(otrosIds);
      if (!mounted) return;
      setState(() {
        _misSolicitudesCreadas = creadas;
        _misSolicitudesAceptadas = aceptadas;
        _nombresMisSolicitudes = nombres;
        _loadingMisSolicitudes = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMisSolicitudes = false;
        });
      }
    }
  }

  Widget _buildTabMisSolicitudes() {
    if (_loadingMisSolicitudes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_misSolicitudesCreadas.isEmpty && _misSolicitudesAceptadas.isEmpty) {
      return _emptyState(
        'Aún no tienes solicitudes creadas ni aceptadas.',
        showRefresh: true,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildSeccionMisSolicitudes(
          titulo: 'Aceptadas por mí',
          vacio: 'No has aceptado solicitudes todavía.',
          icon: Icons.volunteer_activism_rounded,
          items: _misSolicitudesAceptadas,
          builderTitulo: (s) {
            final solicitanteId = s['solicitante_id'] as String?;
            return solicitanteId != null
                ? (_nombresMisSolicitudes[solicitanteId] ?? 'Productor')
                : 'Productor';
          },
          permitirCancelar: false,
        ),
        const SizedBox(height: 20),
        _buildSeccionMisSolicitudes(
          titulo: 'Creadas por mí',
          vacio: 'No has creado solicitudes de ayuda todavía.',
          icon: Icons.campaign_rounded,
          items: _misSolicitudesCreadas,
          builderTitulo: (s) {
            final ayudanteId = s['ayudante_id'] as String?;
            if (ayudanteId == null || ayudanteId.isEmpty) {
              return 'Sin ayudante asignado';
            }
            return _nombresMisSolicitudes[ayudanteId] ?? 'Productor';
          },
          permitirCancelar: true,
        ),
      ],
    );
  }

  Widget _buildSeccionMisSolicitudes({
    required String titulo,
    required String vacio,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) builderTitulo,
    required bool permitirCancelar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _azulHorizonte,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: _azulHorizonte.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vacio,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CommunityCard(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: _azulHorizonte.withValues(alpha: 0.10),
                      child: Icon(icon, color: _azulHorizonte, size: 24),
                    ),
                    title: builderTitulo(s),
                    subtitle: _misSolicitudSubtitle(s),
                    onTap: () => _abrirChatMisSolicitud(s),
                  ),
                  if (permitirCancelar && _puedeCancelarSolicitudCreada(s))
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _cancelarSolicitudCreada(s),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancelar solicitud'),
                      ),
                    ),
                  if (permitirCancelar)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _eliminarSolicitudCreada(s),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Eliminar solicitud'),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _misSolicitudSubtitle(Map<String, dynamic> s) {
    final nItems = _asUuidList(s['item_ids']).length;
    final estado = s['estado'] as String? ?? '';
    final ayudanteId = s['ayudante_id'] as String?;
    final creada = DateTime.tryParse(s['created_at'] as String? ?? '');
    final fecha = creada != null
        ? '${creada.day.toString().padLeft(2, '0')}/${creada.month.toString().padLeft(2, '0')}/${creada.year}'
        : 'sin fecha';
    final chatDisponible = estado == 'cerrada' && ayudanteId != null;
    final estadoUi = chatDisponible ? 'Chat disponible' : 'Pendiente';
    return '$nItems producto${nItems != 1 ? 's' : ''} · $fecha · $estadoUi';
  }

  void _abrirChatMisSolicitud(Map<String, dynamic> s) {
    final solicitudId = s['id'] as String? ?? '';
    final estado = s['estado'] as String? ?? '';
    final ayudanteId = s['ayudante_id'] as String?;
    final chatDisponible = estado == 'cerrada' && ayudanteId != null;
    if (!chatDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta solicitud aún no tiene chat disponible.',
          ),
        ),
      );
      return;
    }
    context.push('/comercializacion/ayuda-chat/$solicitudId');
  }

  bool _puedeCancelarSolicitudCreada(Map<String, dynamic> s) {
    final estado = s['estado'] as String? ?? '';
    final ayudanteId = s['ayudante_id'] as String?;
    return estado == 'abierta' && (ayudanteId == null || ayudanteId.isEmpty);
  }

  Future<void> _cancelarSolicitudCreada(Map<String, dynamic> s) async {
    final solicitudId = s['id'] as String?;
    if (solicitudId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text(
          'Dejará de aparecer en Red comunitaria y otros productores no podrán aceptarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await _ayudaRepo.cancelarSolicitud(solicitudId);
      await _loadUbicacionYDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cancelar: $e')),
      );
    }
  }

  Future<void> _eliminarSolicitudCreada(Map<String, dynamic> s) async {
    final solicitudId = s['id'] as String?;
    if (solicitudId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar solicitud'),
        content: const Text(
          'Se eliminará de tu historial en esta app. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      final ok = await _ayudaRepo.eliminarSolicitud(solicitudId);
      await _loadUbicacionYDatos();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud eliminada.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo eliminar la solicitud. Si acabas de actualizar la app, '
              'aplica la migración 013 en Supabase o revisa tu conexión.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }
}

class _CampesinoCercano {
  _CampesinoCercano({
    required this.id,
    required this.nombre,
    required this.cantidadProductos,
    required this.distanciaKm,
  });

  final String id;
  final String nombre;
  final int cantidadProductos;
  final double distanciaKm;
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: _azulHorizonte, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _azulHorizonte
                : _azulHorizonte.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : _azulHorizonte.withValues(alpha: 0.7),
              fontSize: compact ? 11.5 : 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
