import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/tonalist_screen_header.dart';

class AlfabetizacionNivelesScreen extends StatefulWidget {
  const AlfabetizacionNivelesScreen({
    super.key,
    required this.modulo,
  });

  final String modulo;

  @override
  State<AlfabetizacionNivelesScreen> createState() =>
      _AlfabetizacionNivelesScreenState();
}

class _AlfabetizacionNivelesScreenState
    extends State<AlfabetizacionNivelesScreen> {
  final _repo = AlfabetizacionRepository(Supabase.instance.client);
  final _ttsCoach = AlfabetizacionTtsCoach();
  Set<String> _completadas = {};
  bool _loading = true;
  bool _ttsListo = false;
  bool _audioAutoYa = false;
  bool _narrando = false;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _ttsCoach.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _ttsCoach.isReady);
  }

  @override
  void dispose() {
    unawaited(_ttsCoach.dispose());
    super.dispose();
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
        _programarAudioAuto();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _programarAudioAuto() {
    if (!_ttsListo || _loading || _audioAutoYa) return;
    _audioAutoYa = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_narrarEntrada());
    });
  }

  Future<void> _narrarEntrada() async {
    if (!_ttsListo || _narrando) return;
    final tituloModulo =
        widget.modulo == 'lectura' ? 'Lectura' : 'Escritura';
    final niveles = nivelesDisponibles(widget.modulo);
    final nivelesAbiertos = niveles
        .where((n) => nivelDesbloqueado(widget.modulo, n, _completadas))
        .toList()
      ..sort();
    final siguienteNivel = nivelesAbiertos.isEmpty ? null : nivelesAbiertos.first;
    final ultimoAbierto = nivelesAbiertos.isEmpty ? null : nivelesAbiertos.last;
    setState(() => _narrando = true);
    try {
      await _ttsCoach.interrupt();
      final partes = <String>[
        'Estás en el módulo de $tituloModulo.',
        'Aquí eliges tu nivel.',
        'Hay ${niveles.length} niveles en total.',
        'Tienes ${nivelesAbiertos.length} niveles abiertos.',
        'Los niveles cerrados tienen un candado.',
      ];
      if (siguienteNivel != null) {
        if (ultimoAbierto != null && ultimoAbierto != siguienteNivel) {
          partes.add('Tienes niveles abiertos hasta el nivel $ultimoAbierto.');
        }
        if (siguienteNivel == 1) {
          partes.add('Si estás empezando, entra al nivel 1.');
        }
        partes.add('Tu siguiente nivel recomendado es el nivel $siguienteNivel.');
        partes.add('Pulsa nivel $siguienteNivel para ver sus lecciones.');
      } else {
        partes.add('Si no ves niveles abiertos, primero completa las lecciones anteriores.');
      }
      partes.add('Si necesitas ayuda, pulsa repetir.');
      await _ttsCoach.speakSequence(
        partes,
        shouldContinue: () =>
            mounted && alfabetizacionTtsRouteActive(context),
      );
    } finally {
      if (mounted) setState(() => _narrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final niveles = nivelesDisponibles(widget.modulo);
    final tituloModulo =
        widget.modulo == 'lectura' ? 'Lectura' : 'Escritura';

    _programarAudioAuto();

    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarProgreso,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        TonalistHeaderMetrics.contentTopPadding,
                        16,
                        24,
                      ),
                      children: [
                        _AudioCoachBar(
                          listo: _ttsListo,
                          narrando: _narrando,
                          onRepeat: () => unawaited(_narrarEntrada()),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A4463).withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF1A4463),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Las lecciones se abren una a una.\n'
                                  'Completa un nivel para desbloquear el siguiente.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A4463),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...niveles.expand((nivel) {
                          final lecciones =
                              leccionesPorModuloNivel(widget.modulo, nivel);
                          final total = lecciones.length;
                          final completadasEnNivel = lecciones
                              .where((l) => _completadas.contains(l.id))
                              .length;
                          final desbloqueado = nivelDesbloqueado(
                            widget.modulo,
                            nivel,
                            _completadas,
                          );
                          final IconData nivelIcon = switch (nivel) {
                            1 => Icons.looks_one_rounded,
                            2 => Icons.looks_two_rounded,
                            3 => Icons.looks_3_rounded,
                            _ => Icons.layers_rounded,
                          };
                          final subtitle = desbloqueado
                              ? '$completadasEnNivel de $total lecciones completadas'
                              : 'Termina el nivel ${nivel - 1} para abrir este';
                          return [
                            _TonalNavCard(
                              icon: desbloqueado ? nivelIcon : Icons.lock_rounded,
                              title: 'Nivel $nivel',
                              subtitle: subtitle,
                              completadasEnNivel: completadasEnNivel,
                              total: total,
                              locked: !desbloqueado,
                              onTap: () async {
                                if (!desbloqueado) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Primero completa todas las lecciones del nivel ${nivel - 1}.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await context.push(
                                  '/alfabetizacion/${widget.modulo}/nivel/$nivel',
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
          const TonalistHeaderBackground(
            height: TonalistHeaderMetrics.standardHeight,
          ),
          TonalistHeaderChrome(
            height: TonalistHeaderMetrics.standardHeight,
            title: 'Elige tu nivel',
            subtitle: 'Módulo de $tituloModulo',
            onBack: () => context.pop(),
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
    required this.completadasEnNivel,
    required this.total,
    required this.locked,
    required this.onTap,
  });

  static const Color _azul = Color(0xFF1A4463);

  final IconData icon;
  final String title;
  final String subtitle;
  final int completadasEnNivel;
  final int total;
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

    final progress = total <= 0 ? 0.0 : completadasEnNivel / total;
    final progressClamped = progress.clamp(0.0, 1.0);

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
                      if (!locked) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressClamped,
                          backgroundColor:
                              const Color(0xFF1A4463).withOpacity(0.10),
                          color: const Color(0xFF1A4463),
                          borderRadius: BorderRadius.circular(99),
                          minHeight: 5,
                        ),
                      ],
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

class _AudioCoachBar extends StatelessWidget {
  const _AudioCoachBar({
    required this.listo,
    required this.narrando,
    required this.onRepeat,
  });

  final bool listo;
  final bool narrando;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = !listo || narrando;
    return Container(
      decoration: BoxDecoration(
        color: TonalistColors.azulHorizonte.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.headphones_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              listo ? 'Guía por voz: pulsa para repetir' : 'Preparando audio…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: disabled ? null : onRepeat,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Repetir'),
          ),
        ],
      ),
    );
  }
}
