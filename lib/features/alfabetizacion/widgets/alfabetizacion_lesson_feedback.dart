import 'package:flutter/material.dart';

import '../alfabetizacion_ui_colors.dart';
import 'alfabetizacion_lesson_shell.dart';

/// Retroalimentación breve al acertar (reemplaza el “rebote” elástico anterior).
class AlfabetizacionLessonCorrectBanner extends StatelessWidget {
  const AlfabetizacionLessonCorrectBanner({
    super.key,
    required this.animationTick,
  });

  /// Incrementar en cada acierto para repetir la animación.
  final int animationTick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(animationTick),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final ease = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * ease,
              child: Transform.rotate(
                angle: (1 - t) * 0.12,
                child: child,
              ),
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.2),
              scheme.tertiary.withValues(alpha: 0.14),
            ],
          ),
          border: Border.all(
            color: AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: AlfabetizacionLessonTokens.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 36,
                  color: AlfabetizacionUiColors.verdeContinuar,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Correcto!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AlfabetizacionLessonTokens.headerMid,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buen trabajo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla final al terminar una lección guiada.
class AlfabetizacionLessonCompletionPanel extends StatelessWidget {
  const AlfabetizacionLessonCompletionPanel({
    super.key,
    required this.headline,
    required this.detail,
    required this.pointsLabel,
    this.hint = 'Tu avance queda guardado en el módulo.',
  });

  final String headline;
  final String detail;
  final String pointsLabel;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlfabetizacionLessonSurface(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.35),
                  AlfabetizacionLessonTokens.headerLight.withValues(alpha: 0.45),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AlfabetizacionLessonTokens.headerMid.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AlfabetizacionLessonTokens.headerMid,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AlfabetizacionUiColors.verdeContinuar.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              pointsLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AlfabetizacionLessonTokens.headerMid,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                size: 18,
                color: scheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
