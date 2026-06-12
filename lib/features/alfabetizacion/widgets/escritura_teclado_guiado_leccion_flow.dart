import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/escritura_guiada_config.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';
import 'alfabetizacion_teclado_referencia.dart';

enum _FaseTeclado {
  intro,
  demo,
  practica,
  feedback,
  recompensa,
}

class EscrituraTecladoGuiadoLeccionFlow extends StatefulWidget {
  const EscrituraTecladoGuiadoLeccionFlow({
    super.key,
    required this.leccion,
    required this.config,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final EscrituraGuiadaConfig config;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraTecladoGuiadoLeccionFlow> createState() =>
      _EscrituraTecladoGuiadoLeccionFlowState();
}

class _EscrituraTecladoGuiadoLeccionFlowState
    extends State<EscrituraTecladoGuiadoLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);
  static const Color _resaltadoTecla = Color(0xFF2A6B7C);
  static const Color _resaltadoFondo = Color(0xFFE8F4F8);

  static const _filasTeclado = <List<String>>[
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  final _tts = AlfabetizacionTtsCoach();
  final _entradaController = TextEditingController();
  final _entradaFocus = FocusNode();

  _FaseTeclado _fase = _FaseTeclado.intro;
  int _indicePaso = 0;
  bool _ttsListo = false;
  bool _guardado = false;
  bool _fueCorrecto = false;
  String _mensajeFeedback = '';
  int _aciertoFeedbackTick = 0;
  int _animacionTecladoTick = 0;

  EscrituraPaso get _pasoActual => widget.config.pasos[_indicePaso];

  Set<String> get _teclasResaltadas => _pasoActual.texto
      .toUpperCase()
      .replaceAll(' ', '')
      .split('')
      .toSet();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    unawaited(_tts.dispose());
    _entradaFocus.dispose();
    _entradaController.dispose();
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

  Future<void> _empezar() async {
    setState(() {
      _fase = _FaseTeclado.demo;
      _indicePaso = 0;
      _animacionTecladoTick++;
    });
    await _tts.interrupt();
    await _narrarDemo();
  }

  Future<void> _narrarDemo() async {
    await _ttsDecir('Busca las letras de ${_pasoActual.texto} en el teclado');
    await _ttsDecir(_pasoActual.pista);
    await _ttsDecir('Mira las teclas resaltadas');
  }

  Future<void> _irAPractica() async {
    _entradaController.clear();
    setState(() => _fase = _FaseTeclado.practica);
    await _tts.interrupt();
    await _ttsDecir('Escribe ${_pasoActual.texto}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entradaFocus.requestFocus();
    });
  }

  String _normalizarEntrada(String value) {
    var limpio = value.toUpperCase().replaceAll(RegExp(r'[^A-ZÑ\s]'), '');
    limpio = limpio.replaceAll(RegExp(r'\s+'), ' ');
    return limpio;
  }

  /// Acepta la misma secuencia de letras con o sin espacios (p. ej. ABC = A B C).
  bool _coincideEntrada(String ingresado, String esperado) {
    final a = _normalizarEntrada(ingresado).trim();
    final b = _normalizarEntrada(esperado).trim();
    if (a == b) return true;
    return a.replaceAll(' ', '') == b.replaceAll(' ', '');
  }

  void _onEntradaCambiada(String value) {
    final maxLetras =
        _normalizarEntrada(_pasoActual.texto).replaceAll(' ', '').length;
    var limpio = _normalizarEntrada(value);
    var letras = limpio.replaceAll(' ', '');
    if (letras.length > maxLetras) {
      letras = letras.substring(0, maxLetras);
      limpio = letras;
    }
    if (_entradaController.text != limpio) {
      _entradaController.value = TextEditingValue(
        text: limpio,
        selection: TextSelection.collapsed(offset: limpio.length),
      );
    }
  }

  Future<void> _evaluarPractica() async {
    final ok = _coincideEntrada(_entradaController.text, _pasoActual.texto);
    setState(() {
      _fueCorrecto = ok;
      _fase = _FaseTeclado.feedback;
      _mensajeFeedback = ok ? '¡Muy bien!' : 'Intenta otra vez';
      if (ok) _aciertoFeedbackTick++;
    });
    await _tts.interrupt();
    await _ttsDecir(_mensajeFeedback);
  }

  Future<void> _siguienteDesdeFeedback() async {
    if (_fase != _FaseTeclado.feedback) return;
    if (!_fueCorrecto) {
      _entradaController.clear();
      setState(() => _fase = _FaseTeclado.practica);
      await _ttsDecir('Escribe ${_pasoActual.texto}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entradaFocus.requestFocus();
      });
      return;
    }
    if (_indicePaso < widget.config.pasos.length - 1) {
      setState(() {
        _indicePaso++;
        _fase = _FaseTeclado.demo;
        _animacionTecladoTick++;
      });
      await _narrarDemo();
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
    setState(() => _fase = _FaseTeclado.recompensa);
    await _ttsDecir(widget.config.mensajeCompletado);
  }

