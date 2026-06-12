import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
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

class _VocalTecladoItem {
  const _VocalTecladoItem({
    required this.letra,
    required this.ejemplo,
    required this.emoji,
  });

  final String letra;
  final String ejemplo;
  final String emoji;
}

class EscrituraTecladoVocalesLeccionFlow extends StatefulWidget {
  const EscrituraTecladoVocalesLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<EscrituraTecladoVocalesLeccionFlow> createState() =>
      _EscrituraTecladoVocalesLeccionFlowState();
}

class _EscrituraTecladoVocalesLeccionFlowState
    extends State<EscrituraTecladoVocalesLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);
  static const Color _resaltadoTecla = Color(0xFF2A6B7C);
  static const Color _resaltadoFondo = Color(0xFFE8F4F8);

  static const _vocales = <_VocalTecladoItem>[
    _VocalTecladoItem(letra: 'A', ejemplo: 'A de árbol', emoji: '🌳'),
    _VocalTecladoItem(letra: 'E', ejemplo: 'E de escoba', emoji: '🧹'),
    _VocalTecladoItem(letra: 'I', ejemplo: 'I de iguana', emoji: '🦎'),
    _VocalTecladoItem(letra: 'O', ejemplo: 'O de oveja', emoji: '🐑'),
    _VocalTecladoItem(letra: 'U', ejemplo: 'U de uva', emoji: '🍇'),
  ];

  static const _filasTeclado = <List<String>>[
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  final _tts = AlfabetizacionTtsCoach();
  final _entradaController = TextEditingController();
  final _entradaFocus = FocusNode();

  _FaseTeclado _fase = _FaseTeclado.intro;
  int _indiceVocal = 0;
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
    _entradaFocus.dispose();
    _entradaController.dispose();
    super.dispose();
  }

  bool _ttsFlujoOk() =>
      mounted && alfabetizacionTtsRouteActive(context);

  Future<void> _ttsDecir(String text) =>
      _tts.speak(text, shouldContinue: _ttsFlujoOk);

  _VocalTecladoItem get _vocalActual => _vocales[_indiceVocal];

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _ttsDecir(
      'Vamos a conocer el teclado. Aprenderás dónde están las vocales.',
    );
  }

  Future<void> _empezarPrimeraVocal() async {
    setState(() {
      _fase = _FaseTeclado.demo;
      _indiceVocal = 0;
      _animacionTecladoTick++;
    });
    await _tts.interrupt();
    await _narrarDemoVocal();
  }

  Future<void> _narrarDemoVocal() async {
    await _ttsDecir('Así se encuentra la vocal ${_vocalActual.letra} en el teclado');
    await _ttsDecir(_vocalActual.ejemplo);
    await _ttsDecir('Mira la tecla resaltada');
  }

  Future<void> _irAPractica() async {
    _entradaController.clear();
    setState(() => _fase = _FaseTeclado.practica);
    await _tts.interrupt();
    await _ttsDecir('Ahora escribe la vocal ${_vocalActual.letra}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entradaFocus.requestFocus();
    });
  }

  void _onEntradaCambiada(String value) {
    final limpio = value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final uno = limpio.isEmpty ? '' : limpio[limpio.length - 1];
    if (_entradaController.text != uno) {
      _entradaController.value = TextEditingValue(
        text: uno,
        selection: TextSelection.collapsed(offset: uno.length),
      );
    }
  }

  Future<void> _evaluarPractica() async {
    final texto = _entradaController.text.trim().toUpperCase();
    final ok = texto == _vocalActual.letra;
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
      await _ttsDecir('Escribe la vocal ${_vocalActual.letra}');
      return;
    }
    if (_indiceVocal < _vocales.length - 1) {
      setState(() {
        _indiceVocal++;
        _fase = _FaseTeclado.demo;
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
    setState(() => _fase = _FaseTeclado.recompensa);
    await _ttsDecir('Excelente. Ya conoces las vocales en el teclado');
  }

  double _progresoLeccion() {
    const totalPasos = 12; // intro + 5 vocales × (demo + práctica) + recompensa
    var paso = 0;
    switch (_fase) {
      case _FaseTeclado.intro:
        paso = 0;
      case _FaseTeclado.demo:
        paso = 1 + _indiceVocal * 2;
      case _FaseTeclado.practica:
      case _FaseTeclado.feedback:
        paso = 2 + _indiceVocal * 2;
      case _FaseTeclado.recompensa:
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
        return 'Teclado · ${_vocalActual.letra}';
      case _FaseTeclado.practica:
        return 'Tu turno · ${_vocalActual.letra}';
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
        return _buildDemoTeclado();
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
        const Text(
          'Primer acercamiento al teclado',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Verás dónde está cada vocal en el teclado y luego la escribirás tú.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _ttsListo ? _empezarPrimeraVocal : null,
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
          '${_vocalActual.letra} · ${_vocalActual.ejemplo}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _vocalActual.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 52),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _TecladoVocalAnimado(
            key: ValueKey<int>(_animacionTecladoTick),
            vocalResaltada: _vocalActual.letra,
            filas: _filasTeclado,
            colorResaltado: _resaltadoTecla,
            fondoResaltado: _resaltadoFondo,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _rojoManta),
          onPressed: _irAPractica,
          child: const Text('Practicar esta vocal'),
        ),
      ],
    );
  }

  void _escribirLetraEnPractica(String letra) {
    final l = letra.toUpperCase();
    _entradaController.value = TextEditingValue(
      text: l,
      selection: TextSelection.collapsed(offset: l.length),
    );
    setState(() {});
    _entradaFocus.requestFocus();
  }

  Widget _buildPractica() {
    final tecladoSistemaVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Escribe la vocal ${_vocalActual.letra}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _vocalActual.ejemplo,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca la vocal en el teclado o escríbela en el recuadro',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.3,
          ),
        ),
        if (!tecladoSistemaVisible) ...[
          const SizedBox(height: 10),
          AlfabetizacionTecladoReferencia(
            teclasResaltadas: {_vocalActual.letra},
            filas: _filasTeclado,
            colorResaltado: _resaltadoTecla,
            fondoResaltado: _resaltadoFondo,
            opacidadReferencia: 0.45,
            onLetraTap: _escribirLetraEnPractica,
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 12),
        TextField(
          focusNode: _entradaFocus,
          controller: _entradaController,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _azulHorizonte,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: _vocalActual.letra,
            hintStyle: TextStyle(
              color: _azulHorizonte.withValues(alpha: 0.25),
            ),
            filled: true,
            fillColor: Colors.white,
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

/// Teclado con entrada animada y tecla de la vocal pulsando.
class _TecladoVocalAnimado extends StatefulWidget {
  const _TecladoVocalAnimado({
    super.key,
    required this.vocalResaltada,
    required this.filas,
    required this.colorResaltado,
    required this.fondoResaltado,
  });

  final String vocalResaltada;
  final List<List<String>> filas;
  final Color colorResaltado;
  final Color fondoResaltado;

  @override
  State<_TecladoVocalAnimado> createState() => _TecladoVocalAnimadoState();
}

class _TecladoVocalAnimadoState extends State<_TecladoVocalAnimado>
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
          child: AlfabetizacionTecladoReferencia(
            teclasResaltadas: {widget.vocalResaltada.toUpperCase()},
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
