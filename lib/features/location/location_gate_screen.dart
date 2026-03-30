import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/location_service.dart';
import '../../core/widgets/minimal_ui.dart';

class LocationGateScreen extends StatefulWidget {
  const LocationGateScreen({super.key});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen> {
  bool _loading = false;
  String? _error;
  bool _needsPermissionSettings = false;
  bool _needsGpsSettings = false;

  Future<void> _continuar() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsPermissionSettings = false;
      _needsGpsSettings = false;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Activa el GPS para continuar.';
          _needsGpsSettings = true;
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
          _needsPermissionSettings = true;
        });
        return;
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Permite ubicación para continuar.';
          _needsPermissionSettings = true;
        });
        return;
      }

      final pos = await LocationService.instance.ensureReadyAndFetch();
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _loading = false;
          _error = 'Activa GPS y permite ubicación para continuar.';
          _needsGpsSettings = true;
          _needsPermissionSettings = true;
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
      appBar: AppBar(
        title: const Text('Ubicación'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: AppPagePadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MinimalScreenHint(
              'Necesitamos tu ubicación para mostrar productos cercanos y ubicar publicaciones.',
            ),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 16, color: cs.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 30,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Activa GPS y permite ubicación “Mientras usas la app”.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _abrirAjustes,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Ajustes de GPS'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _abrirAjustesPermisos,
              icon: const Icon(Icons.security_rounded),
              label: const Text('Ajustes de permisos'),
            ),
          ],
        ),
      ),
    );
  }
}

