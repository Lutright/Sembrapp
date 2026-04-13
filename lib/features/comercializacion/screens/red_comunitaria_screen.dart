import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../navigation/tienda_campesino_extra.dart';
import '../repositories/orden_ayuda_repository.dart';
import '../repositories/productos_repository.dart';

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
    _init();
    _suscribirRealtime();
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
      showDragHandle: true,
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
              Text(
                'Pedido de ayuda',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                nombreSol != null
                    ? '$nombreSol necesita apoyo con parte de un pedido.'
                    : 'Un productor necesita apoyo con parte de un pedido.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              if (nota != null && nota.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Nota:', style: Theme.of(ctx).textTheme.titleSmall),
                Text(nota),
              ],
              const SizedBox(height: 12),
              Text(
                'Productos en los que pide ayuda',
                style: Theme.of(ctx).textTheme.titleSmall,
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(nombre),
                            subtitle: Text(
                              '${cant.toStringAsFixed(cant == cant.roundToDouble() ? 0 : 1)} $u',
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
      appBar: AppBar(
        title: const Text('Red comunitaria'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Productores', icon: Icon(Icons.groups_rounded)),
            Tab(text: 'Ayuda', icon: Icon(Icons.volunteer_activism_rounded)),
            Tab(text: 'Mis solicitudes', icon: Icon(Icons.forum_rounded)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                  onChanged: (v) =>
                      setState(() => _selectedDistanceKm = v.round()),
                  onChangeEnd: _onDistanceChangedEnd,
                ),
              ],
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
    return ListView.separated(
      padding: AppPagePadding.screen,
      itemCount: _campesinos.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppPagePadding.tileGap),
      itemBuilder: (context, i) {
        final c = _campesinos[i];
        return BigNavTile(
          icon: Icons.agriculture_rounded,
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
      padding: AppPagePadding.screen,
      itemCount: _solicitudesFiltradas.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppPagePadding.tileGap),
      itemBuilder: (context, i) {
        final s = _solicitudesFiltradas[i];
        final sid = s['solicitante_id'] as String?;
        final nombre = sid != null ? _nombresSolicitantes[sid] : null;
        final d = (s['_dist_km'] as double?) ?? 0;
        final nItems = _asUuidList(s['item_ids']).length;
        return BigNavTile(
          icon: Icons.handshake_rounded,
          title: nombre ?? 'Productor',
          subtitle:
              '$nItems producto${nItems != 1 ? 's' : ''} · ${d.toStringAsFixed(1)} km · '
              'Toca para ver o aceptar',
          onTap: () => _mostrarDetalleSolicitud(s),
        );
      },
    );
  }

  Widget _emptyState(String message, {bool showRefresh = false}) {
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
      padding: AppPagePadding.screen,
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
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            vacio,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...items.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppPagePadding.tileGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BigNavTile(
                    icon: icon,
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
