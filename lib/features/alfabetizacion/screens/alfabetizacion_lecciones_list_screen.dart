import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
const Color _crema = Color(0xFFFBF9F1);

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

class AlfabetizacionLeccionesListScreen extends StatefulWidget {
  const AlfabetizacionLeccionesListScreen({
    super.key,
    required this.modulo,
    required this.nivel,
  });

  final String modulo;
  final int nivel;

  @override
  State<AlfabetizacionLeccionesListScreen> createState() =>
      _AlfabetizacionLeccionesListScreenState();
}

class _AlfabetizacionLeccionesListScreenState
    extends State<AlfabetizacionLeccionesListScreen> {
  final _repo = AlfabetizacionRepository(Supabase.instance.client);
  Set<String> _completadas = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final ids = await _repo.getLeccionesCompletadasIds(uid, widget.modulo);
      if (mounted) {
        setState(() {
          _completadas = ids;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecciones = leccionesPorModuloNivel(widget.modulo, widget.nivel);
    final desbloqueado = nivelDesbloqueado(
      widget.modulo,
      widget.nivel,
      _completadas,
    );

    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !desbloqueado
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 124, 16, 24),
                        children: [
                          _InfoBox(
                            text:
                                'Este nivel aún está cerrado.\nCompleta todas las lecciones del nivel ${widget.nivel - 1} para abrirlo.',
                          ),
                          const SizedBox(height: 18),
                          Icon(
                            Icons.lock_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Este nivel aún está cerrado.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completa todas las lecciones del nivel ${widget.nivel - 1} para abrirlo.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => context.pop(),
                            child: const Text('Volver'),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarProgreso,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 124, 16, 24),
                          children: [
                            const _InfoBox(
                              text:
                                  'Las lecciones se abren una a una.\nCompleta cada una para desbloquear la siguiente.',
                            ),
                            const SizedBox(height: 14),
                            ...lecciones.asMap().entries.expand((e) {
                              final i = e.key;
                              final l = e.value;
                              final leccionAbierta =
                                  leccionDesbloqueada(l, _completadas);
                              final String subtitulo = leccionAbierta
                                  ? '+${l.puntos} puntos si aciertas'
                                  : 'Completa la anterior para desbloquear';
                              final icon = leccionAbierta
                                  ? (l.esLectura
                                      ? Icons.menu_book_rounded
                                      : Icons.edit_rounded)
                                  : Icons.lock_rounded;

                              return [
                                _TonalNavCard(
                                  icon: icon,
                                  title: l.titulo,
                                  subtitle: subtitulo,
                                  locked: !leccionAbierta,
                                  onTap: () async {
                                    if (!leccionAbierta) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            i > 0
                                                ? 'Primero aprueba la lección «${lecciones[i - 1].titulo}».'
                                                : 'Esta lección no está disponible aún.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    await context.push(
                                      '/alfabetizacion/leccion/${l.id}',
                                    );
                                    if (mounted) _cargarProgreso();
                                  },
                                ),
                                const SizedBox(height: 14),
                              ];
                            }),
                          ],
                        ),
                      ),
          ),
          // Header orgánico
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
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Elige tu lección',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nivel ${widget.nivel}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4463).withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF1A4463),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A4463),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TonalNavCard extends StatelessWidget {
  const _TonalNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.locked,
    required this.onTap,
  });

  static const Color _azul = Color(0xFF1A4463);

  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconBg = locked
        ? Colors.grey.withValues(alpha: 0.10)
        : const Color(0xFF1A4463).withOpacity(0.10);
    final iconFg = locked ? Colors.grey : const Color(0xFF1A4463);
    final chevronColor = locked ? Colors.grey : _azul;

    return Material(
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
        child: SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconFg, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: cs.onSurface,
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
                Icon(Icons.chevron_right, color: chevronColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
