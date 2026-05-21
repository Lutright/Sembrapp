import 'dart:async';

import 'package:flutter/material.dart';

import '../router/root_navigator_key.dart';
import 'models/tutorial_step.dart';
import 'tutorial_service.dart';

/// Pinta atenuación con un solo hueco (spotlight). No participa en hit testing.
class TutorialSpotlightPainter extends CustomPainter {
  TutorialSpotlightPainter({
    required this.holeRect,
    this.borderRadius = 12,
  });

  final Rect? holeRect;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.48);
    final holeR = holeRect;
    if (holeR == null || holeR.isEmpty || !holeR.isFinite) {
      canvas.drawPath(full, overlayPaint);
      return;
    }
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          holeR,
          Radius.circular(borderRadius),
        ),
      );
    try {
      final cut = Path.combine(PathOperation.difference, full, hole);
      canvas.drawPath(cut, overlayPaint);
    } catch (_) {
      canvas.drawPath(full, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.borderRadius != borderRadius;
  }
}

final class TutorialRunner {
  TutorialRunner._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  /// Pasos pendientes según prefs / perfil.
  static List<TutorialStep> filterPendingSteps({
    required String flowId,
    required List<TutorialStep> steps,
  }) {
    if (!TutorialService.instance.initialized) return [];
    if (!TutorialService.instance.tutorialsGloballyEnabled) return [];
    if (TutorialService.instance.isFlowSkipped(flowId)) return [];
    return steps
        .where((s) => !TutorialService.instance.isStepCompleted(s.id))
        .toList();
  }

  static void dismiss() {
    final e = _entry;
    _entry = null;
    e?.remove();
    unawaited(TutorialService.instance.interruptTts());
  }

