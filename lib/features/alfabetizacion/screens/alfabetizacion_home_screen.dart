import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/alfabetizacion_tts_coach.dart';

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

class AlfabetizacionHomeScreen extends StatefulWidget {
  const AlfabetizacionHomeScreen({super.key});

  @override
  State<AlfabetizacionHomeScreen> createState() => _AlfabetizacionHomeScreenState();
}

class _AlfabetizacionHomeScreenState extends State<AlfabetizacionHomeScreen> {
  final _ttsCoach = AlfabetizacionTtsCoach();
  bool _ttsListo = false;
  bool _audioAutoYa = false;
  bool _narrando = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _ttsCoach.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _ttsCoach.isReady);
    if (_ttsListo && !_audioAutoYa) {
      _audioAutoYa = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_narrarEntrada());
      });
    }
  }

  @override
  void dispose() {
    unawaited(_ttsCoach.dispose());
    super.dispose();
  }

  Future<void> _narrarEntrada({bool forzar = false}) async {
    if (!_ttsListo || _narrando) return;
    setState(() => _narrando = true);
    try {
      await _ttsCoach.interrupt();
      await _ttsCoach.speakSequence(const [
        'Bienvenido al módulo de alfabetización.',
        'Aquí te voy a guiar con la voz, paso a paso.',
        'Si quieres volver a escuchar, pulsa el botón repetir que está arriba.',
        'Primero elige una opción.',
        'Pulsa lectura para aprender letras, sílabas y palabras.',
        'Pulsa escritura para practicar escribir letras y palabras.',
      ]);
    } finally {
      if (mounted) setState(() => _narrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 124, 16, 20),
              children: [
                _AudioCoachBar(
                  listo: _ttsListo,
                  narrando: _narrando,
                  onRepeat: () => unawaited(_narrarEntrada(forzar: true)),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 12),
                  child: Text(
                    'Elige si quieres practicar leer o escribir.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.80),
                        ),
                  ),
                ),
                _HeroLearnCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Lectura',
                  subtitle: 'Letras, sílabas y palabras',
                  buttonLabel: 'Ir a lectura',
                  onTap: () async {
                    await _ttsCoach.interrupt();
                    if (!context.mounted) return;
                    await context.push('/alfabetizacion/lectura');
                  },
                ),
                const SizedBox(height: 12),
                _HeroLearnCard(
                  icon: Icons.edit_rounded,
                  title: 'Escritura',
                  subtitle: 'Escribir letras y palabras',
                  buttonLabel: 'Ir a escritura',
                  onTap: () async {
                    await _ttsCoach.interrupt();
                    if (!context.mounted) return;
                    await context.push('/alfabetizacion/escritura');
                  },
                ),
              ],
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
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Aprender',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fondo crema detrás de header (por si el theme cambia)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1,
            child: ColoredBox(color: cs.surface),
          ),
        ],
      ),
    );
  }
}

class _HeroLearnCard extends StatelessWidget {
  const _HeroLearnCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  static const Color _azul = Color(0xFF1A4463);

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            height: 130,
            decoration: BoxDecoration(
              color: _azul.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 52,
                color: _azul,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _azul,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(buttonLabel),
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
        color: _azulHorizonte.withValues(alpha: 0.06),
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
