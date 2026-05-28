import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/escritura_guiada_config.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';

enum _FaseTrazo {
  intro,
  demo,
  guiada,
  libre,
  feedback,
  recompensa,
}

class EscrituraTrazosGuiadoLeccionFlow extends StatefulWidget {
  const EscrituraTrazosGuiadoLeccionFlow({
    super.key,
    required this.leccion,
    required this.config,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final EscrituraGuiadaConfig config;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraTrazosGuiadoLeccionFlow> createState() =>
      _EscrituraTrazosGuiadoLeccionFlowState();
}

class _EscrituraTrazosGuiadoLeccionFlowState
    extends State<EscrituraTrazosGuiadoLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);

  final _tts = AlfabetizacionTtsCoach();
  _FaseTrazo _fase = _FaseTrazo.intro;
  int _indicePaso = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _aciertoFeedbackTick = 0;
  List<Offset> _puntos = <Offset>[];
  final GlobalKey _lienzoTrazoKey = GlobalKey();

  EscrituraPaso get _pasoActual => widget.config.pasos[_indicePaso];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    unawaited(_tts.dispose());
    super.dispose();
  }

  bool _ttsFlujoOk() =>
      mounted && alfabetizacionTtsRouteActive(context);

  Future<void> _ttsDecir(String text) =>
      _tts.speak(text, shouldContinue: _ttsFlujoOk);

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir(widget.config.introNarracion);
  }

  Future<void> _irADemo() async {
    setState(() {
      _fase = _FaseTrazo.demo;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Así se escribe ${_pasoActual.texto}');
    await _ttsDecir(_pasoActual.pista);
  }

  Future<void> _irAGuiada() async {
    setState(() {
      _fase = _FaseTrazo.guiada;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Ahora hazlo tú');
    await _ttsDecir('Traza ${widget.config.nombreUnidad.toLowerCase()} ${_pasoActual.texto}');
  }

  Future<void> _irALibre() async {
    setState(() {
      _fase = _FaseTrazo.libre;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Escribe ${_pasoActual.texto} sin ayuda');
  }

  Future<void> _evaluarGuiada() async {
    await _evaluarTrazo(esGuiada: true);
  }

  Future<void> _evaluarLibre() async {
    await _evaluarTrazo(esGuiada: false);
  }

  Future<void> _evaluarTrazo({required bool esGuiada}) async {
    final ok = _trazoSuficiente(_puntos, _pasoActual.texto);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseTrazo.feedback;
      _mensajeFeedback = ok
          ? (esGuiada ? 'Bien' : 'Muy bien')
          : (esGuiada ? 'Intenta otra vez' : 'Intenta de nuevo');
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseTrazo.feedback) return;
    if (!_fueCorrecto) {
      setState(() {
        _fase = _FaseTrazo.guiada;
        _puntos = [];
      });
      await _ttsDecir('Volvamos a la guía');
      return;
    }
    if (_indicePaso < widget.config.pasos.length - 1) {
      setState(() {
        _indicePaso++;
        _fase = _FaseTrazo.demo;
        _puntos = [];
      });
      await _ttsDecir('Ahora sigue ${_pasoActual.texto}');
      await _ttsDecir(_pasoActual.pista);
      return;
    }
    await _completarLeccion();
  }

  Future<void> _completarLeccion() async {
    if (!_guardado) {
      _guardado = true;
      await widget.onCompletar();
    }
    if (!mounted) return;
    setState(() => _fase = _FaseTrazo.recompensa);
    await _ttsDecir(widget.config.mensajeCompletado);
  }

  bool _trazoSuficiente(List<Offset> raw, String texto) {
    final puntos = raw.where((p) => p.dx.isFinite && p.dy.isFinite).toList();
    final n = math.max(texto.length, 1);
    if (puntos.length < 8 + n * 6) return false;
    final box = _bounds(puntos);
    if (box.height < 28) return false;
    if (box.width < 22 + n * 20) return false;
    return box.width * box.height >= 800 + (n - 1) * 350;
  }

  Rect _bounds(List<Offset> pts) {
    var left = pts.first.dx;
    var right = pts.first.dx;
    var top = pts.first.dy;
    var bottom = pts.first.dy;
    for (final p in pts) {
      left = math.min(left, p.dx);
      right = math.max(right, p.dx);
      top = math.min(top, p.dy);
      bottom = math.max(bottom, p.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _progresoLeccion() {
    final total = 1 + widget.config.pasos.length * 2 + 1;
    var paso = 0;
    switch (_fase) {
      case _FaseTrazo.intro:
        paso = 0;
      case _FaseTrazo.demo:
        paso = 1 + _indicePaso * 2;
      case _FaseTrazo.guiada:
      case _FaseTrazo.libre:
      case _FaseTrazo.feedback:
        paso = 2 + _indicePaso * 2;
      case _FaseTrazo.recompensa:
        paso = total - 1;
    }
    return (paso + 1) / total;
  }

  double _fontModelo(String texto) {
    if (texto.length <= 2) return 88;
    if (texto.length == 3) return 72;
    return 56;
  }

  @override
  Widget build(BuildContext context) {
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Escritura · Nivel ${widget.leccion.nivel}',
      progress: _progresoLeccion(),
      stepLabel: _tituloPantalla(),
      expandBody: true,
      child: _buildFase(),
    );
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseTrazo.intro:
        return 'Introducción';
      case _FaseTrazo.demo:
        return 'Ejemplo · ${_pasoActual.texto}';
      case _FaseTrazo.guiada:
        return 'Trazo guiado';
      case _FaseTrazo.libre:
        return 'Trazo libre';
      case _FaseTrazo.feedback:
        return 'Retroalimentación';
      case _FaseTrazo.recompensa:
        return '¡Lección completada!';
    }
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseTrazo.intro:
        return _buildIntro();
      case _FaseTrazo.demo:
        return _buildDemo();
      case _FaseTrazo.guiada:
        return _buildTrazo(isGuided: true);
      case _FaseTrazo.libre:
        return _buildTrazo(isGuided: false);
      case _FaseTrazo.feedback:
        return _buildFeedback();
      case _FaseTrazo.recompensa:
        return _buildRecompensa();
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.gesture_rounded, size: 110, color: _azulHorizonte),
        const SizedBox(height: 12),
        Text(
          widget.config.tituloNarrado,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Primero verás el modelo y luego practicarás con trazos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.35),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _ttsListo ? _irADemo : null,
          child: const Text('Empezar'),
        ),
      ],
    );
  }

  Widget _buildDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_pasoActual.texto} · ${_pasoActual.pista}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_pasoActual.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _azulHorizonte, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _ModeloTextoPainter(
                _pasoActual.texto,
                fontSize: _fontModelo(_pasoActual.texto),
              ),
              child: const Center(
                child: Text('↑ Sigue la forma', style: TextStyle(color: _azulHorizonte)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _rojoManta),
          onPressed: _irAGuiada,
          child: const Text('Ahora hazlo tú'),
        ),
      ],
    );
  }

  Widget _buildTrazo({required bool isGuided}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isGuided
              ? 'Traza ${_pasoActual.texto} con ayuda'
              : 'Escribe ${_pasoActual.texto} sin guía',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GestureDetector(
            key: _lienzoTrazoKey,
            onPanStart: (d) {
              final p = _normalizarPunto(d.localPosition);
              setState(() => _puntos = [..._puntos, p]);
            },
            onPanUpdate: (d) {
              final p = _normalizarPunto(d.localPosition);
              setState(() => _puntos = [..._puntos, p]);
            },
            onPanEnd: (_) {
              setState(() => _puntos = [..._puntos, const Offset(double.nan, double.nan)]);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _azulHorizonte, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _TrazoPainter(
                  puntos: _puntos,
                  textoModelo: isGuided ? _pasoActual.texto : '',
                  fontSize: _fontModelo(_pasoActual.texto),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _puntos = []),
                child: const Text('Borrar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isGuided ? _evaluarGuiada : _evaluarLibre,
                child: const Text('Comprobar'),
              ),
            ),
          ],
        ),
        if (isGuided) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _irALibre,
            child: const Text('Continuar a trazo libre'),
          ),
        ],
      ],
    );
  }

  Offset _normalizarPunto(Offset localPosition) {
    final box = _lienzoTrazoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return localPosition;
    final size = box.size;
    return Offset(
      localPosition.dx.clamp(0.0, size.width),
      localPosition.dy.clamp(0.0, size.height),
    );
  }

  Widget _buildFeedback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fueCorrecto) ...[
          AlfabetizacionLessonCorrectBanner(animationTick: _aciertoFeedbackTick),
          const SizedBox(height: 16),
        ] else ...[
          const Icon(Icons.refresh_rounded, size: 90, color: _rojoManta),
          const SizedBox(height: 12),
        ],
        Text(
          _mensajeFeedback,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _siguienteDesdeFeedback,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildRecompensa() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlfabetizacionLessonCompletionPanel(
          headline: '¡Lo lograste!',
          detail: 'Lección: ${widget.leccion.titulo}',
          pointsLabel: '+${widget.leccion.puntos} puntos',
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AlfabetizacionUiColors.verdeContinuar,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: const Text('Volver al módulo'),
        ),
      ],
    );
  }
}

class _ModeloTextoPainter extends CustomPainter {
  _ModeloTextoPainter(this.texto, {required this.fontSize});
  final String texto;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final text = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey.withValues(alpha: 0.35),
          fontWeight: FontWeight.w800,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    text.paint(
      canvas,
      Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ModeloTextoPainter oldDelegate) =>
      oldDelegate.texto != texto || oldDelegate.fontSize != fontSize;
}

class _TrazoPainter extends CustomPainter {
  const _TrazoPainter({
    required this.puntos,
    required this.textoModelo,
    required this.fontSize,
  });

  final List<Offset> puntos;
  final String textoModelo;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (textoModelo.isNotEmpty) {
      final text = TextPainter(
        text: TextSpan(
          text: textoModelo,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.withValues(alpha: 0.22),
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      text.paint(
        canvas,
        Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
      );
    }
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < puntos.length; i++) {
      if (!puntos[i - 1].dx.isFinite || !puntos[i].dx.isFinite) continue;
      canvas.drawLine(puntos[i - 1], puntos[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrazoPainter oldDelegate) =>
      oldDelegate.puntos != puntos || oldDelegate.textoModelo != textoModelo;
}
