import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';
import 'alfabetizacion_trazo_validator.dart';

enum _FaseEscritura {
  intro,
  demo,
  guiada,
  libre,
  feedback,
  recompensa,
}

class _VocalItem {
  const _VocalItem({
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

class EscrituraVocalesLeccionFlow extends StatefulWidget {
  const EscrituraVocalesLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraVocalesLeccionFlow> createState() =>
      _EscrituraVocalesLeccionFlowState();
}

class _EscrituraVocalesLeccionFlowState extends State<EscrituraVocalesLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);
  static const _vocales = <_VocalItem>[
    _VocalItem(
      letra: 'A',
      ejemplo: 'A de árbol',
      emoji: '🌳',
      trazo: [Offset(0.2, 0.9), Offset(0.5, 0.15), Offset(0.8, 0.9), Offset(0.35, 0.55), Offset(0.65, 0.55)],
    ),
    _VocalItem(
      letra: 'E',
      ejemplo: 'E de escoba',
      emoji: '🧹',
      trazo: [Offset(0.75, 0.2), Offset(0.25, 0.2), Offset(0.25, 0.85), Offset(0.75, 0.85), Offset(0.25, 0.52), Offset(0.65, 0.52)],
    ),
    _VocalItem(
      letra: 'I',
      ejemplo: 'I de iguana',
      emoji: '🦎',
      // Línea vertical principal; trazos cortos arriba/abajo opcionales.
      trazo: [
        Offset(0.5, 0.12),
        Offset(0.5, 0.9),
        Offset(0.34, 0.12),
        Offset(0.66, 0.12),
        Offset(0.34, 0.9),
        Offset(0.66, 0.9),
      ],
    ),
    _VocalItem(
      letra: 'O',
      ejemplo: 'O de oveja',
      emoji: '🐑',
      trazo: [Offset(0.5, 0.15), Offset(0.78, 0.3), Offset(0.82, 0.58), Offset(0.68, 0.84), Offset(0.32, 0.84), Offset(0.18, 0.58), Offset(0.22, 0.3), Offset(0.5, 0.15)],
    ),
    _VocalItem(
      letra: 'U',
      ejemplo: 'U de uva',
      emoji: '🍇',
      trazo: [
        Offset(0.27, 0.14),
        Offset(0.27, 0.42),
        Offset(0.27, 0.68),
        Offset(0.36, 0.8),
        Offset(0.5, 0.88),
        Offset(0.64, 0.8),
        Offset(0.73, 0.68),
        Offset(0.73, 0.42),
        Offset(0.73, 0.14),
      ],
    ),
  ];

  final _tts = AlfabetizacionTtsCoach();

  _FaseEscritura _fase = _FaseEscritura.intro;
  int _indiceVocal = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  List<Offset> _puntos = <Offset>[];
  int _aciertoFeedbackTick = 0;
  Size _lienzoSize = Size.zero;
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

  _VocalItem get _vocalActual => _vocales[_indiceVocal];

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir('Vamos a aprender a escribir las vocales');
  }

  Future<void> _irADemo() async {
    setState(() => _fase = _FaseEscritura.demo);
    await _tts.interrupt();
    await _ttsDecir('Así se escribe la ${_vocalActual.letra}');
    await _ttsDecir(_instruccionDemoTrazo(_vocalActual.letra));
  }

