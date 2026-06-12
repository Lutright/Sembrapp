import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/pending_notification_navigation.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../../../core/widgets/tonalist_gradient_button.dart';

/// Rutas de assets
const String _assetFondoCampo = 'assets/alfabetizacion/images/fondo_campo.jpg';
const String _assetLogoApp = 'assets/alfabetizacion/images/logo_app.png';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static String _mensajeLoginEspanol(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid credentials') ||
        m.contains('email or password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirma tu correo antes de entrar.';
    }
    if (m.contains('user not found')) {
      return 'No hay cuenta con ese correo.';
    }
    return e.message;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        final pending =
            PendingNotificationNavigation.instance.peekPendingDeepLink;
        if (pending != null) {
          PendingNotificationNavigation.instance.consumePendingDeepLink();
          // Un frame después del sign-in evita carrera con el parseo del Router (match.dart).
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(pending);
          });
        } else {
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _mensajeLoginEspanol(e);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo entrar. Revisa tu conexión.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? cs.surface;
    final media = MediaQuery.of(context);
    final logoSize = (media.size.width * 0.4).clamp(150.0, 210.0);
    final formMaxWidth = media.size.width > 520 ? 520.0 : media.size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _assetFondoCampo,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: cs.primaryContainer,
                child: Icon(
                  Icons.landscape_rounded,
                  size: 64,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: cs.scrim.withValues(alpha: 0.4),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formMaxWidth),
                  child: Material(
                    color: cardColor,
                    elevation: 14,
                    shadowColor: cs.shadow.withValues(alpha: 0.4),
                    surfaceTintColor: cs.surface.withValues(alpha: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: ClipOval(
                                child: Image.asset(
                                  _assetLogoApp,
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.eco_rounded,
                                    size: 72,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Sembrapp',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Entra con tu correo y contraseña',
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                            ),
                            const SizedBox(height: 34),
                            if (_error != null) ...[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _error!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: cs.onErrorContainer,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Correo',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Escribe tu correo';
                                }
                                if (!v.contains('@')) return 'Correo no válido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              decoration: const InputDecoration(
                                hintText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Escribe tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.primary,
                                  minimumSize: const Size(
                                    kMinimalTouchTarget,
                                    kMinimalTouchTarget,
                                  ),
                                ),
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: const Text('¿Olvidaste la contraseña?'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TonalistGradientButton(
                              label: 'Entrar',
                              loading: _loading,
                              onPressed: _loading ? null : _signIn,
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes cuenta? ',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: cs.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(
                                      kMinimalTouchTarget,
                                      kMinimalTouchTarget,
                                    ),
                                  ),
                                  onPressed: () => context.push('/register'),
                                  child: Text(
                                    'Registrarse',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
