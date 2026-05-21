import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/tutorial/models/tutorial_step.dart';
import '../../../core/tutorial/tutorial_runner.dart';
import '../../../core/tutorial/tutorial_service.dart';
import '../../../core/tutorial/widgets/tutorial_help_button.dart';
import '../tutorial/comercializacion_tutorial_keys.dart';
import '../tutorial/productor_mercado_menu_tutorial.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
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

class ComercializacionHomeScreen extends StatefulWidget {
  const ComercializacionHomeScreen({super.key});

  @override
  State<ComercializacionHomeScreen> createState() =>
      _ComercializacionHomeScreenState();
}

class _ComercializacionHomeScreenState extends State<ComercializacionHomeScreen> {
  final _scrollController = ScrollController();
  final _tutorialInfo = GlobalKey();
  final _tutorialMisProductos = GlobalKey();
  final _tutorialMisPedidos = GlobalKey();
  final _tutorialRed = GlobalKey();
  final _tutorialBeneficios = GlobalKey();
  final _tutorialIndicadores = GlobalKey();
  final _tutorialAyuda = GlobalKey();
  List<TutorialStep>? _tutorialSteps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartTutorial());
  }

  List<TutorialStep> _buildMercadoTutorialSteps() {
    return buildProductorMercadoMenuTutorialSteps(
      infoKey: _tutorialInfo,
      misProductosKey: _tutorialMisProductos,
      misPedidosKey: _tutorialMisPedidos,
      redKey: _tutorialRed,
      beneficiosKey: _tutorialBeneficios,
      indicadoresKey: _tutorialIndicadores,
      ayudaKey: _tutorialAyuda,
    );
  }

  void _tryStartTutorial() {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    if (role != 'campesino') return;

    final pending = TutorialRunner.filterPendingSteps(
      flowId: kTutorialProductorMercadoFlowId,
      steps: _buildMercadoTutorialSteps(),
    );
    if (pending.isEmpty) return;
    setState(() => _tutorialSteps = pending);
  }

  Future<void> _replayTutorial() async {
    await TutorialService.instance.resetFlow(
      stepIdPrefix: kTutorialProductorMercadoFlowId,
    );
    if (!mounted) return;
    setState(() => _tutorialSteps = _buildMercadoTutorialSteps());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 124, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                KeyedSubtree(
                  key: _tutorialInfo,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A4463).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF1A4463),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gestiona tus productos, pedidos y '
                            'herramientas desde aquí.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A4463),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (isCampesino) ...[
                  KeyedSubtree(
                    key: _tutorialMisProductos,
                    child: _TonalNavCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Mis productos',
                      subtitle: 'Lo que tú publicas',
                      onTap: () => context.push('/comercializacion/mis-productos'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialMisPedidos,
                    child: _TonalNavCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Mis pedidos',
                      subtitle: 'Pedidos que hiciste o recibiste',
                      onTap: () => context.push('/comercializacion/ordenes'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialRed,
                    child: _TonalNavCard(
                      icon: Icons.groups_rounded,
                      title: 'Red comunitaria',
                      subtitle: 'Otros productores y pedidos juntos',
                      onTap: () =>
                          context.push('/comercializacion/red-comunitaria'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialBeneficios,
                    child: _TonalNavCard(
                      icon: Icons.stars_rounded,
                      title: 'Beneficios',
                      subtitle: 'Canjear puntos por visibilidad',
                      onTap: () => context.push('/comercializacion/beneficios'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialIndicadores,
                    child: _TonalNavCard(
                      icon: Icons.analytics_rounded,
                      title: 'Precios de referencia',
                      subtitle: 'Indicadores para ayudarte a fijar precios',
                      onTap: () =>
                          context.push('/comercializacion/indicadores'),
                    ),
                  ),
                ] else
                  KeyedSubtree(
                    key: _tutorialMisPedidos,
                    child: _TonalNavCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Mis pedidos',
                      subtitle: 'Pedidos que hiciste o recibiste',
                      onTap: () => context.push('/comercializacion/ordenes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: _azulHorizonte),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mercado',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tu espacio de comercialización',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (isCampesino)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: KeyedSubtree(
                        key: _tutorialAyuda,
                        child: IconTheme(
                          data: const IconThemeData(color: Colors.white),
                          child: TutorialHelpButton(
                            phrases: productorMercadoMenuHelpPhrases,
                            tooltip: 'Ayuda',
                            onReplayWalkthrough: () =>
                                unawaited(_replayTutorial()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_tutorialSteps != null)
            TutorialWalkthroughLayer(
              anchorContext: context,
              flowId: kTutorialProductorMercadoFlowId,
              steps: _tutorialSteps!,
              scrollController: _scrollController,
              onClose: () {
                if (mounted) setState(() => _tutorialSteps = null);
              },
            ),
        ],
      ),
    );
  }
}

class _TonalNavCard extends StatelessWidget {
  const _TonalNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _azul = Color(0xFF1A4463);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const iconBg = Color(0xFF1A4463);
    const iconFg = Color(0xFF1A4463);

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconFg, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: _azul, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
