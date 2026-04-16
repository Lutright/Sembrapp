import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.1,
        0,
        size.height * 0.7,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OrderStatusPill extends StatelessWidget {
  final String estado;
  const _OrderStatusPill({required this.estado});

  @override
  Widget build(BuildContext context) {
    final e = estado.toLowerCase().trim();
    Color bg;
    Color fg;

    // Fallback por defecto
    bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    fg = Theme.of(context).colorScheme.onSurfaceVariant;

    if (e == 'pendiente' || e == 'creada') {
      bg = const Color(0xFFFFF3CD);
      fg = const Color(0xFF856404);
    } else if (e == 'confirmado' ||
        e == 'confirmada' ||
        e == 'aceptado' ||
        e == 'aceptada' ||
        e == 'ac') {
      bg = const Color(0xFFD4EDDA);
      fg = const Color(0xFF155724);
    } else if (e == 'cancelada' || e == 'cancelado') {
      bg = Theme.of(context).colorScheme.errorContainer;
      fg = Theme.of(context).colorScheme.onErrorContainer;
    } else if (e == 'en camino' ||
        e == 'en_camino' ||
        e == 'preparando' ||
        e == 'enviada') {
      bg = Theme.of(context).colorScheme.primaryContainer;
      fg = Theme.of(context).colorScheme.onPrimaryContainer;
    } else if (e == 'entregado' || e == 'entregada' || e == 'completada') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: ShapeDecoration(
        color: bg,
        shape: const StadiumBorder(),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ComercializacionOrdenesScreen extends StatefulWidget {
  const ComercializacionOrdenesScreen({super.key});

  @override
  State<ComercializacionOrdenesScreen> createState() =>
      _ComercializacionOrdenesScreenState();
}

class _ComercializacionOrdenesScreenState
    extends State<ComercializacionOrdenesScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  Map<String, String> _nombresProductorPorId = {};
  Map<String, String> _nombresCompradorPorId = {};
  bool _loading = true;
  RealtimeChannel? _ordenesChannel;
  RealtimeChannel? _ordenesCompradorChannel;
  RealtimeChannel? _ordenesCampesinoChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _suscribirRealtimeOrdenes();
  }

  @override
  void dispose() {
    if (_ordenesChannel != null) {
      Supabase.instance.client.removeChannel(_ordenesChannel!);
    }
    if (_ordenesCompradorChannel != null) {
      Supabase.instance.client.removeChannel(_ordenesCompradorChannel!);
    }
    if (_ordenesCampesinoChannel != null) {
      Supabase.instance.client.removeChannel(_ordenesCampesinoChannel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('ordenes')
          .select('*, orden_items(cantidad, precio_unitario)')
          .or('comprador_id.eq.$uid,campesino_id.eq.$uid')
          .order('created_at', ascending: false);
      final ordenes = List<Map<String, dynamic>>.from(res as List);
      final idsProductor = ordenes
          .map((o) => o['campesino_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final idsComprador = ordenes
          .map((o) => o['comprador_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final nombresProductor = await _cargarNombresPerfiles(idsProductor);
      final nombresComprador = await _cargarNombresPerfiles(idsComprador);
      if (mounted) {
        setState(() {
          _ordenes = ordenes;
          _nombresProductorPorId = nombresProductor;
          _nombresCompradorPorId = nombresComprador;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, String>> _cargarNombresPerfiles(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', ids);
      final out = <String, String>{};
      for (final row in res as List) {
        final m = row as Map<String, dynamic>;
        final id = m['id'] as String?;
        final fullName = m['full_name'] as String?;
        if (id != null && fullName != null && fullName.trim().isNotEmpty) {
          out[id] = fullName.trim();
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  String _inicialesDe(String nombre) {
    final parts = nombre
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _suscribirRealtimeOrdenes() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _ordenesChannel = Supabase.instance.client
        .channel('mis_ordenes_items_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orden_items',
          callback: (_) {
            if (mounted) _load();
          },
        )
        .subscribe();

    _ordenesCompradorChannel = Supabase.instance.client
        .channel('mis_ordenes_comprador_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordenes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'comprador_id',
            value: uid,
          ),
          callback: (_) {
            if (mounted) _load();
          },
        )
        .subscribe();

    _ordenesCampesinoChannel = Supabase.instance.client
        .channel('mis_ordenes_campesino_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordenes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'campesino_id',
            value: uid,
          ),
          callback: (_) {
            if (mounted) _load();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // 1. Capa Inferior: El scroll donde habitan las tarjetas de órdenes
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 180, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4463).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF1A4463),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aquí están tus compras con cada productor. Toca un pedido para ver detalles y coordinar la entrega por chat.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xD91A4463),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_ordenes.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: AppPagePadding.screen,
                        child: Text(
                          'Aún no tienes pedidos.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontFamily: 'Montserrat',
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final o = _ordenes[i];
                          final id = o['id'] as String? ?? '';
                          final estado = o['estado'] as String? ?? 'Pendiente';
                          final uid = Supabase.instance.client.auth.currentUser?.id;
                          final productorId = o['campesino_id'] as String?;
                          final compradorId = o['comprador_id'] as String?;
                          final esVistaProductor =
                              uid != null && productorId != null && uid == productorId;

                          // Manejo de variables con default premium y cálculo dinámico de items
                          double? totalDouble;
                          final t = o['total'];
                          if (t is num)
                            totalDouble = t.toDouble();
                          else if (t is String)
                            totalDouble = double.tryParse(t);
                          else if (o['orden_items'] is List) {
                            double s = 0.0;
                            for (final item in o['orden_items'] as List) {
                              if (item is Map) {
                                final c =
                                    (item['cantidad'] as num?)?.toDouble() ?? 0;
                                final p = (item['precio_unitario'] as num?)
                                        ?.toDouble() ??
                                    0;
                                s += c * p;
                              }
                            }
                            if (s > 0) totalDouble = s;
                          }
                          final totalStr = totalDouble != null
                              ? '\$${totalDouble.toStringAsFixed(0)}'
                              : '\$ --';

                          final rawNombreProductor = o['tienda_nombre']?.toString() ??
                              o['productor_nombre']?.toString() ??
                              o['vendedor_nombre']?.toString() ??
                              (productorId != null
                                  ? _nombresProductorPorId[productorId]
                                  : null);
                          final rawNombreComprador = o['comprador_nombre']?.toString() ??
                              o['buyer_name']?.toString() ??
                              o['cliente_nombre']?.toString() ??
                              o['nombre_comprador']?.toString() ??
                              (compradorId != null
                                  ? _nombresCompradorPorId[compradorId]
                                  : null);
                          final fallbackNombre = esVistaProductor
                              ? (compradorId != null && compradorId.length >= 4
                                  ? 'Comprador ${compradorId.substring(compradorId.length - 4)}'
                                  : 'Comprador')
                              : (productorId != null && productorId.length >= 4
                                  ? 'Productor ${productorId.substring(productorId.length - 4)}'
                                  : 'Productor');
                          final rawNombre =
                              esVistaProductor ? rawNombreComprador : rawNombreProductor;
                          final tituloTarjeta =
                              (rawNombre != null && rawNombre.trim().isNotEmpty)
                                  ? rawNombre.trim()
                                  : fallbackNombre;

                          final shortId =
                              id.length >= 8 ? id.substring(0, 8) : id;

                          final createdAt = o['created_at'] as String?;
                          String dateStr = '';
                          if (createdAt != null) {
                            try {
                              final dt = DateTime.parse(createdAt).toLocal();
                              const meses = [
                                'Ene',
                                'Feb',
                                'Mar',
                                'Abr',
                                'May',
                                'Jun',
                                'Jul',
                                'Ago',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dic'
                              ];
                              dateStr =
                                  '${dt.day} ${meses[dt.month - 1]}, ${dt.year}';
                            } catch (_) {}
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withValues(alpha: 0.12),
                                    blurRadius: 12, // Sombra flotada premium
                                    spreadRadius: 1.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => context
                                      .push('/comercializacion/orden/$id'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: const Color(0xFF1A4463),
                                          child: Text(
                                            _inicialesDe(tituloTarjeta),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      tituloTarjeta,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontFamily:
                                                                'Montserrat',
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(
                                                      totalStr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontFamily:
                                                                'Montserrat',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: const Color(0xFF1A4463),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text('Pedido #$shortId',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          fontFamily:
                                                              'Montserrat',
                                                          color: cs
                                                              .onSurfaceVariant)),
                                              if (dateStr.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2.0),
                                                  child: Text(dateStr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                              fontFamily:
                                                                  'Montserrat',
                                                              color: cs
                                                                  .onSurfaceVariant)),
                                                ),
                                              const SizedBox(height: 12),
                                              _OrderStatusPill(estado: estado),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right_rounded,
                                            size: 32,
                                            color: cs.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _ordenes.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Capa Media: La Ola Mágica. Cubre el contenido debajo al scrollear
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 160, // Altura de la Ola reducida en un ~27%
            child: IgnorePointer(
              ignoring:
                  true, // Importante: la ola no debe bloquear toques de la lista en huecos vacíos
              child: ClipPath(
                clipper: _OrganicHeaderClipper(),
                child: Container(color: cs.primary),
              ),
            ),
          ),

          // 3. Capa Superior Fija: Botonería de Control que no se tapa con la ola
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 160,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: cs.onPrimary, size: 28),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/comercializacion');
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: Text(
                      'Mis pedidos',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
