import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/location_service.dart';
import '../../core/services/pending_notification_navigation.dart';
import '../../core/widgets/minimal_ui.dart';

const String _assetLogoApp = 'assets/alfabetizacion/images/logo_app.png';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    _controller.forward();
    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Esperar la animación del splash.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Pre-calcular el estado de ubicación (async) ANTES de señalar al router.
    // El redirect (síncrono) en app_router usará este valor cacheado.
    try {
      final locOk = await LocationService.instance.isReady();
      PendingNotificationNavigation.instance.locationReady = locOk;
    } catch (_) {
      PendingNotificationNavigation.instance.locationReady = false;
    }

    if (!mounted) return;

    // Salida por go (no refreshListenable): evita re-parse del Router concurrente → assert match.dart.
    // [ScheduleColdStartDeepLink] abre el deep link en frío con otro go cuando la base está lista.
    PendingNotificationNavigation.instance.markSplashDone();

    final session = Supabase.instance.client.auth.currentSession;
    final role = session?.user.userMetadata?['role'] as String?;
    final next = session == null
        ? '/login'
        : (role == 'comprador' ? '/comercializacion' : '/home');
    if (!mounted) return;
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: ClipOval(
                      child: Image.asset(
                        _assetLogoApp,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 72,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppPagePadding.sectionGap),
              Text(
                'Sembrapp',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
