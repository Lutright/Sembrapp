import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/location_service.dart';
import '../../core/widgets/minimal_ui.dart';

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.06,
        0,
        size.height * 0.8,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}


class LocationGateScreen extends StatefulWidget {
  const LocationGateScreen({super.key});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _continuar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Activa el GPS para continuar.';
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Permite ubicación en los ajustes para continuar.';
        });
        return;
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Permite ubicación para continuar.';
        });
        return;
      }

      final pos = await LocationService.instance.ensureReadyAndFetch();
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _loading = false;
          _error = 'Activa GPS y permite ubicación para continuar.';
        });
        return;
      }

      final role = Supabase.instance.client.auth.currentUser?.userMetadata?['role']
          as String?;
      // comprador → marketplace, campesino → home (como router)
      if (role == 'comprador') {
        context.go('/comercializacion');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo activar la ubicación.';
      });
    }
  }

  Future<void> _abrirAjustes() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'En web, activa la ubicación desde el icono de candado en la barra del navegador.',
          ),
        ),
      );
      return;
    }
    await Geolocator.openLocationSettings();
  }

  Future<void> _abrirAjustesPermisos() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'En web, permite ubicación en la configuración del sitio del navegador.',
          ),
        ),
      );
      return;
    }
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = (constraints.maxHeight * 0.25).clamp(190.0, 260.0);
          
          return Stack(
            children: [
              // 1. Contenido Scrolleable Principal superpuesto al fondo crema sólido
              Positioned.fill(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          // Header Ocre Superior Fijo en este bloque
                          ClipPath(
                            clipper: _OrganicHeaderClipper(),
                            child: Container(
                              height: headerHeight,
                              color: cs.tertiary,
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppPagePadding.screen.left,
                                16,
                                AppPagePadding.screen.right,
                                48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: headerHeight * 0.75,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer.withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: cs.shadow.withValues(alpha: 0.14),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.location_on_rounded,
                                              size: 54,
                                              color: cs.onTertiary,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Ubicación',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: cs.onTertiary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 64),
                                  Text(
                                    'Necesitamos tu ubicación para mostrar productos cercanos y ubicar publicaciones.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_error != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: cs.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _error!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: cs.onErrorContainer,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                                    decoration: BoxDecoration(
                                      color: cs.tertiary.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gps_fixed_rounded,
                                          size: 34,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            'Activa GPS y permite ubicación “Mientras usas la app”.',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  height: 1.3,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  FilledButton(
                                    onPressed: _loading ? null : _continuar,
                                    child: _loading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                        : const Text('Activar y continuar'),
                                  ),
                                  const SizedBox(height: 40),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _loading ? null : _abrirAjustes,
                                          icon: const Icon(Icons.settings_rounded),
                                          label: const Text('Ajustes de GPS'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: cs.primary,
                                            side: BorderSide(color: cs.primary, width: 1.0),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: _loading ? null : _abrirAjustesPermisos,
                                          icon: const Icon(Icons.security_rounded),
                                          label: const Text('Ajustes de permisos'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: cs.primary,
                                            side: BorderSide(color: cs.primary, width: 1.0),
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
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

