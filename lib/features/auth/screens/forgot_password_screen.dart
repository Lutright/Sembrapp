import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../../../core/widgets/tonalist_gradient_button.dart';
import '../../../core/widgets/tonalist_screen_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sent = true;
          _loading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo enviar el mensaje.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.25;
          return Stack(
            children: [
              TonalistHeaderWave(height: headerHeight),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppPagePadding.screen.left,
                    16,
                    AppPagePadding.screen.right,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 56),
                                  Expanded(
                                    child: Text(
                                      'Recuperar contraseña',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 56),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: Icon(Icons.arrow_back_rounded, color: cs.onPrimary),
                                style: IconButton.styleFrom(
                                  backgroundColor: cs.onPrimary.withValues(alpha: 0.14),
                                  minimumSize: const Size(48, 48),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sent ? _buildSuccess(context) : _buildForm(context, cs),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Revisa tu correo',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Si hay una cuenta con ${_emailController.text.trim()}, '
          'te llegará un enlace para crear una contraseña nueva.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        TonalistGradientButton(
          label: 'Volver a entrar',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, ColorScheme cs) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Hero(
              tag: 'auth-lock-reset-icon',
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4463).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: Color(0xFF1A4463),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No te preocupes, a todos nos pasa. Escribe tu correo abajo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  hintText: 'tu@correo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
                  if (!v.contains('@')) return 'Correo no válido';
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          TonalistGradientButton(
            label: 'Enviar enlace',
            loading: _loading,
            onPressed: _loading ? null : _sendResetLink,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Recordaste la clave de repente? ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