  Future<void> _irAGuiada() async {
    setState(() {
      _fase = _FaseEscritura.guiada;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Ahora hazlo tú');
    for (final paso in _instruccionesGuiadasTrazo(_vocalActual.letra)) {
      await _ttsDecir(paso);
    }
  }

  String _instruccionDemoTrazo(String letra) {
    switch (letra) {
      case 'I':
        return 'Haz una línea recta de arriba hacia abajo';
      case 'O':
        return 'Haz un círculo';
      case 'U':
        return 'Baja, curva y sube';
      default:
        return 'Sube... baja... cruza';
    }
  }

  List<String> _instruccionesGuiadasTrazo(String letra) {
    switch (letra) {
      case 'I':
        return ['Arriba', 'Abajo'];
      case 'O':
        return ['Gira', 'Cierra el círculo'];
      case 'U':
        return ['Baja', 'Curva', 'Sube'];
      default:
        return ['Sube', 'Baja', 'Cruza'];
    }
  }

  Future<void> _irALibre() async {
    setState(() {
      _fase = _FaseEscritura.libre;
      _puntos = [];
    });
    await _tts.interrupt();
    await _ttsDecir('Escribe la ${_vocalActual.letra}');
  }

  Future<void> _evaluarGuiada() async {
    final ok = _validarTrazoActual();
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseEscritura.feedback;
      _mensajeFeedback = ok ? 'Bien' : 'Intenta otra vez';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _evaluarLibre() async {
    final ok = _validarTrazoActual();
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseEscritura.feedback;
      _mensajeFeedback = ok ? 'Muy bien' : 'Intenta de nuevo';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  bool _validarTrazoActual() {
    final canvasSize = _lienzoSize;
    final perfil = switch (_vocalActual.letra) {
      'I' => AlfabetizacionTrazoPerfil.vocalI,
      'U' => AlfabetizacionTrazoPerfil.vocalU,
      _ => AlfabetizacionTrazoPerfil.estandar,
    };
    return AlfabetizacionTrazoValidator.validarLetraEnLienzo(
      puntosRaw: _puntos,
      letra: _vocalActual.letra,
      canvasSize: canvasSize,
      perfil: perfil,
    );
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseEscritura.feedback) return;
    if (!_fueCorrecto) {
      setState(() {
        _fase = _FaseEscritura.guiada;
        _puntos = [];
      });
      await _ttsDecir('Volvamos a la guía');
      return;
    }
    if (_indiceVocal < _vocales.length - 1) {
      setState(() {
        _indiceVocal++;
        _fase = _FaseEscritura.demo;
        _puntos = [];
      });
      await _ttsDecir('Ahora sigue la vocal ${_vocalActual.letra}');
      await _ttsDecir(_vocalActual.ejemplo);
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
    setState(() => _fase = _FaseEscritura.recompensa);
    await _ttsDecir('Muy bien. Ya sabes escribir las vocales');
  }

  @override
  Widget build(BuildContext context) {
    const totalEtapas = 6;
    final progreso = (_fase.index + 1) / totalEtapas;
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Escritura · Nivel ${widget.leccion.nivel}',
      progress: progreso,
      stepLabel: _tituloPantalla(),
      expandBody: true,
      child: _buildFase(),
    );
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseEscritura.intro:
        return 'Introducción';
      case _FaseEscritura.demo:
        return 'Trazo de ejemplo';
      case _FaseEscritura.guiada:
        return 'Escritura guiada';
      case _FaseEscritura.libre:
        return 'Escritura libre';
      case _FaseEscritura.feedback:
        return 'Retroalimentación';
      case _FaseEscritura.recompensa:
        return '¡Lección completada!';
    }
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseEscritura.intro:
        return _buildIntro();
      case _FaseEscritura.demo:
        return _buildDemo();
      case _FaseEscritura.guiada:
        return _buildTrazo(isGuided: true);
      case _FaseEscritura.libre:
        return _buildTrazo(isGuided: false);
      case _FaseEscritura.feedback:
        return _buildFeedback();
      case _FaseEscritura.recompensa:
        return _buildRecompensa();
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.edit_note_rounded, size: 120, color: _azulHorizonte),
        const SizedBox(height: 8),
        const Text('✏️🌾', textAlign: TextAlign.center, style: TextStyle(fontSize: 44)),
        const SizedBox(height: 16),
        const Text(
          'Vamos a aprender a escribir las vocales',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
          '${_vocalActual.letra} · ${_vocalActual.ejemplo}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_vocalActual.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _azulHorizonte, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _ModeloLetraPainter(_vocalActual.letra),
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
          isGuided ? 'Traza la ${_vocalActual.letra} con ayuda' : 'Escribe ${_vocalActual.letra} sin guía',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _lienzoSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
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
                      letraModelo: isGuided ? _vocalActual.letra : '',
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
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
            child: const Text('Continuar a escritura libre'),
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
          const Icon(
            Icons.refresh_rounded,
            size: 90,
            color: _rojoManta,
          ),
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

class _ModeloLetraPainter extends CustomPainter {
  const _ModeloLetraPainter(this.letra);
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
    text.paint(canvas, Offset((size.width - text.width) / 2, (size.height - text.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _ModeloLetraPainter oldDelegate) => oldDelegate.letra != letra;
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
      text.paint(canvas, Offset((size.width - text.width) / 2, (size.height - text.height) / 2));
    }
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < puntos.length; i++) {
      if (!puntos[i - 1].dx.isFinite || !puntos[i - 1].dy.isFinite) continue;
      if (!puntos[i].dx.isFinite || !puntos[i].dy.isFinite) continue;
      canvas.drawLine(puntos[i - 1], puntos[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrazoPainter oldDelegate) =>
      oldDelegate.puntos != puntos || oldDelegate.letraModelo != letraModelo;
}
