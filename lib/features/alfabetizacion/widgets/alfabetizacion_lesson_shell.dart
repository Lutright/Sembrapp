import 'package:flutter/material.dart';

import '../../../core/widgets/tonalist_screen_header.dart';
import '../alfabetizacion_ui_colors.dart';

/// Paleta y sombras compartidas para pantallas de lección (alfabetización).
abstract final class AlfabetizacionLessonTokens {
  static const Color accentBlue = Color(0xFF1A4463);
  static const Color fondoArriba = Color(0xFFE8E4DB);
  static const Color fondoAbajo = Color(0xFFF7F4EC);
  static const Color headerDeep = Color(0xFF0E3248);
  static const Color headerMid = Color(0xFF1A4463);
  static const Color headerLight = Color(0xFF2A6B7C);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Marco común: fondo cálido, cabecera con gradiente, tarjeta de progreso y cuerpo.
class AlfabetizacionLessonShell extends StatelessWidget {
  const AlfabetizacionLessonShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.stepLabel,
    required this.child,
    this.useCloseButton = false,
    this.centerChild = false,
    /// Si es true, el cuerpo ocupa el espacio restante (p. ej. trazos con [Expanded]).
    /// Si es false, el contenido va en un [SingleChildScrollView].
    this.expandBody = false,
    this.resizeForKeyboard = false,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String stepLabel;
  final Widget child;
  final bool useCloseButton;
  final bool centerChild;
  final bool expandBody;
  final bool resizeForKeyboard;

  static const double _headerH = TonalistHeaderMetrics.lessonHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AlfabetizacionLessonTokens.fondoAbajo,
      resizeToAvoidBottomInset: resizeForKeyboard,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AlfabetizacionLessonTokens.fondoArriba,
                    AlfabetizacionLessonTokens.fondoAbajo,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: _headerH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _ProgressCard(
                        progress: progress,
                        stepLabel: stepLabel,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildBodyRegion(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TonalistHeaderBackground(height: _headerH),
          TonalistHeaderChrome(
            height: _headerH,
            title: title,
            subtitle: subtitle,
            useCloseButton: useCloseButton,
            subtitleAsPill: true,
          ),
        ],
      ),
    );
  }

  static const EdgeInsets _padBody = EdgeInsets.fromLTRB(20, 16, 20, 28);

  Widget _buildBodyRegion() {
    if (expandBody) {
      return Padding(
        padding: _padBody,
        child: child,
      );
    }
    if (centerChild) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(child: child),
      );
    }
    return SingleChildScrollView(
      padding: _padBody,
      child: child,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.stepLabel,
    required this.scheme,
  });

  final double progress;
  final String stepLabel;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: AlfabetizacionLessonTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
              color: AlfabetizacionUiColors.verdeContinuar,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stepLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AlfabetizacionLessonTokens.accentBlue,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de contenido blanca con borde suave (pregunta, bloque principal).
class AlfabetizacionLessonSurface extends StatelessWidget {
  const AlfabetizacionLessonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AlfabetizacionLessonTokens.cardShadow,
      ),
      child: child,
    );
  }
}
