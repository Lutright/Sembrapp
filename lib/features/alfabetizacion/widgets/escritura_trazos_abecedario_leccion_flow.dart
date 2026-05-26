import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';

enum _FaseAbecedario {
  intro,
  demo,
  guiada,
  libre,
  feedback,
  recompensa,
}

class _LetraItem {
  const _LetraItem({
    required this.letra,
    required this.ejemplo,
    required this.emoji,
    required this.trazo,
  });

  final String letra;
  final String ejemplo;
  final String emoji;
  final List<Offset> trazo;
}

class _Cfg {
  const _Cfg({
    required this.umbralCobertura,
    required this.umbralPrecision,
    required this.umbralCercaniaModelo,
    required this.umbralCercaniaTrazo,
  });

  final double umbralCobertura;
  final double umbralPrecision;
  final double umbralCercaniaModelo;
  final double umbralCercaniaTrazo;
}

class EscrituraTrazosAbecedarioLeccionFlow extends StatefulWidget {
  const EscrituraTrazosAbecedarioLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraTrazosAbecedarioLeccionFlow> createState() =>
      _EscrituraTrazosAbecedarioLeccionFlowState();
}

class _EscrituraTrazosAbecedarioLeccionFlowState
    extends State<EscrituraTrazosAbecedarioLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);

  // Primer acercamiento: letras simples de trazo y referencia.
  static const _letras = <_LetraItem>[
    _LetraItem(
      letra: 'A',
      ejemplo: 'A de árbol',
      emoji: '🌳',
      // Polilínea aproximada de A (dos diagonales + barra).
      trazo: [
        Offset(0.25, 0.85),
        Offset(0.5, 0.12),
        Offset(0.75, 0.85),
        Offset(0.62, 0.55),
        Offset(0.38, 0.55),
      ],
    ),
    _LetraItem(
      letra: 'B',
      ejemplo: 'B de burro',
      emoji: '🐴',
      // Polilínea aproximada de B (espina + dos curvas en forma de tramos).
      trazo: [
        Offset(0.28, 0.15),
        Offset(0.28, 0.85),
        Offset(0.66, 0.85),
        Offset(0.66, 0.55),
        Offset(0.28, 0.55),
        Offset(0.66, 0.55),
        Offset(0.66, 0.15),
        Offset(0.28, 0.15),
      ],
    ),
    _LetraItem(
      letra: 'C',
      ejemplo: 'C de casa',
      emoji: '🏠',
      // Polilínea aproximada de C (arco abierto).
      trazo: [
        Offset(0.7, 0.25),
        Offset(0.35, 0.15),
        Offset(0.25, 0.4),
        Offset(0.25, 0.6),
        Offset(0.35, 0.85),
        Offset(0.7, 0.75),
      ],
    ),
  ];

  final _tts = AlfabetizacionTtsCoach();
  _FaseAbecedario _fase = _FaseAbecedario.intro;
  int _indiceLetra = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _aciertoFeedbackTick = 0;

  List<Offset> _puntos = <Offset>[];
  final GlobalKey _lienzoTrazoKey = GlobalKey();

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

  _LetraItem get _letraActual => _letras[_indiceLetra];

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir('Vamos a practicar trazos del abecedario');
  }

  Future<void> _irADemo() async {
    setState(() {
      _fase = _FaseAbecedario.demo;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Así se escribe la ${_letraActual.letra}');
    await _ttsDecir('Mira bien el trazo');
  }

  Future<void> _irAGuiada() async {
    setState(() {
      _fase = _FaseAbecedario.guiada;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Ahora hazlo tú');
    await _ttsDecir('Traza con cuidado la letra ${_letraActual.letra}');
  }

  Future<void> _irALibre() async {
    setState(() {
      _fase = _FaseAbecedario.libre;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Ahora sin ayuda');
    await _ttsDecir('Escribe la letra ${_letraActual.letra}');
  }

  Future<void> _evaluarGuiada() async {
    final ok = _trazoAproximado(_puntos, _letraActual.trazo, letra: _letraActual.letra);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseAbecedario.feedback;
      _mensajeFeedback = ok ? 'Bien' : 'Intenta otra vez';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _evaluarLibre() async {
    final ok = _trazoAproximado(_puntos, _letraActual.trazo, letra: _letraActual.letra);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseAbecedario.feedback;
      _mensajeFeedback = ok ? 'Muy bien' : 'Intenta de nuevo';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseAbecedario.feedback) return;
    if (!_fueCorrecto) {
      setState(() {
        _fase = _FaseAbecedario.guiada;
        _puntos = [];
      });
      await _ttsDecir('Volvamos a la guía');
      return;
    }
    if (_indiceLetra < _letras.length - 1) {
      setState(() {
        _indiceLetra++;
        _fase = _FaseAbecedario.demo;
        _puntos = [];
      });
      await _ttsDecir('Ahora sigue la letra ${_letraActual.letra}');
      await _ttsDecir(_letraActual.ejemplo);
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
    setState(() => _fase = _FaseAbecedario.recompensa);
    await _ttsDecir('¡Lo lograste! Ya practicaste el abecedario con trazos');
  }

  double _progresoLeccion() {
    final totalPasos = 1 + (_letras.length * 2) + 1;
    var paso = 0;
    switch (_fase) {
      case _FaseAbecedario.intro:
        paso = 0;
      case _FaseAbecedario.demo:
        paso = 1 + _indiceLetra * 2;
      case _FaseAbecedario.guiada:
      case _FaseAbecedario.libre:
      case _FaseAbecedario.feedback:
        paso = 2 + _indiceLetra * 2;
      case _FaseAbecedario.recompensa:
        paso = totalPasos - 1;
    }
    return (paso + 1) / totalPasos;
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseAbecedario.intro:
        return 'Introducción';
      case _FaseAbecedario.demo:
        return 'Trazo de ejemplo';
      case _FaseAbecedario.guiada:
        return 'Trazo guiado';
      case _FaseAbecedario.libre:
        return 'Trazo libre';
      case _FaseAbecedario.feedback:
        return 'Retroalimentación';
      case _FaseAbecedario.recompensa:
        return '¡Lección completada!';
    }
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseAbecedario.intro:
        return _buildIntro();
      case _FaseAbecedario.demo:
        return _buildDemo();
      case _FaseAbecedario.guiada:
        return _buildTrazo(isGuided: true);
      case _FaseAbecedario.libre:
        return _buildTrazo(isGuided: false);
      case _FaseAbecedario.feedback:
        return _buildFeedback();
      case _FaseAbecedario.recompensa:
        return _buildRecompensa();
    }
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

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.edit_note_rounded, size: 120, color: _azulHorizonte),
        const SizedBox(height: 8),
        const Text('✏️ Abecedario', textAlign: TextAlign.center, style: TextStyle(fontSize: 44)),
        const SizedBox(height: 16),
        const Text(
          'Practica con trazos las letras A, B y C',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
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
          '${_letraActual.letra} · ${_letraActual.ejemplo}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_letraActual.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _azulHorizonte, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _ModeloLetraPainter(_letraActual.letra),
              child: const Center(
                child: Text('↑ Direccion del trazo', style: TextStyle(color: _azulHorizonte)),
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
              ? 'Traza la ${_letraActual.letra} con ayuda'
              : 'Escribe ${_letraActual.letra} sin guía',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GestureDetector(
            key: _lienzoTrazoKey,
            onPanStart: (d) {
              final p = _normalizarPuntoAlLienzo(d.localPosition);
              setState(() => _puntos = [..._puntos, p]);
            },
            onPanUpdate: (d) {
              final p = _normalizarPuntoAlLienzo(d.localPosition);
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
                  letraModelo: isGuided ? _letraActual.letra : '',
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

  Offset _normalizarPuntoAlLienzo(Offset localPosition) {
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

  bool _trazoAproximado(List<Offset> raw, List<Offset> objetivo,
      {required String letra}) {
    // Validación más tolerante que vocales, porque letras requieren más trazos y
    // los modelos son aproximados.
    final puntosValidos = raw.where((p) => p.dx.isFinite && p.dy.isFinite).toList();
    if (puntosValidos.length < 14) return false;

    final box = _bounds(puntosValidos);
    if (box.width < 18 || box.height < 35) return false;

    final normalizadosUser = _normalizarTrazadoConSeparadores(raw);
    final objetivoNormalizado = _normalizarTrazado(objetivo);

    // Parámetros por letra (para ajustar tolerancia).
    final cfg = switch (letra) {
      'A' => const _Cfg(
        umbralCobertura: 0.32,
        umbralPrecision: 0.42,
        umbralCercaniaModelo: 0.22,
        umbralCercaniaTrazo: 0.3,
      ),
      'B' => const _Cfg(
        umbralCobertura: 0.28,
        umbralPrecision: 0.4,
        umbralCercaniaModelo: 0.23,
        umbralCercaniaTrazo: 0.32,
      ),
      'C' => const _Cfg(
        umbralCobertura: 0.28,
        umbralPrecision: 0.4,
        umbralCercaniaModelo: 0.22,
        umbralCercaniaTrazo: 0.32,
      ),
      _ => const _Cfg(
        umbralCobertura: 0.3,
        umbralPrecision: 0.4,
        umbralCercaniaModelo: 0.22,
        umbralCercaniaTrazo: 0.3,
      ),
    };

    final coberturaModelo = _ratioCercaniaAContorno(
      muestra: objetivoNormalizado,
      contorno: normalizadosUser,
      umbral: cfg.umbralCercaniaModelo,
    );
    final precisionTrazo = _ratioCercaniaAContorno(
      muestra: normalizadosUser.where((p) => p.dx.isFinite && p.dy.isFinite).toList(),
      contorno: objetivoNormalizado,
      umbral: cfg.umbralCercaniaTrazo,
    );

    return coberturaModelo >= cfg.umbralCobertura &&
        precisionTrazo >= cfg.umbralPrecision;
  }

  List<Offset> _normalizarTrazadoConSeparadores(List<Offset> pts) {
    final finitos = pts.where((p) => p.dx.isFinite && p.dy.isFinite).toList();
    final box = _bounds(finitos);
    final ancho = math.max(box.width, 1.0);
    final alto = math.max(box.height, 1.0);
    return pts
        .map((p) {
          if (!p.dx.isFinite || !p.dy.isFinite) {
            return const Offset(double.nan, double.nan);
          }
          return Offset((p.dx - box.left) / ancho, (p.dy - box.top) / alto);
        })
        .toList();
  }

  List<Offset> _normalizarTrazado(List<Offset> pts) {
    final box = _bounds(pts);
    final ancho = math.max(box.width, 1.0);
    final alto = math.max(box.height, 1.0);
    return pts
        .map((p) => Offset((p.dx - box.left) / ancho, (p.dy - box.top) / alto))
        .toList();
  }

  double _ratioCercaniaAContorno({
    required List<Offset> muestra,
    required List<Offset> contorno,
    required double umbral,
  }) {
    if (muestra.isEmpty) return 0;
    var cercanos = 0;
    for (final p in muestra) {
      if (!p.dx.isFinite || !p.dy.isFinite) continue;
      final d = _distanciaMinimaAContorno(p, contorno);
      if (d <= umbral) cercanos++;
    }
    return cercanos / muestra.length;
  }

  double _distanciaMinimaAContorno(Offset p, List<Offset> contorno) {
    var minimo = double.infinity;
    for (var i = 1; i < contorno.length; i++) {
      final a = contorno[i - 1];
      final b = contorno[i];
      if (!a.dx.isFinite || !a.dy.isFinite) continue;
      if (!b.dx.isFinite || !b.dy.isFinite) continue;
      final d = _distanciaPuntoASegmento(p, a, b);
      if (d < minimo) minimo = d;
    }
    return minimo;
  }

  double _distanciaPuntoASegmento(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = (ab.dx * ab.dx) + (ab.dy * ab.dy);
    if (ab2 <= 1e-9) return (p - a).distance;
    final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / ab2;
    final tc = t.clamp(0.0, 1.0);
    final proyeccion = Offset(a.dx + ab.dx * tc, a.dy + ab.dy * tc);
    return (p - proyeccion).distance;
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
}

class _ModeloLetraPainter extends CustomPainter {
  _ModeloLetraPainter(this.letra);
  final String letra;

  @override
  void paint(Canvas canvas, Size size) {
    final style = TextStyle(
      fontSize: size.height * 0.7,
      color: Colors.grey.withValues(alpha: 0.35),
      fontWeight: FontWeight.w800,
    );
    final text = TextPainter(
      text: TextSpan(text: letra, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    text.paint(
      canvas,
      Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ModeloLetraPainter oldDelegate) =>
      oldDelegate.letra != letra;
}

class _TrazoPainter extends CustomPainter {
  const _TrazoPainter({
    required this.puntos,
    required this.letraModelo,
  });

  final List<Offset> puntos;
  final String letraModelo;

  @override
  void paint(Canvas canvas, Size size) {
    if (letraModelo.isNotEmpty) {
      final text = TextPainter(
        text: TextSpan(
          text: letraModelo,
          style: TextStyle(
            fontSize: size.height * 0.7,
            color: Colors.grey.withValues(alpha: 0.25),
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      text.paint(canvas,
          Offset((size.width - text.width) / 2, (size.height - text.height) / 2));
    }

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Dibuja saltando NaNs para evitar “puentes” entre trazos.
    for (var i = 1; i < puntos.length; i++) {
      final a = puntos[i - 1];
      final b = puntos[i];
      if (!a.dx.isFinite || !a.dy.isFinite) continue;
      if (!b.dx.isFinite || !b.dy.isFinite) continue;
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrazoPainter oldDelegate) =>
      oldDelegate.puntos != puntos || oldDelegate.letraModelo != letraModelo;
}

