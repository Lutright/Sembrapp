import 'package:flutter/material.dart';

import '../theme/tonalist_colors.dart';

/// Rol visual del botón con degradado (no depende solo del color base).
enum TonalistGradientKind {
  /// Navegación principal: hero Home, tarjetas de módulo (Aprender…).
  brandBlue,

  /// Acción principal de pantalla: guardar, comprar, entrar, añadir…
  actionRed,
}

/// Botón cápsula con degradado Tonalist para CTAs principales.
///
/// Usar en acciones hero o CTA dominante de pantalla.
/// Secundarios, diálogos y acciones repetidas en listas → plano/outlined.
class TonalistGradientButton extends StatelessWidget {
  const TonalistGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = TonalistGradientKind.actionRed,
    this.icon,
    this.loading = false,
    this.minimumHeight = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final TonalistGradientKind kind;
  final IconData? icon;
  final bool loading;
  final double minimumHeight;

  bool get _disabled => onPressed == null || loading;

  LinearGradient get _gradient => switch (kind) {
        TonalistGradientKind.brandBlue => TonalistColors.headerGradient,
        TonalistGradientKind.actionRed => TonalistColors.ctaRedGradient,
      };

  Color get _disabledColor => switch (kind) {
        TonalistGradientKind.brandBlue =>
          TonalistColors.azulHorizonte.withValues(alpha: 0.45),
        TonalistGradientKind.actionRed =>
          TonalistColors.rojoManta.withValues(alpha: 0.45),
      };

  Color get _shadowColor => switch (kind) {
        TonalistGradientKind.brandBlue => TonalistColors.azulHorizonte,
        TonalistGradientKind.actionRed => TonalistColors.rojoManta,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minimumHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _disabled ? null : _gradient,
          color: _disabled ? _disabledColor : null,
          borderRadius: BorderRadius.circular(minimumHeight / 2),
          boxShadow: _disabled
              ? null
              : [
                  BoxShadow(
                    color: _shadowColor.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(minimumHeight / 2),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
