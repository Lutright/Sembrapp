import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';

enum _FaseTecladoAbc {
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

  // Mismo conjunto y ejemplos que en la lección guiada de abecedario.
  static const _abecedario = <_LetraTecladoItem>[
    _LetraTecladoItem(letra: 'A', ejemplo: 'A de árbol', emoji: '🌳'),
    _LetraTecladoItem(letra: 'B', ejemplo: 'B de burro', emoji: '🐴'),
    _LetraTecladoItem(letra: 'C', ejemplo: 'C de casa', emoji: '🏠'),
    _LetraTecladoItem(letra: 'D', ejemplo: 'D de dado', emoji: '🎲'),
    _LetraTecladoItem(letra: 'E', ejemplo: 'E de escoba', emoji: '🧹'),
    _LetraTecladoItem(letra: 'F', ejemplo: 'F de flor', emoji: '🌼'),
    _LetraTecladoItem(letra: 'G', ejemplo: 'G de gato', emoji: '🐱'),
    _LetraTecladoItem(letra: 'H', ejemplo: 'H de hoja', emoji: '🍃'),
    _LetraTecladoItem(letra: 'I', ejemplo: 'I de iguana', emoji: '🦎'),
    _LetraTecladoItem(letra: 'J', ejemplo: 'J de jirafa', emoji: '🦒'),
    _LetraTecladoItem(letra: 'K', ejemplo: 'K de kiwi', emoji: '🥝'),
    _LetraTecladoItem(letra: 'L', ejemplo: 'L de luna', emoji: '🌙'),
    _LetraTecladoItem(letra: 'M', ejemplo: 'M de mano', emoji: '✋'),
    _LetraTecladoItem(letra: 'N', ejemplo: 'N de nube', emoji: '☁️'),
    _LetraTecladoItem(letra: 'Ñ', ejemplo: 'Ñ de ñandú', emoji: '🐦'),
    _LetraTecladoItem(letra: 'O', ejemplo: 'O de oveja', emoji: '🐑'),
    _LetraTecladoItem(letra: 'P', ejemplo: 'P de perro', emoji: '🐶'),
    _LetraTecladoItem(letra: 'Q', ejemplo: 'Q de queso', emoji: '🧀'),
    _LetraTecladoItem(letra: 'R', ejemplo: 'R de rana', emoji: '🐸'),
    _LetraTecladoItem(letra: 'S', ejemplo: 'S de sol', emoji: '☀️'),
    _LetraTecladoItem(letra: 'T', ejemplo: 'T de tomate', emoji: '🍅'),
    _LetraTecladoItem(letra: 'U', ejemplo: 'U de uva', emoji: '🍇'),
    _LetraTecladoItem(letra: 'V', ejemplo: 'V de vaca', emoji: '🐄'),
    _LetraTecladoItem(letra: 'W', ejemplo: 'W de wifi', emoji: '📶'),
    _LetraTecladoItem(letra: 'X', ejemplo: 'X de xilófono', emoji: '🎼'),
    _LetraTecladoItem(letra: 'Y', ejemplo: 'Y de yoyo', emoji: '🪀'),
    _LetraTecladoItem(letra: 'Z', ejemplo: 'Z de zapato', emoji: '👟'),
  ];

  static const _filasTeclado = <List<String>>[
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  final _tts = AlfabetizacionTtsCoach();
  final _entradaController = TextEditingController();

  _FaseTecladoAbc _fase = _FaseTecladoAbc.intro;
  int _indiceLetra = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _aciertoFeedbackTick = 0;
  int _animacionTecladoTick = 0;

  List<_LetraTecladoItem> get _letrasActuales {
    final id = widget.leccion.id;
    if (id == 'E1-3') {
      // Primera mitad aproximada del abecedario.
      return _abecedario.sublist(0, 14);
    }
    if (id == 'E1-4') {
      // Segunda mitad.
      return _abecedario.sublist(14);
    }
    return _abecedario;
  }

  _LetraTecladoItem get _letraActual => _letrasActuales[_indiceLetra];

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

  bool _ttsFlujoOk() => mounted && alfabetizacionTtsRouteActive(context);

  Future<void> _ttsDecir(String text) =>
      _tts.speak(text, shouldContinue: _ttsFlujoOk);

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir(
      'Vamos a conocer el teclado con el abecedario. Verás dónde está cada letra y luego la escribirás tú.',
    );
  }

  Future<void> _empezarPrimeraLetra() async {
    setState(() {
      _fase = _FaseTecladoAbc.demo;
      _indiceLetra = 0;
      _animacionTecladoTick++;
    });
    await _tts.interrupt();
    await _narrarDemoLetra();
  }

  Future<void> _narrarDemoLetra() async {
    await _ttsDecir(
      'Así se encuentra la letra ${_letraActual.letra} en el teclado',
    );
    await _ttsDecir(_letraActual.ejemplo);
    await _ttsDecir('Mira la tecla resaltada');
  }

  Future<void> _irAPractica() async {
    _entradaController.clear();
    setState(() => _fase = _FaseTecladoAbc.practica);
    await _tts.interrupt();
    await _ttsDecir('Ahora escribe la letra ${_letraActual.letra}');
  }

