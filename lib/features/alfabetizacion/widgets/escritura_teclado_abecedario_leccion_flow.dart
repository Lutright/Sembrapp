import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';

enum _FaseTecladoAbecedario {
  intro,
  demo,
  practica,
  feedback,
  recompensa,
}

class _LetraTecladoItem {
  const _LetraTecladoItem({
    required this.letra,
    required this.ejemplo,
    required this.emoji,
  });

  final String letra;
  final String ejemplo;
  final String emoji;
}

class EscrituraTecladoAbecedarioLeccionFlow extends StatefulWidget {
  const EscrituraTecladoAbecedarioLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraTecladoAbecedarioLeccionFlow> createState() =>
      _EscrituraTecladoAbecedarioLeccionFlowState();
}

class _EscrituraTecladoAbecedarioLeccionFlowState
    extends State<EscrituraTecladoAbecedarioLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);
  static const Color _resaltadoTecla = Color(0xFF2A6B7C);
  static const Color _resaltadoFondo = Color(0xFFE8F4F8);

  // Primer acercamiento: A, B y C.
  static const _letras = <_LetraTecladoItem>[
    _LetraTecladoItem(letra: 'A', ejemplo: 'A de árbol', emoji: '🌳'),
    _LetraTecladoItem(letra: 'B', ejemplo: 'B de burro', emoji: '🐴'),
    _LetraTecladoItem(letra: 'C', ejemplo: 'C de casa', emoji: '🏠'),
  ];

  // Layout simple tipo QWERTY (solo para resaltar letras).
  static const _filasTeclado = <List<String>>[
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  final _tts = AlfabetizacionTtsCoach();
  final _entradaController = TextEditingController();

  _FaseTecladoAbecedario _fase = _FaseTecladoAbecedario.intro;
  int _indiceLetra = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _aciertoFeedbackTick = 0;
  int _animacionTecladoTick = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    unawaited(_tts.dispose());
    _entradaController.dispose();
    super.dispose();
  }

  bool _ttsFlujoOk() =>
      mounted && alfabetizacionTtsRouteActive(context);

  Future<void> _ttsDecir(String text) =>
      _tts.speak(text, shouldContinue: _ttsFlujoOk);

  _LetraTecladoItem get _letraActual => _letras[_indiceLetra];

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir('Vamos a practicar letras en el teclado');
  }

  Future<void> _irAPrimera() async {
    setState(() {
      _fase = _FaseTecladoAbecedario.demo;
      _indiceLetra = 0;
      _animacionTecladoTick++;
    });
    await _tts.interrupt();
    await _narrarDemoVocal(); // reutiliza la misma idea: demo por letra
  }

  Future<void> _narrarDemoVocal() async {
    await _ttsDecir('Busca la letra ${_letraActual.letra} en el teclado');
    await _ttsDecir(_letraActual.ejemplo);
    await _ttsDecir('Mira la tecla resaltada');
  }

  Future<void> _irAPractica() async {
    _entradaController.clear();
    setState(() => _fase = _FaseTecladoAbecedario.practica);
    await _tts.interrupt();
    await _ttsDecir('Ahora escribe la letra ${_letraActual.letra}');
  }

  Future<void> _evaluarPractica() async {
    final texto = _entradaController.text.trim().toUpperCase();
    final ok = texto == _letraActual.letra;
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseTecladoAbecedario.feedback;
      _mensajeFeedback = ok ? '¡Muy bien!' : 'Intenta otra vez';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseTecladoAbecedario.feedback) return;
    if (!_fueCorrecto) {
      _entradaController.clear();
      setState(() => _fase = _FaseTecladoAbecedario.practica);
      await _ttsDecir('Escribe de nuevo la letra ${_letraActual.letra}');
      return;
    }
    if (_indiceLetra < _letras.length - 1) {
      setState(() {
        _indiceLetra++;
        _fase = _FaseTecladoAbecedario.demo;
        _animacionTecladoTick++;
      });
      await _narrarDemoVocal();
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
    setState(() => _fase = _FaseTecladoAbecedario.recompensa);
    await _ttsDecir('¡Lo lograste! Ya reconoces las letras en el teclado');
  }

  double _progresoLeccion() {
    final totalPasos = 1 + (_letras.length * 2) + 1;
    var paso = 0;
    switch (_fase) {
      case _FaseTecladoAbecedario.intro:
        paso = 0;
      case _FaseTecladoAbecedario.demo:
        paso = 1 + _indiceLetra * 2;
      case _FaseTecladoAbecedario.practica:
      case _FaseTecladoAbecedario.feedback:
        paso = 2 + _indiceLetra * 2;
      case _FaseTecladoAbecedario.recompensa:
        paso = totalPasos - 1;
    }
    return (paso + 1) / totalPasos;
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseTecladoAbecedario.intro:
        return 'Introducción';
      case _FaseTecladoAbecedario.demo:
        return 'Teclado · ${_letraActual.letra}';
      case _FaseTecladoAbecedario.practica:
        return 'Tu turno · ${_letraActual.letra}';
      case _FaseTecladoAbecedario.feedback:
        return 'Retroalimentación';
      case _FaseTecladoAbecedario.recompensa:
        return '¡Lección completada!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Escritura · Nivel ${widget.leccion.nivel}',
      progress: _progresoLeccion(),
      stepLabel: _tituloPantalla(),
      expandBody: _fase == _FaseTecladoAbecedario.demo,
      child: _buildFase(),
    );
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseTecladoAbecedario.intro:
        return _buildIntro();
      case _FaseTecladoAbecedario.demo:
        return _buildDemo();
      case _FaseTecladoAbecedario.practica:
        return _buildPractica();
      case _FaseTecladoAbecedario.feedback:
        return _buildFeedback();
      case _FaseTecladoAbecedario.recompensa:
        return _buildRecompensa();
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.keyboard_rounded, size: 110, color: _azulHorizonte),
        const SizedBox(height: 12),
        const Text(
          'Teclado del abecedario',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Aprende dónde están A, B y C en el teclado y escríbelas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _ttsListo ? _irAPrimera : null,
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _letraActual.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 52),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _TecladoVocalAnimado(
            key: ValueKey<int>(_animacionTecladoTick),
            letraResaltada: _letraActual.letra,
            filas: _filasTeclado,
            colorResaltado: _resaltadoTecla,
            fondoResaltado: _resaltadoFondo,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _rojoManta),
          onPressed: _irAPractica,
          child: const Text('Practicar esta letra'),
        ),
      ],
    );
  }

  Widget _buildPractica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escribe la letra ${_letraActual.letra}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _letraActual.ejemplo,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        _TecladoLetraEstatico(
          letraResaltada: _letraActual.letra,
          filas: _filasTeclado,
          colorResaltado: _resaltadoTecla,
          fondoResaltado: _resaltadoFondo,
          opacidadReferencia: 0.45,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _entradaController,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _azulHorizonte,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: _letraActual.letra,
            hintStyle: TextStyle(
              color: _azulHorizonte.withValues(alpha: 0.25),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _azulHorizonte, width: 2),
            ),
          ),
          onSubmitted: (_) => unawaited(_evaluarPractica()),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _evaluarPractica,
          child: const Text('Comprobar'),
        ),
      ],
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

