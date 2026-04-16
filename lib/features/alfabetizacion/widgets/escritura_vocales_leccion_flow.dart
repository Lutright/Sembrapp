import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/lecciones_data.dart';
import '../services/alfabetizacion_tts_coach.dart';

enum _FaseEscritura {
  intro,
  demo,
  guiada,
  libre,
  actividad,
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
      trazo: [Offset(0.3, 0.2), Offset(0.7, 0.2), Offset(0.5, 0.2), Offset(0.5, 0.85), Offset(0.3, 0.85), Offset(0.7, 0.85)],
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
      trazo: [Offset(0.25, 0.2), Offset(0.25, 0.72), Offset(0.5, 0.86), Offset(0.75, 0.72), Offset(0.75, 0.2)],
    ),
  ];

  final _tts = AlfabetizacionTtsCoach();

  _FaseEscritura _fase = _FaseEscritura.intro;
  int _indiceVocal = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _actividadIndex = 0;
  String _actividadRespuesta = '';
  List<Offset> _puntos = <Offset>[];

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

  _VocalItem get _vocalActual => _vocales[_indiceVocal];

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _tts.speak('Vamos a aprender a escribir las vocales');
  }

  Future<void> _irADemo() async {
    setState(() => _fase = _FaseEscritura.demo);
    await _tts.interrupt();
    await _tts.speak('Así se escribe la ${_vocalActual.letra}');
    await _tts.speak('Sube... baja... cruza');
  }

  Future<void> _irAGuiada() async {
    setState(() {
      _fase = _FaseEscritura.guiada;
      _puntos = [];
    });
    await _tts.interrupt();
    await _tts.speak('Ahora hazlo tú');
    await _tts.speak('Sube');
    await _tts.speak('Baja');
    await _tts.speak('Cruza');
  }

  Future<void> _irALibre() async {
    setState(() {
      _fase = _FaseEscritura.libre;
      _puntos = [];
    });
    await _tts.interrupt();
    await _tts.speak('Escribe la ${_vocalActual.letra}');
  }

  Future<void> _evaluarGuiada() async {
    final ok = _trazoAproximado(_puntos, _vocalActual.trazo);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseEscritura.feedback;
      _mensajeFeedback = ok ? 'Bien' : 'Intenta otra vez';
    });
    await _tts.interrupt();
    await _tts.speak(_mensajeFeedback);
  }

  Future<void> _evaluarLibre() async {
    final ok = _trazoAproximado(_puntos, _vocalActual.trazo);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseEscritura.feedback;
      _mensajeFeedback = ok ? 'Muy bien' : 'Intenta de nuevo';
    });
    await _tts.interrupt();
    await _tts.speak(_mensajeFeedback);
  }

  bool _trazoAproximado(List<Offset> raw, List<Offset> objetivo) {
    if (raw.length < 10) return false;
    final box = _bounds(raw);
    if (box.width < 35 || box.height < 35) return false;
    final normalizados = raw
        .map((p) => Offset((p.dx - box.left) / box.width, (p.dy - box.top) / box.height))
        .toList();
    var idxObjetivo = 0;
    for (final p in normalizados) {
      if (idxObjetivo >= objetivo.length) break;
      if ((p - objetivo[idxObjetivo]).distance <= 0.22) idxObjetivo++;
    }
    return idxObjetivo >= math.max(3, (objetivo.length * 0.75).round());
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

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseEscritura.feedback) return;
    if (!_fueCorrecto) {
      setState(() {
        _fase = _FaseEscritura.guiada;
        _puntos = [];
      });
      await _tts.speak('Volvamos a la guía');
      return;
    }
    if (_indiceVocal < _vocales.length - 1) {
      setState(() {
        _indiceVocal++;
        _fase = _FaseEscritura.demo;
        _puntos = [];
      });
      await _tts.speak('Ahora sigue la vocal ${_vocalActual.letra}');
      await _tts.speak(_vocalActual.ejemplo);
      return;
    }
    setState(() {
      _fase = _FaseEscritura.actividad;
      _actividadIndex = 0;
      _actividadRespuesta = '';
    });
    await _tts.speak('Actividad interactiva');
    await _tts.speak('Selecciona la A bien escrita');
  }

  Future<void> _evaluarActividad() async {
    bool ok = false;
    if (_actividadIndex == 0) {
      ok = _actividadRespuesta == 'A';
    } else if (_actividadIndex == 1) {
      ok = _actividadRespuesta.trim().toUpperCase() == 'U';
    } else {
      ok = _actividadRespuesta.trim().toUpperCase() == 'O';
    }
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseEscritura.feedback;
      _mensajeFeedback = ok ? 'Muy bien' : 'Intenta de nuevo';
    });
    await _tts.speak(_mensajeFeedback);
  }

  Future<void> _continuarActividadDesdeFeedback() async {
    if (!_fueCorrecto) {
      setState(() => _fase = _FaseEscritura.actividad);
      await _tts.speak('Escucha y vuelve a intentarlo');
      return;
    }
    if (_actividadIndex < 2) {
      setState(() {
        _actividadIndex++;
        _fase = _FaseEscritura.actividad;
        _actividadRespuesta = '';
      });
      if (_actividadIndex == 1) {
        await _tts.speak('Escribe la letra con la que empieza uva');
      } else {
        await _tts.speak('Ooooo. Escribe la vocal que escuchas');
      }
      return;
    }
    if (!_guardado) {
      _guardado = true;
      await widget.onCompletar();
    }
    setState(() => _fase = _FaseEscritura.recompensa);
    await _tts.speak('Muy bien. Ya sabes escribir las vocales');
  }

  @override
  Widget build(BuildContext context) {
    const totalEtapas = 7;
    final progreso = (_fase.index + 1) / totalEtapas;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leccion.titulo),
        backgroundColor: _azulHorizonte,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progreso),
            const SizedBox(height: 8),
            Text(_tituloPantalla(), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Expanded(child: _buildFase()),
          ],
        ),
      ),
    );
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseEscritura.intro:
        return 'Pantalla 1 · Introducción';
      case _FaseEscritura.demo:
        return 'Pantalla 2 · Trazo guiado';
      case _FaseEscritura.guiada:
        return 'Pantalla 3 · Escritura guiada';
      case _FaseEscritura.libre:
        return 'Pantalla 4 · Escritura libre';
      case _FaseEscritura.actividad:
        return 'Pantalla 5 · Actividad';
      case _FaseEscritura.feedback:
        return 'Pantalla 6 · Retroalimentación';
      case _FaseEscritura.recompensa:
        return 'Pantalla 7 · Recompensa';
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
      case _FaseEscritura.actividad:
        return _buildActividad();
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
          child: GestureDetector(
            onPanUpdate: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(d.globalPosition);
              setState(() => _puntos = [..._puntos, local]);
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

  Widget _buildActividad() {
    if (_actividadIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Selecciona la A bien escrita', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ...['A', 'A/', 'B'].map(
            (op) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => setState(() => _actividadRespuesta = op),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _actividadRespuesta == op ? Colors.blue.shade50 : null,
                ),
                child: Text(op, style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          const Spacer(),
          FilledButton(onPressed: _evaluarActividad, child: const Text('Validar')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _actividadIndex == 1 ? '🍇 Escribe la letra con la que empieza' : 'Audio: Ooooo. Escribe la vocal',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => _actividadRespuesta = v,
          decoration: const InputDecoration(hintText: 'Escribe aquí'),
        ),
        const Spacer(),
        FilledButton(onPressed: _evaluarActividad, child: const Text('Validar')),
      ],
    );
  }

  Widget _buildFeedback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _fueCorrecto ? Icons.celebration_rounded : Icons.refresh_rounded,
          size: 90,
          color: _fueCorrecto ? Colors.green : _rojoManta,
        ),
        const SizedBox(height: 12),
        Text(
          _mensajeFeedback,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _fase == _FaseEscritura.feedback && _indiceVocal == _vocales.length - 1
              ? _continuarActividadDesdeFeedback
              : _siguienteDesdeFeedback,
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
        const Text('🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 80)),
        const SizedBox(height: 8),
        const Text(
          'Completaste la escritura de vocales',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '+10 puntos',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 8),
        const Text('⭐ Progreso: 10%', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(backgroundColor: _rojoManta),
          child: const Text('Volver'),
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
      canvas.drawLine(puntos[i - 1], puntos[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrazoPainter oldDelegate) =>
      oldDelegate.puntos != puntos || oldDelegate.letraModelo != letraModelo;
}