  Future<void> _evaluarPractica() async {
    final texto = _entradaController.text.trim().toUpperCase();
    final ok = texto == _letraActual.letra;
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseTecladoAbc.feedback;
      _mensajeFeedback = ok ? '¡Muy bien!' : 'Intenta otra vez';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseTecladoAbc.feedback) return;
    if (!_fueCorrecto) {
      _entradaController.clear();
      setState(() => _fase = _FaseTecladoAbc.practica);
      await _ttsDecir('Escribe la letra ${_letraActual.letra}');
      return;
    }
    if (_indiceLetra < _letrasActuales.length - 1) {
      setState(() {
        _indiceLetra++;
        _fase = _FaseTecladoAbc.demo;
        _animacionTecladoTick++;
      });
      await _narrarDemoLetra();
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
    setState(() => _fase = _FaseTecladoAbc.recompensa);
    await _ttsDecir('Excelente. Ya conoces estas letras en el teclado');
  }

  double _progresoLeccion() {
    final totalPasos = 1 + (_letrasActuales.length * 2) + 1;
    var paso = 0;
    switch (_fase) {
      case _FaseTecladoAbc.intro:
        paso = 0;
      case _FaseTecladoAbc.demo:
        paso = 1 + _indiceLetra * 2;
      case _FaseTecladoAbc.practica:
      case _FaseTecladoAbc.feedback:
        paso = 2 + _indiceLetra * 2;
      case _FaseTecladoAbc.recompensa:
        paso = totalPasos - 1;
    }
    return (paso + 1) / totalPasos;
  }

  @override
  Widget build(BuildContext context) {
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Escritura · Nivel ${widget.leccion.nivel}',
      progress: _progresoLeccion(),
      stepLabel: _tituloPantalla(),
      expandBody: _fase == _FaseTecladoAbc.demo,
      child: _buildFase(),
    );
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseTecladoAbc.intro:
        return 'Introducción';
      case _FaseTecladoAbc.demo:
        return 'Teclado · ${_letraActual.letra}';
      case _FaseTecladoAbc.practica:
        return 'Tu turno · ${_letraActual.letra}';
      case _FaseTecladoAbc.feedback:
        return 'Retroalimentación';
      case _FaseTecladoAbc.recompensa:
        return '¡Lección completada!';
    }
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseTecladoAbc.intro:
        return _buildIntro();
      case _FaseTecladoAbc.demo:
        return _buildDemoTeclado();
      case _FaseTecladoAbc.practica:
        return _buildPractica();
      case _FaseTecladoAbc.feedback:
        return _buildFeedback();
      case _FaseTecladoAbc.recompensa:
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
          'Teclado y abecedario',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Verás dónde está cada letra del abecedario en el teclado y luego la escribirás tú.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _ttsListo ? _empezarPrimeraLetra : null,
          child: const Text('Empezar'),
        ),
      ],
    );
  }

  Widget _buildDemoTeclado() {
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
          child: _TecladoAbcAnimado(
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
        _TecladoAbcEstatico(
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

class _TecladoAbcAnimado extends StatefulWidget {
  const _TecladoAbcAnimado({
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
  State<_TecladoAbcAnimado> createState() => _TecladoAbcAnimadoState();
}

class _TecladoAbcAnimadoState extends State<_TecladoAbcAnimado>
    with TickerProviderStateMixin {
  late final AnimationController _entrada;
  late final AnimationController _pulso;
  late final Animation<double> _entradaAnim;
  late final Animation<double> _pulsoAnim;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entradaAnim = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    _pulsoAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulso, curve: Curves.easeInOut),
    );
    _entrada.forward();
    _pulso.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrada.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entradaAnim, _pulsoAnim]),
      builder: (context, _) {
        return Opacity(
          opacity: _entradaAnim.value,
          child: Transform.scale(
            scale: 0.88 + 0.12 * _entradaAnim.value,
            child: _TecladoAbcEstatico(
              letraResaltada: widget.letraResaltada,
              filas: widget.filas,
              colorResaltado: widget.colorResaltado,
              fondoResaltado: widget.fondoResaltado,
              escalaResaltado: _pulsoAnim.value,
            ),
          ),
        );
      },
    );
  }
}

class _TecladoAbcEstatico extends StatelessWidget {
  const _TecladoAbcEstatico({
    required this.letraResaltada,
    required this.filas,
    required this.colorResaltado,
    required this.fondoResaltado,
    this.opacidadReferencia = 1.0,
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
          boxShadow: AlfabetizacionLessonTokens.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < filas.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < filas.length - 1 ? 8 : 0),
                child: _filaTeclado(filas[i], objetivo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filaTeclado(List<String> letras, String objetivo) {
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
        boxShadow: resaltada
            ? [
                BoxShadow(
                  color: colorResaltado.withValues(alpha: 0.45),
                  blurRadius: 10 * escalaResaltado,
                  spreadRadius: 1,
                ),
              ]
            : null,
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

