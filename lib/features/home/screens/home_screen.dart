import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/schedule_cold_start_deep_link.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
const Color _rojoManta = Color(0xFFD34836);
const Color _crema = Color(0xFFFBF9F1);

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.06,
        0,
        size.height * 0.78,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';
    final nombre = (user?.userMetadata?['full_name'] as String?)?.trim();
    final saludoNombre = (nombre != null && nombre.isNotEmpty)
        ? nombre
        : (user?.email?.split('@').first.trim().isNotEmpty == true
            ? user!.email!.split('@').first
            : 'Productor');

    return ScheduleColdStartDeepLink(
      child: Scaffold(
        backgroundColor: _crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 220, 16, 20),
                  child: Column(
                    children: [
                      if (isCampesino) ...[
                        _HeroActionCard(
                          icon: Icons.school_rounded,
                          iconBg: _azulHorizonte.withValues(alpha: 0.10),
                          iconFg: _azulHorizonte,
                          title: 'Aprender',
                          titleColor: _azulHorizonte,
                          description:
                              'Practica lectura y escritura paso a paso, a tu ritmo',
                          buttonLabel: 'Ir a aprender',
                          buttonBg: _azulHorizonte,
                          onTap: () => context.push('/alfabetizacion'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _HeroActionCard(
                        icon: Icons.storefront_rounded,
                        iconBg: _rojoManta.withValues(alpha: 0.10),
                        iconFg: _rojoManta,
                        title: 'Vender y comprar',
                        titleColor: _rojoManta,
                        description: 'Publica tus productos y gestiona tu tienda',
                        buttonLabel: 'Ir a mi tienda',
                        buttonBg: _rojoManta,
                        onTap: () => context.push('/comercializacion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Header orgánico
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 210,
              child: ClipPath(
                clipper: _OrganicHeaderClipper(),
                child: Container(color: _azulHorizonte),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $saludoNombre 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sembrapp',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '¿Qué quieres hacer hoy?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _CircleHeaderIconButton(
                        tooltip: 'Mi perfil',
                        icon: Icons.person_rounded,
                        onTap: () => context.push('/profile'),
                      ),
                      const SizedBox(width: 10),
                      _CircleHeaderIconButton(
                        tooltip: 'Salir',
                        icon: Icons.logout_rounded,
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleHeaderIconButton extends StatelessWidget {
  const _CircleHeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
          child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
            child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.titleColor,
    required this.description,
    required this.buttonLabel,
    required this.buttonBg,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final Color titleColor;
  final String description;
  final String buttonLabel;
  final Color buttonBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.55),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zona superior con margen y esquinas redondeadas (no borde a borde)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              height: 110,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 34, color: iconFg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(44),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
