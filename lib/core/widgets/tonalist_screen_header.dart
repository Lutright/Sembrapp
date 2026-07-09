import 'package:flutter/material.dart';

import '../theme/tonalist_colors.dart';
import 'organic_header_clipper.dart';

/// Alturas y paddings estándar del header Tonalist.
abstract final class TonalistHeaderMetrics {
  static const double standardHeight = 120;
  static const double lessonHeight = 124;
  static const double homeHeight = 210;
  static const double profileHeight = 200;
  static const double marketplaceHeight = 250;
  static const double ordenesWaveHeight = 160;
  static const double contentTopPadding = 124;
  /// Ola de Mis pedidos + curva orgánica (~106% de [ordenesWaveHeight]).
  static const double ordenesContentTopPadding = 178;
  static const double lessonContentTopPadding = 128;
  static const double homeContentTopPadding = 220;
}

/// Ola orgánica con degradado (uso en Column, Stack sin Positioned, etc.).
class TonalistHeaderWave extends StatelessWidget {
  const TonalistHeaderWave({
    super.key,
    required this.height,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const OrganicHeaderClipper(),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: const DecoratedBox(
          decoration: BoxDecoration(gradient: TonalistColors.headerGradient),
        ),
      ),
    );
  }
}

/// Fondo del header fijo superior (ola + degradado).
class TonalistHeaderBackground extends StatelessWidget {
  const TonalistHeaderBackground({
    super.key,
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: TonalistHeaderWave(height: height),
    );
  }
}

/// Controles del header: atrás, título, subtítulo y acción derecha.
class TonalistHeaderChrome extends StatelessWidget {
  const TonalistHeaderChrome({
    super.key,
    required this.height,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.useCloseButton = false,
    this.subtitleAsPill = false,
    this.titleHorizontalPadding = 56,
  });

  final double height;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool useCloseButton;
  final bool subtitleAsPill;
  final double titleHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 4,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    useCloseButton
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed:
                      onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: titleHorizontalPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            height: 1.2,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      if (subtitleAsPill)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        )
                      else
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (trailing != null)
              Positioned(
                right: 4,
                top: 4,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Scaffold con fondo crema y header orgánico con degradado.
class TonalistScreenScaffold extends StatelessWidget {
  const TonalistScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.headerHeight = TonalistHeaderMetrics.standardHeight,
    this.backgroundColor = TonalistColors.crema,
    this.onBack,
    this.trailing,
    this.useCloseButton = false,
    this.subtitleAsPill = false,
    this.resizeToAvoidBottomInset,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final double headerHeight;
  final Color backgroundColor;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool useCloseButton;
  final bool subtitleAsPill;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          TonalistHeaderBackground(height: headerHeight),
          TonalistHeaderChrome(
            height: headerHeight,
            title: title,
            subtitle: subtitle,
            onBack: onBack,
            trailing: trailing,
            useCloseButton: useCloseButton,
            subtitleAsPill: subtitleAsPill,
          ),
        ],
      ),
    );
  }
}