  /// Overlay global (respaldo). Preferir [TutorialWalkthroughLayer] en el Stack de la pantalla.
  static void show(
    BuildContext context, {
    required String flowId,
    required List<TutorialStep> steps,
    ScrollController? scrollController,
  }) {
    final pending = filterPendingSteps(flowId: flowId, steps: steps);
    if (pending.isEmpty) return;

    dismiss();

    final overlay = rootNavigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => SizedBox.expand(
        child: _TutorialWalkthroughView(
          anchorContext: context,
          flowId: flowId,
          steps: pending,
          scrollController: scrollController,
          onClose: dismiss,
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// Capa de tutorial dentro del [Stack] de la pantalla (recomendado; controles siempre visibles).
class TutorialWalkthroughLayer extends StatelessWidget {
  const TutorialWalkthroughLayer({
    super.key,
    required this.anchorContext,
    required this.flowId,
    required this.steps,
    this.scrollController,
    required this.onClose,
  });

  final BuildContext anchorContext;
  final String flowId;
  final List<TutorialStep> steps;
  final ScrollController? scrollController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: _TutorialWalkthroughView(
        anchorContext: anchorContext,
        flowId: flowId,
        steps: steps,
        scrollController: scrollController,
        onClose: onClose,
      ),
    );
  }
}

class _TutorialWalkthroughView extends StatefulWidget {
  const _TutorialWalkthroughView({
    required this.anchorContext,
    required this.flowId,
    required this.steps,
    this.scrollController,
    required this.onClose,
  });

  final BuildContext anchorContext;
  final String flowId;
  final List<TutorialStep> steps;
  final ScrollController? scrollController;
  final VoidCallback onClose;

  @override
  State<_TutorialWalkthroughView> createState() =>
      _TutorialWalkthroughViewState();
}

enum _TutorialPanelEdge { top, bottom }

class _TutorialWalkthroughViewState extends State<_TutorialWalkthroughView> {
  int _index = 0;
  bool _speaking = false;
  bool _scrollRebuildScheduled = false;
  bool _advancing = false;
  final _panelKey = GlobalKey();
  double? _panelHeight;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareCurrentStep());
      _scheduleMeasurePanel();
    });
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    unawaited(TutorialService.instance.interruptTts());
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollRebuildScheduled) return;
    _scrollRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollRebuildScheduled = false;
      if (mounted) setState(() {});
    });
  }

  TutorialStep get _step => widget.steps[_index];

  void _close() {
    unawaited(TutorialService.instance.interruptTts());
    widget.onClose();
  }

  Future<void> _prepareCurrentStep() async {
    if (!mounted) return;
    final target = _step.targetKey.currentContext;
    if (target != null) {
      try {
        final alignment = _scrollAlignmentForTarget(target);
        await Scrollable.ensureVisible(
          target,
          alignment: alignment,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {});
    _scheduleMeasurePanel();
    unawaited(_speakCurrent());
  }

  double _scrollAlignmentForTarget(BuildContext target) {
    final targetBox = target.findRenderObject();
    final overlayBox = context.findRenderObject();
    if (targetBox is! RenderBox ||
        !targetBox.hasSize ||
        overlayBox is! RenderBox ||
        !overlayBox.hasSize) {
      return 0.32;
    }
    final targetTop = targetBox.localToGlobal(Offset.zero);
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    final y = targetTop.dy - overlayOrigin.dy;
    final h = overlayBox.size.height;
    if (h <= 0) return 0.32;
    return y > h * 0.52 ? 0.18 : 0.38;
  }

  void _scheduleMeasurePanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _panelKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final h = box.size.height;
      if (_panelHeight == null || (h - _panelHeight!).abs() > 2) {
        setState(() => _panelHeight = h);
      }
    });
  }

  _TutorialPanelEdge _resolvePanelEdge({
    required Rect? hole,
    required Size overlaySize,
    required EdgeInsets safePadding,
    required double panelHeight,
  }) {
    const horizontalPad = 16.0;
    const verticalPad = 16.0;
    const gap = 10.0;

    Rect panelRectAtBottom() {
      final top = overlaySize.height -
          safePadding.bottom -
          verticalPad -
          panelHeight;
      return Rect.fromLTWH(
        horizontalPad,
        top,
        overlaySize.width - horizontalPad * 2,
        panelHeight,
      );
    }

    Rect panelRectAtTop() {
      final top = safePadding.top + verticalPad;
      return Rect.fromLTWH(
        horizontalPad,
        top,
        overlaySize.width - horizontalPad * 2,
        panelHeight,
      );
    }

    bool overlaps(Rect panel, Rect target) =>
        panel.overlaps(target.inflate(gap));

    if (hole == null) return _TutorialPanelEdge.bottom;

    final bottomRect = panelRectAtBottom();
    if (!overlaps(bottomRect, hole)) return _TutorialPanelEdge.bottom;

    final topRect = panelRectAtTop();
    if (!overlaps(topRect, hole)) return _TutorialPanelEdge.top;

    return hole.center.dy > overlaySize.height * 0.45
        ? _TutorialPanelEdge.top
        : _TutorialPanelEdge.bottom;
  }

  Future<void> _speakCurrent() async {
    if (!mounted) return;
    setState(() => _speaking = true);
    try {
      await TutorialService.instance.speakTutorialPhrase(
        widget.anchorContext,
        _step.ttsPhrase,
      );
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Rect? _holeRectAdjusted() {
    final targetCtx = _step.targetKey.currentContext;
    if (targetCtx == null) return null;
    final targetBox = targetCtx.findRenderObject();
    if (targetBox is! RenderBox || !targetBox.hasSize) return null;

    // El overlay y los targets suelen ser hermanos en un Stack (no ancestro).
    // Restamos el origen global del overlay para obtener coords locales al recorte.
    final overlayBox = context.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) return null;

    final targetTopLeft = targetBox.localToGlobal(Offset.zero);
    final targetBottomRight = targetBox.localToGlobal(
      Offset(targetBox.size.width, targetBox.size.height),
    );
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    final topLeft = targetTopLeft - overlayOrigin;
    final bottomRight = targetBottomRight - overlayOrigin;
    final base = Rect.fromPoints(topLeft, bottomRight);
    final p = _step.padding;
    final r = Rect.fromLTRB(
      base.left - p.left,
      base.top - p.top,
      base.right + p.right,
      base.bottom + p.bottom,
    );
    if (!r.isFinite || r.isEmpty) return null;
    return r;
  }

  Future<void> _siguiente() async {
    if (_advancing) return;
    _advancing = true;
    try {
      await TutorialService.instance.interruptTts();
      await TutorialService.instance.markStepCompleted(_step.id);
      if (!mounted) return;
      if (_index + 1 >= widget.steps.length) {
        _close();
        return;
      }
      setState(() => _index++);
      await _prepareCurrentStep();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _anterior() async {
    if (_advancing || _index <= 0) return;
    _advancing = true;
    try {
      await TutorialService.instance.interruptTts();
      setState(() => _index--);
      await _prepareCurrentStep();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _omitirTodo() async {
    await TutorialService.instance.interruptTts();
    await TutorialService.instance.markFlowSkipped(widget.flowId);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final hole = _holeRectAdjusted();
    final isLast = _index + 1 >= widget.steps.length;
    final panel = KeyedSubtree(
      key: _panelKey,
      child: _TutorialControlPanel(
        stepIndex: _index,
        stepCount: widget.steps.length,
        hintText: _step.hintText,
        speaking: _speaking,
        advancing: _advancing,
        isLast: isLast,
        canGoBack: _index > 0,
        onOmitir: () => unawaited(_omitirTodo()),
        onRepetir: () => unawaited(_speakCurrent()),
        onAtras: () => unawaited(_anterior()),
        onSiguiente: () => unawaited(_siguiente()),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final overlaySize = Size(constraints.maxWidth, constraints.maxHeight);
        final safe = MediaQuery.paddingOf(context);
        final panelH = _panelHeight ?? 232;
        final edge = _resolvePanelEdge(
          hole: hole,
          overlaySize: overlaySize,
          safePadding: safe,
          panelHeight: panelH,
        );
        final atTop = edge == _TutorialPanelEdge.top;

        return SizedBox.expand(
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: TutorialSpotlightPainter(holeRect: hole),
                  ),
                ),
                Align(
                  alignment: atTop
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: SafeArea(
                    top: atTop,
                    bottom: !atTop,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        atTop ? 12 : 0,
                        16,
                        atTop ? 0 : 16,
                      ),
                      child: panel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TutorialControlPanel extends StatelessWidget {
  const _TutorialControlPanel({
    required this.stepIndex,
    required this.stepCount,
    required this.hintText,
    required this.speaking,
    required this.advancing,
    required this.isLast,
    required this.canGoBack,
    required this.onOmitir,
    required this.onRepetir,
    required this.onAtras,
    required this.onSiguiente,
  });

  final int stepIndex;
  final int stepCount;
  final String? hintText;
  final bool speaking;
  final bool advancing;
  final bool isLast;
  final bool canGoBack;
  final VoidCallback onOmitir;
  final VoidCallback onRepetir;
  final VoidCallback onAtras;
  final VoidCallback onSiguiente;

  static const Color _azul = Color(0xFF1A4463);
  static const Color _crema = Color(0xFFFBF9F1);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      color: _crema,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paso ${stepIndex + 1} de $stepCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _azul.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 8),
            if (speaking)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reproduciendo guía…',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else if (hintText != null)
              Text(
                hintText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        (advancing || !canGoBack) ? null : onAtras,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _azul,
                      side: const BorderSide(color: _azul, width: 1.5),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Atrás',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: advancing ? null : onSiguiente,
                    style: FilledButton.styleFrom(
                      backgroundColor: _azul,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Listo' : 'Siguiente',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onOmitir,
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: onRepetir,
                    child: const Text(
                      'Repetir audio',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