class _TecladoLetraEstatico extends StatelessWidget {
  const _TecladoLetraEstatico({
    required this.letraResaltada,
    required this.filas,
    required this.colorResaltado,
    required this.fondoResaltado,
    required this.opacidadReferencia,
    this.escalaResaltado = 1.0,
  });

  final String letraResaltada;
  final List<List<String>> filas;
  final Color colorResaltado;
  final Color fondoResaltado;
  final double opacidadReferencia;
  final double escalaResaltado;

  @override
  Widget build(BuildContext context) {
    final objetivo = letraResaltada.toUpperCase();
    return Opacity(
      opacity: opacidadReferencia,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < filas.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < filas.length - 1 ? 8 : 0),
                child: _fila(filas[i], objetivo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(List<String> letras, String objetivo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < letras.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          _tecla(letras[i], letras[i] == objetivo),
        ],
      ],
    );
  }

  Widget _tecla(String letra, bool resaltada) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: resaltada ? fondoResaltado : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: resaltada ? colorResaltado : Colors.grey.shade400,
          width: resaltada ? 2.5 : 1,
        ),
      ),
      child: Text(
        letra,
        style: TextStyle(
          fontSize: 14,
          fontWeight: resaltada ? FontWeight.w800 : FontWeight.w600,
          color: resaltada ? colorResaltado : Colors.grey.shade800,
        ),
      ),
    );
    if (!resaltada) return child;
    return Transform.scale(scale: escalaResaltado, child: child);
  }
}

/// Animación simple: la tecla resaltada “late” mientras el resto permanece igual.
class _TecladoVocalAnimado extends StatefulWidget {
  const _TecladoVocalAnimado({
    super.key,
    required this.letraResaltada,
    required this.filas,
    required this.colorResaltado,
    required this.fondoResaltado,
  });

  final String letraResaltada;
  final List<List<String>> filas;
  final Color colorResaltado;
  final Color fondoResaltado;

  @override
  State<_TecladoVocalAnimado> createState() => _TecladoVocalAnimadoState();
}

class _TecladoVocalAnimadoState extends State<_TecladoVocalAnimado>
    with TickerProviderStateMixin {
  late final AnimationController _pulso;
  late final Animation<double> _pulsoAnim;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulsoAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulso, curve: Curves.easeInOut),
    );
    _pulso.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulsoAnim,
      builder: (context, _) {
        return _TecladoLetraEstatico(
          letraResaltada: widget.letraResaltada,
          filas: widget.filas,
          colorResaltado: widget.colorResaltado,
          fondoResaltado: widget.fondoResaltado,
          opacidadReferencia: 1.0,
          escalaResaltado: _pulsoAnim.value,
        );
      },
    );
  }
}

