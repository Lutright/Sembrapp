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
      bg = Theme.of(context).colorScheme.tertiaryContainer;
      fg = Theme.of(context).colorScheme.onTertiaryContainer;
    } else if (e == 'en camino' || e == 'en_camino' || e == 'preparando' || e == 'enviada') {
      bg = Theme.of(context).colorScheme.secondaryContainer;
      fg = Theme.of(context).colorScheme.onSecondaryContainer;
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) {
        setState(() {
        _ordenes = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                    padding: const EdgeInsets.only(top: 180, bottom: 20),
                    child: Text(
                      'Revisa el estado de tus compras de campo.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Montserrat',
                        color: Colors.black54,
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          
                          // Manejo de variables con default premium y cálculo dinámico de items
                          double? totalDouble;
                          final t = o['total'];
                          if (t is num) totalDouble = t.toDouble();
                          else if (t is String) totalDouble = double.tryParse(t);
                          else if (o['orden_items'] is List) {
                            double s = 0.0;
                            for (final item in o['orden_items'] as List) {
                              if (item is Map) {
                                final c = (item['cantidad'] as num?)?.toDouble() ?? 0;
                                final p = (item['precio_unitario'] as num?)?.toDouble() ?? 0;
                                s += c * p;
                              }
                            }
                            if (s > 0) totalDouble = s;
                          }
                          final totalStr = totalDouble != null ? '\$${totalDouble.toStringAsFixed(0)}' : '\$ --';
                          
                          final rawTienda = o['tienda_nombre']?.toString() ?? o['productor_nombre']?.toString();
                          final tiendaNombre = (rawTienda != null && rawTienda.trim().isNotEmpty)
                              ? 'Compra a $rawTienda'
                              : 'Compra Sembrapp';
                          
                          final shortId = id.length >= 8 ? id.substring(0, 8) : id;
                          
                          final createdAt = o['created_at'] as String?;
                          String dateStr = '';
                          if (createdAt != null) {
                            try {
                              final dt = DateTime.parse(createdAt).toLocal();
                              const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                              dateStr = '${dt.day} ${meses[dt.month - 1]}, ${dt.year}';
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
                                onTap: () => context.push('/comercializacion/orden/$id'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: cs.tertiaryContainer,
                                        child: Icon(Icons.shopping_bag_outlined, 
                                          color: cs.onTertiaryContainer, size: 26),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tiendaNombre,
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontFamily: 'Montserrat',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8.0),
                                                    child: Text(
                                                      totalStr,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontFamily: 'Montserrat',
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade700, // Verde Premium
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Pedido #$shortId', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontFamily: 'Montserrat',
                                              color: cs.onSurfaceVariant
                                            )),
                                            if (dateStr.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0),
                                                child: Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontFamily: 'Montserrat',
                                                  color: cs.onSurfaceVariant
                                                )),
                                              ),
                                            const SizedBox(height: 12),
                                            _OrderStatusPill(estado: estado),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right_rounded, size: 32, color: cs.onSurfaceVariant),
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
              ignoring: true, // Importante: la ola no debe bloquear toques de la lista en huecos vacíos
              child: ClipPath(
                clipper: _OrganicHeaderClipper(),
                child: Container(color: cs.secondary),
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
                        icon: Icon(Icons.arrow_back_rounded, color: cs.onSecondary, size: 28),
                        onPressed: () => context.pop(),
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
