import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/tutorial/models/tutorial_step.dart';
import '../../../core/tutorial/tutorial_runner.dart';
import '../../../core/tutorial/tutorial_service.dart';
import '../../../core/tutorial/widgets/tutorial_help_button.dart';
import '../audio/comercializacion_audio_phrases.dart';
import '../services/comercializacion_audio_guide.dart';
import '../tutorial/comercializacion_tutorial_keys.dart';
import '../tutorial/productor_mercado_menu_tutorial.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/tonalist_screen_header.dart';
import '../widgets/comercializacion_audio_coach_bar.dart';

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

  final _audioGuide = ComercializacionAudioGuide();
  bool _ttsListo = false;
  bool _audioAutoYa = false;
  bool _narrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartTutorial());
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _audioGuide.ensureReady();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _audioGuide.isReady);
    if (_ttsListo && !_audioAutoYa) {
      _audioAutoYa = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_narrarEntrada());
      });
    }
  }

  bool get _tutorialActivo => _tutorialSteps != null || TutorialRunner.isShowing;

  Future<void> _narrarEntrada({bool forzar = false}) async {
    if (_tutorialActivo) return;
    if (!_ttsListo || _narrando) return;
    setState(() => _narrando = true);
    try {
      await _audioGuide.interrupt();
      if (!mounted) return;
      await _audioGuide.speakSequence(
        context,
        ComercializacionAudioPhrases.homeWelcome,
      );
    } finally {
      if (mounted) setState(() => _narrando = false);
    }
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

  Future<void> _go(String route, String phrase) async {
    if (_tutorialActivo) {
      await context.push(route);
      return;
    }
    await _audioGuide.interruptAndSpeak(
      context,
      phrase,
    );
    if (!mounted) return;
    await context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                16,
                TonalistHeaderMetrics.contentTopPadding,
                16,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                ComercializacionAudioCoachBar(
                  listo: _ttsListo,
                  narrando: _narrando,
                  enabled: !_tutorialActivo,
                  onRepeat: () => unawaited(_narrarEntrada(forzar: true)),
                ),
                const SizedBox(height: 14),
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
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/mis-productos',
                          ComercializacionAudioPhrases.goMisProductos,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialMisPedidos,
                    child: _TonalNavCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Mis pedidos',
                      subtitle: 'Pedidos que hiciste o recibiste',
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/ordenes',
                          ComercializacionAudioPhrases.goMisPedidos,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialRed,
                    child: _TonalNavCard(
                      icon: Icons.groups_rounded,
                      title: 'Red comunitaria',
                      subtitle: 'Otros productores y pedidos juntos',
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/red-comunitaria',
                          ComercializacionAudioPhrases.goRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialBeneficios,
                    child: _TonalNavCard(
                      icon: Icons.stars_rounded,
                      title: 'Beneficios',
                      subtitle: 'Canjear puntos por visibilidad',
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/beneficios',
                          ComercializacionAudioPhrases.goBeneficios,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialIndicadores,
                    child: _TonalNavCard(
                      icon: Icons.analytics_rounded,
                      title: 'Precios de referencia',
                      subtitle: 'Indicadores para ayudarte a fijar precios',
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/indicadores',
                          ComercializacionAudioPhrases.goIndicadores,
                        ),
                      ),
                    ),
                  ),
                ] else
                  KeyedSubtree(
                    key: _tutorialMisPedidos,
                    child: _TonalNavCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Mis pedidos',
                      subtitle: 'Pedidos que hiciste o recibiste',
                      onTap: () => unawaited(
                        _go(
                          '/comercializacion/ordenes',
                          ComercializacionAudioPhrases.goMisPedidos,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const TonalistHeaderBackground(
            height: TonalistHeaderMetrics.standardHeight,
          ),
          TonalistHeaderChrome(
            height: TonalistHeaderMetrics.standardHeight,
            title: 'Mercado',
            subtitle: 'Tu espacio de comercialización',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            trailing: isCampesino
                ? KeyedSubtree(
                    key: _tutorialAyuda,
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: TutorialHelpButton(
                        phrases: productorMercadoMenuHelpPhrases,
                        tooltip: 'Ayuda',
                        onReplayWalkthrough: () => unawaited(_replayTutorial()),
                      ),
                    ),
                  )
                : null,
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
