import 'package:flutter/material.dart';

/// Espaciado único para pantallas: pocas decisiones, más claridad.
abstract final class AppPagePadding {
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const double sectionGap = 20;
  static const double tileGap = 12;
}

/// Área mínima recomendada para toques (accesibilidad).
const double kMinimalTouchTarget = 48;

/// Botón atrás grande y claro.
class MinimalBackButton extends StatelessWidget {
  const MinimalBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 28),
      style: IconButton.styleFrom(
        minimumSize: const Size(kMinimalTouchTarget, kMinimalTouchTarget),
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}

/// Tarjeta de menú: icono grande + título corto + una línea opcional.
/// Prioriza reconocimiento visual sobre texto largo.
class BigNavTile extends StatelessWidget {
  const BigNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primaryContainer.withOpacity(0.35);
    final fg = iconColor ?? cs.primary;

    return Material(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: fg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.outline, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado opcional: una sola frase corta bajo el título de la pantalla.
class MinimalScreenHint extends StatelessWidget {
  const MinimalScreenHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPagePadding.sectionGap),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
      ),
    );
  }
}