  double _progresoLeccion() {
    final total = 1 + widget.config.pasos.length * 2 + 1;
    var paso = 0;
    switch (_fase) {
      case _FaseTeclado.intro:
        paso = 0;
      case _FaseTeclado.demo:
        paso = 1 + _indicePaso * 2;
      case _FaseTeclado.practica:
      case _FaseTeclado.feedback:
        paso = 2 + _indicePaso * 2;
      case _FaseTeclado.recompensa:
        paso = total - 1;
    }
    return (paso + 1) / total;
  }

  double _fontEntrada(int longitud) {
    if (longitud <= 2) return 48;
    if (longitud <= 4) return 40;
    if (longitud <= 8) return 32;
    if (longitud <= 14) return 24;
    if (longitud <= 20) return 20;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Escritura · Nivel ${widget.leccion.nivel}',
      progress: _progresoLeccion(),
      stepLabel: _tituloPantalla(),
      expandBody: _fase == _FaseTeclado.demo,
      resizeForKeyboard: _fase == _FaseTeclado.practica,
      child: _buildFase(),
    );
  }

  String _tituloPantalla() {
    switch (_fase) {
      case _FaseTeclado.intro:
        return 'Introducción';
      case _FaseTeclado.demo:
        return 'Teclado · ${_pasoActual.texto}';
      case _FaseTeclado.practica:
        return 'Tu turno · ${_pasoActual.texto}';
      case _FaseTeclado.feedback:
        return 'Retroalimentación';
      case _FaseTeclado.recompensa:
        return '¡Lección completada!';
    }
  }

  Widget _buildFase() {
    switch (_fase) {
      case _FaseTeclado.intro:
        return _buildIntro();
      case _FaseTeclado.demo:
        return _buildDemo();
      case _FaseTeclado.practica:
        return _buildPractica();
      case _FaseTeclado.feedback:
        return _buildFeedback();
      case _FaseTeclado.recompensa:
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
        Text(
          widget.config.tituloNarrado,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Verás el teclado con las letras resaltadas y luego las escribirás.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.35),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _ttsListo ? _empezar : null,
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
        const SizedBox(height: 6),
        Text(_pasoActual.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 8),
        Expanded(
          child: _TecladoAnimado(
            key: ValueKey<int>(_animacionTecladoTick),
            teclasResaltadas: _teclasResaltadas,
            filas: _filasTeclado,
            colorResaltado: _resaltadoTecla,
            fondoResaltado: _resaltadoFondo,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _rojoManta),
          onPressed: _irAPractica,
          child: const Text('Practicar'),
        ),
      ],
    );
  }

  Widget _buildPractica() {
    final longitud = _pasoActual.texto.length;
    final tecladoSistemaVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Escribe ${_pasoActual.texto}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _pasoActual.pista,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        if (!tecladoSistemaVisible) ...[
          const SizedBox(height: 16),
          AlfabetizacionTecladoReferencia(
            teclasResaltadas: _teclasResaltadas,
            filas: _filasTeclado,
            colorResaltado: _resaltadoTecla,
            fondoResaltado: _resaltadoFondo,
            opacidadReferencia: 0.45,
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 12),
        TextField(
          controller: _entradaController,
          focusNode: _entradaFocus,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          maxLength: longitud,
          maxLines: longitud > 16 ? 2 : 1,
          style: TextStyle(
            fontSize: _fontEntrada(longitud),
            fontWeight: FontWeight.bold,
            color: _azulHorizonte,
            letterSpacing: longitud > 8 ? 2 : (longitud > 2 ? 4 : 8),
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: _pasoActual.texto,
            hintStyle: TextStyle(
              color: _azulHorizonte.withValues(alpha: 0.25),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _azulHorizonte, width: 2),
            ),
          ),
          onChanged: _onEntradaCambiada,
          onSubmitted: (_) => unawaited(_evaluarPractica()),
          onTap: () => _entradaFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _rojoManta,
            minimumSize: const Size.fromHeight(52),
          ),
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

class _TecladoAnimado extends StatefulWidget {
  const _TecladoAnimado({
    super.key,
    required this.teclasResaltadas,
    required this.filas,
    required this.colorResaltado,
    required this.fondoResaltado,
  });

  final Set<String> teclasResaltadas;
  final List<List<String>> filas;
  final Color colorResaltado;
  final Color fondoResaltado;

  @override
  State<_TecladoAnimado> createState() => _TecladoAnimadoState();
}

class _TecladoAnimadoState extends State<_TecladoAnimado>
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
    _pulsoAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
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
          child: AlfabetizacionTecladoReferencia(
            teclasResaltadas: widget.teclasResaltadas,
            filas: widget.filas,
            colorResaltado: widget.colorResaltado,
            fondoResaltado: widget.fondoResaltado,
            escalaResaltado: _pulsoAnim.value,
          ),
        );
      },
    );
  }
}
