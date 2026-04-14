import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../data/lecciones_data.dart';

/// Flujo en 6 etapas para la lección Abecedario: intro → presentación →
/// práctica → actividad (con retroalimentación) → recompensa.
class AbecedarioLeccionFlow extends StatefulWidget {
  const AbecedarioLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<AbecedarioLeccionFlow> createState() => _AbecedarioLeccionFlowState();
}

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.06,
        0,
        size.height * 0.78,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LetraPaso {
  const _LetraPaso({
    required this.letra,
    required this.deEjemplo,
    required this.emoji,
  });

  final String letra;
  final String deEjemplo;
  final String emoji;
}

class _EjercicioActividad {
  const _EjercicioActividad({
    required this.textoPregunta,
    required this.audioInstruccion,
    required this.opciones,
    required this.correcta,
    required this.emojiIlustracion,
  });

  final String textoPregunta;
  final String audioInstruccion;
  final List<String> opciones;
  final String correcta;
  final String emojiIlustracion;
}

enum _Fase {
  intro,
  presentacion,
  practica,
  actividad,
  recompensa,
}

class _AbecedarioLeccionFlowState extends State<AbecedarioLeccionFlow>
    with SingleTickerProviderStateMixin {
  static const Color _azulHorizonte = Color(0xFF1A4463);
  static const Color _rojoManta = Color(0xFFD34836);
  static const Color _ocrePremium = Color(0xFFE8D48B);
  static const Color _ocrePremiumOscuro = Color(0xFF8B6914);
  static const _abecedario = <_LetraPaso>[
    _LetraPaso(letra: 'A', deEjemplo: 'A de árbol', emoji: '🌳'),
    _LetraPaso(letra: 'B', deEjemplo: 'B de burro', emoji: '🐴'),
    _LetraPaso(letra: 'C', deEjemplo: 'C de casa', emoji: '🏠'),
    _LetraPaso(letra: 'D', deEjemplo: 'D de dado', emoji: '🎲'),
    _LetraPaso(letra: 'E', deEjemplo: 'E de escoba', emoji: '🧹'),
    _LetraPaso(letra: 'F', deEjemplo: 'F de flor', emoji: '🌼'),
    _LetraPaso(letra: 'G', deEjemplo: 'G de gato', emoji: '🐱'),
    _LetraPaso(letra: 'H', deEjemplo: 'H de hoja', emoji: '🍃'),
    _LetraPaso(letra: 'I', deEjemplo: 'I de iguana', emoji: '🦎'),
    _LetraPaso(letra: 'J', deEjemplo: 'J de jirafa', emoji: '🦒'),
    _LetraPaso(letra: 'K', deEjemplo: 'K de kiwi', emoji: '🥝'),
    _LetraPaso(letra: 'L', deEjemplo: 'L de luna', emoji: '🌙'),
    _LetraPaso(letra: 'M', deEjemplo: 'M de mano', emoji: '✋'),
    _LetraPaso(letra: 'N', deEjemplo: 'N de nube', emoji: '☁️'),
    _LetraPaso(letra: 'Ñ', deEjemplo: 'Ñ de ñandú', emoji: '🐦'),
    _LetraPaso(letra: 'O', deEjemplo: 'O de oveja', emoji: '🐑'),
    _LetraPaso(letra: 'P', deEjemplo: 'P de perro', emoji: '🐶'),
    _LetraPaso(letra: 'Q', deEjemplo: 'Q de queso', emoji: '🧀'),
    _LetraPaso(letra: 'R', deEjemplo: 'R de rana', emoji: '🐸'),
    _LetraPaso(letra: 'S', deEjemplo: 'S de sol', emoji: '☀️'),
    _LetraPaso(letra: 'T', deEjemplo: 'T de tomate', emoji: '🍅'),
    _LetraPaso(letra: 'U', deEjemplo: 'U de uva', emoji: '🍇'),
    _LetraPaso(letra: 'V', deEjemplo: 'V de vaca', emoji: '🐄'),
    _LetraPaso(letra: 'W', deEjemplo: 'W de wifi', emoji: '📶'),
    _LetraPaso(letra: 'X', deEjemplo: 'X de xilófono', emoji: '🎼'),
    _LetraPaso(letra: 'Y', deEjemplo: 'Y de yoyo', emoji: '🪀'),
    _LetraPaso(letra: 'Z', deEjemplo: 'Z de zapato', emoji: '👟'),
  ];

  static const _ejercicios = <_EjercicioActividad>[
    _EjercicioActividad(
      textoPregunta: 'Selecciona la letra B',
      audioInstruccion: 'Selecciona la letra B',
      opciones: ['B', 'D', 'E'],
      correcta: 'B',
      emojiIlustracion: '🐴',
    ),
    _EjercicioActividad(
      textoPregunta: '¿Qué letra va después de M?',
      audioInstruccion: '¿Qué letra va después de M?',
      opciones: ['N', 'P', 'L'],
      correcta: 'N',
      emojiIlustracion: '☁️',
    ),
    _EjercicioActividad(
      textoPregunta: 'Selecciona la letra Ñ',
      audioInstruccion: 'Selecciona la letra Ñ',
      opciones: ['N', 'Ñ', 'M'],
      correcta: 'Ñ',
      emojiIlustracion: '🐦',
    ),
  ];

  static const double _ttsRateNormal = 0.42;
  static const double _ttsRateLetra = 0.26;
  static const Duration _ttsStopTimeout = Duration(milliseconds: 900);
  static const Duration _ttsSpeakTimeout = Duration(seconds: 7);

  final FlutterTts _tts = FlutterTts();

  bool _ttsListo = false;
  bool _introAudioYa = false;
  bool _progresoGuardado = false;

  int _ttsGen = 0;
  Future<void> _ttsQueue = Future.value();

  _Fase _fase = _Fase.intro;
  int _indicePresentacion = 0;
  int _indicePractica = 0;
  int _indiceEjercicio = 0;

  bool _actividadBloqueada = false;
  bool _mostrarMuyBien = false;
  bool _mostrarIntentaDeNuevo = false;
  String? _opcionActividadSeleccionada;
  bool? _opcionActividadFueCorrecta;

  late final AnimationController _celebracionCtrl;
  late final Animation<double> _celebracionScale;

  @override
  void initState() {
    super.initState();
    _celebracionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebracionScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _celebracionCtrl, curve: Curves.elasticOut),
    );
    _inicializarTts();
  }

  Future<void> _inicializarTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(_ttsRateNormal);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      try {
        await _tts.setLanguage('es-MX');
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _ttsListo = true);
    await _reproducirIntroSiCorresponde();
  }

  Future<void> _ttsStopSeguro() async {
    try {
      await _tts.stop().timeout(_ttsStopTimeout);
    } catch (_) {}
  }

  Future<void> _ttsSpeakSeguro(String texto) async {
    try {
      await _tts.speak(texto).timeout(_ttsSpeakTimeout);
    } catch (_) {}
  }

  Future<void> _ttsInterrumpir() async {
    _ttsGen++;
    await _ttsStopSeguro();
    await Future<void>.delayed(const Duration(milliseconds: 130));
  }

  Future<void> _ttsEncolar(Future<void> Function(int miGen) accion) async {
    if (!_ttsListo) return;
    final miGen = _ttsGen;
    final hecho = Completer<void>();
    _ttsQueue = _ttsQueue.then((_) async {
      try {
        if (miGen != _ttsGen) return;
        await _ttsStopSeguro();
        await Future<void>.delayed(const Duration(milliseconds: 115));
        if (miGen != _ttsGen) return;
        await accion(miGen);
      } catch (_) {
      } finally {
        if (!hecho.isCompleted) hecho.complete();
      }
    });
    await hecho.future;
  }

  Future<void> _hablar(String texto) async {
    if (!_ttsListo || texto.isEmpty) return;
    await _ttsEncolar((miGen) async {
      if (miGen != _ttsGen) return;
      await _tts.setSpeechRate(_ttsRateNormal);
      if (miGen != _ttsGen) return;
      await _ttsSpeakSeguro(texto);
    });
  }

  Future<void> _hablarLetra(String letra) async {
    if (!_ttsListo || letra.isEmpty) return;
    final texto = 'Letra $letra';
    await _ttsEncolar((miGen) async {
      try {
        if (miGen != _ttsGen) return;
        await _tts.setSpeechRate(_ttsRateLetra);
        if (miGen != _ttsGen) return;
        await _ttsSpeakSeguro(texto);
      } finally {
        try {
          await _tts.setSpeechRate(_ttsRateNormal);
        } catch (_) {}
      }
    });
  }

  Future<void> _reproducirIntroSiCorresponde() async {
    if (_introAudioYa || _fase != _Fase.intro) return;
    _introAudioYa = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.intro) return;
    await _hablar('Vamos a aprender el abecedario');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _fase != _Fase.intro) return;
    await _hablar('Pulsa el botón verde para empezar');
  }

  Future<void> _escucharIntroduccion() async {
    if (!_ttsListo) return;
    await _ttsInterrumpir();
    await _hablar('Vamos a aprender el abecedario');
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    _celebracionCtrl.dispose();
    super.dispose();
  }

  double get _progresoLineal {
    switch (_fase) {
      case _Fase.intro:
        return 1 / 6;
      case _Fase.presentacion:
        return 2 / 6;
      case _Fase.practica:
        return 3 / 6;
      case _Fase.actividad:
        final fraccion = (_indiceEjercicio + 1) / _ejercicios.length;
        return 4 / 6 + fraccion * (1 / 6);
      case _Fase.recompensa:
        return 1;
    }
  }

  String get _etiquetaPaso {
    switch (_fase) {
      case _Fase.intro:
        return 'Pantalla 1 · Introducción';
      case _Fase.presentacion:
        return 'Pantalla 2 · El abecedario (${_indicePresentacion + 1} de ${_abecedario.length})';
      case _Fase.practica:
        return 'Pantalla 3 · Práctica guiada (${_indicePractica + 1} de ${_abecedario.length})';
      case _Fase.actividad:
        return 'Pantalla 4 · Actividad (${_indiceEjercicio + 1} de ${_ejercicios.length})';
      case _Fase.recompensa:
        return 'Pantalla 6 · Recompensa';
    }
  }

  Future<void> _anunciarInstruccionesPresentacion() async {
    final l = _abecedario[_indicePresentacion];
    await _hablar(l.deEjemplo);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.presentacion) return;
    await _hablar('Pulsa el botón blanco para escuchar la letra');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.presentacion) return;
    await _hablar('Pulsa el botón verde para continuar');
  }

  Future<void> _empezarPresentacion() async {
    await _ttsInterrumpir();
    if (!mounted) return;
    setState(() {
      _fase = _Fase.presentacion;
      _indicePresentacion = 0;
    });
    await _anunciarInstruccionesPresentacion();
  }

  Future<void> _repetirSonidoLetraPresentacion() async {
    await _hablarLetra(_abecedario[_indicePresentacion].letra);
  }

  Future<void> _siguientePresentacion() async {
    await _ttsInterrumpir();
    if (!mounted) return;
    if (_indicePresentacion < _abecedario.length - 1) {
      setState(() => _indicePresentacion++);
      await _anunciarInstruccionesPresentacion();
    } else {
      setState(() {
        _fase = _Fase.practica;
        _indicePractica = 0;
      });
      await _entradaPracticaActual();
    }
  }

  Future<void> _entradaPracticaActual() async {
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Escucha y repite');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablarLetra(_abecedario[_indicePractica].letra);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Pulsa el botón blanco para escuchar de nuevo');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Pulsa el botón verde para continuar');
  }

  Future<void> _repetirPractica() async {
    await _hablarLetra(_abecedario[_indicePractica].letra);
  }

  Future<void> _tocarLetraPractica() async {
    await _hablarLetra(_abecedario[_indicePractica].letra);
  }

  Future<void> _siguientePractica() async {
    await _ttsInterrumpir();
    if (!mounted) return;
    if (_indicePractica < _abecedario.length - 1) {
      setState(() => _indicePractica++);
      await _entradaPracticaActual();
    } else {
      setState(() {
        _fase = _Fase.actividad;
        _indiceEjercicio = 0;
        _actividadBloqueada = false;
        _mostrarMuyBien = false;
      });
      await _hablarInstruccionEjercicio();
    }
  }

  Future<void> _hablarInstruccionEjercicio() async {
    final ej = _ejercicios[_indiceEjercicio];
    await _hablar('Selecciona la respuesta correcta');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _fase != _Fase.actividad) return;
    await _hablar(ej.audioInstruccion);
  }

  Future<void> _repetirPreguntaActividadPorVoz() async {
    await _hablarInstruccionEjercicio();
  }

  Future<void> _elegirOpcionActividad(String opcion) async {
    if (_actividadBloqueada || _fase != _Fase.actividad) return;
    final ej = _ejercicios[_indiceEjercicio];
    if (opcion == ej.correcta) {
      setState(() {
        _actividadBloqueada = true;
        _mostrarMuyBien = true;
        _opcionActividadSeleccionada = opcion;
        _opcionActividadFueCorrecta = true;
      });
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      await _hablar('¡Muy bien!');
      if (!mounted) return;
      await _celebracionCtrl.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      if (_indiceEjercicio < _ejercicios.length - 1) {
        setState(() {
          _indiceEjercicio++;
          _actividadBloqueada = false;
          _mostrarMuyBien = false;
          _opcionActividadSeleccionada = null;
          _opcionActividadFueCorrecta = null;
        });
        await _hablarInstruccionEjercicio();
      } else {
        await _finalizarConRecompensa();
      }
    } else {
      setState(() {
        _mostrarIntentaDeNuevo = true;
        _opcionActividadSeleccionada = opcion;
        _opcionActividadFueCorrecta = false;
      });
      await _hablar('Intenta de nuevo');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || _fase != _Fase.actividad) return;
      await _repetirPreguntaActividadPorVoz();
      if (mounted) {
        setState(() {
          _mostrarIntentaDeNuevo = false;
          _opcionActividadSeleccionada = null;
          _opcionActividadFueCorrecta = null;
        });
      }
    }
  }

  Future<void> _repetirAudioEjercicio() async {
    await _repetirPreguntaActividadPorVoz();
  }

  Future<void> _finalizarConRecompensa() async {
    if (!_progresoGuardado) {
      _progresoGuardado = true;
      await widget.onCompletar();
    }
    if (!mounted) return;
    setState(() {
      _fase = _Fase.recompensa;
      _mostrarMuyBien = false;
      _actividadBloqueada = false;
    });
    await _hablar('Completaste la lección. Muy bien.');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await _hablar('Pulsa el botón verde para volver');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tituloModulo =
        widget.leccion.modulo == 'lectura' ? 'Lectura' : 'Escritura';
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value: _progresoLineal,
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _etiquetaPaso,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _fase == _Fase.recompensa
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                child: KeyedSubtree(
                                  key: ValueKey(
                                    (_fase, _indicePresentacion, _indicePractica, _indiceEjercicio),
                                  ),
                                  child: _cuerpoFase(context),
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              child: KeyedSubtree(
                                key: ValueKey(
                                  (_fase, _indicePresentacion, _indicePractica, _indiceEjercicio),
                                ),
                                child: _cuerpoFase(context),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: _azulHorizonte),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.leccion.titulo,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$tituloModulo · Nivel ${widget.leccion.nivel}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpoFase(BuildContext context) {
    switch (_fase) {
      case _Fase.intro:
        return _buildIntro(context);
      case _Fase.presentacion:
        return _buildPresentacion(context);
      case _Fase.practica:
        return _buildPractica(context);
      case _Fase.actividad:
        return _buildActividad(context);
      case _Fase.recompensa:
        return _buildRecompensa(context);
    }
  }

  Widget _buildIntro(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.85),
                    scheme.tertiaryContainer.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    size: 96,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones_rounded, color: scheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Audio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Vamos a aprender el abecedario',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _ttsListo ? _escucharIntroduccion : null,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Escuchar introducción'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _azulHorizonte, width: 1.5),
            foregroundColor: _azulHorizonte,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: const StadiumBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _ttsListo ? _empezarPresentacion : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          child: const Text('Empezar lección'),
        ),
        if (!_ttsListo) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildPresentacion(BuildContext context) {
    final l = _abecedario[_indicePresentacion];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Letra ${l.letra}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 20),
        Text(
          l.letra,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 96,
                height: 1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 88),
        ),
        const SizedBox(height: 8),
        Text(
          l.deEjemplo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _repetirSonidoLetraPresentacion,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Escuchar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _azulHorizonte, width: 1.5),
            foregroundColor: _azulHorizonte,
            shape: const StadiumBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _siguientePresentacion,
          style: FilledButton.styleFrom(
            backgroundColor: _rojoManta,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: Text(
            _indicePresentacion < _abecedario.length - 1
                ? 'Siguiente'
                : 'Ir a la práctica',
          ),
        ),
      ],
    );
  }

  Widget _buildPractica(BuildContext context) {
    final l = _abecedario[_indicePractica];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escucha y repite',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca la letra o el botón blanco.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 28),
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _tocarLetraPractica,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Text(
                l.letra,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 110,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _repetirPractica,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Escuchar otra vez'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _azulHorizonte, width: 1.5),
            foregroundColor: _azulHorizonte,
            shape: const StadiumBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _siguientePractica,
          style: FilledButton.styleFrom(
            backgroundColor: _rojoManta,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: Text(
            _indicePractica < _abecedario.length - 1
                ? 'Siguiente'
                : 'Ir a la actividad',
          ),
        ),
      ],
    );
  }

  Widget _buildActividad(BuildContext context) {
    final ej = _ejercicios[_indiceEjercicio];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mostrarMuyBien) ...[
          ScaleTransition(
            scale: _celebracionScale,
            child: Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.celebration_rounded, size: 56, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      '¡Muy bien!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_mostrarIntentaDeNuevo) ...[
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Intenta de nuevo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Selecciona la respuesta correcta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Text(
                  ej.emojiIlustracion,
                  style: const TextStyle(fontSize: 96),
                ),
                const SizedBox(height: 16),
                Text(
                  ej.textoPregunta,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            for (var i = 0; i < ej.opciones.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _actividadBloqueada
                      ? null
                      : () => _elegirOpcionActividad(ej.opciones[i]),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    side: BorderSide(
                      color: _colorBordeOpcionActividad(ej.opciones[i]),
                      width: 1.5,
                    ),
                    backgroundColor: _colorFondoOpcionActividad(ej.opciones[i]),
                    foregroundColor: _colorTextoOpcionActividad(ej.opciones[i]),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: _buildLabelOpcionActividad(ej.opciones[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _actividadBloqueada ? null : _repetirAudioEjercicio,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Repetir la pregunta con voz'),
        ),
      ],
    );
  }

  Widget _buildRecompensa(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _ocrePremium.withOpacity(0.20),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                'Completaste la lección',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${widget.leccion.puntos} puntos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ocrePremiumOscuro,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _azulHorizonte.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: _ocrePremium,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progreso del módulo: 10%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(
            backgroundColor: _rojoManta,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
          ),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Color _colorFondoOpcionActividad(String opcion) {
    if (_opcionActividadSeleccionada != opcion) return Colors.white;
    final ok = _opcionActividadFueCorrecta;
    if (ok == true) return Colors.green.shade100;
    if (ok == false) return _rojoManta.withOpacity(0.10);
    return Colors.white;
  }

  Color _colorBordeOpcionActividad(String opcion) {
    if (_opcionActividadSeleccionada != opcion) return _azulHorizonte;
    final ok = _opcionActividadFueCorrecta;
    if (ok == true) return Colors.green.shade700;
    if (ok == false) return _rojoManta;
    return _azulHorizonte;
  }

  Color _colorTextoOpcionActividad(String opcion) {
    if (_opcionActividadSeleccionada != opcion) return _azulHorizonte;
    final ok = _opcionActividadFueCorrecta;
    if (ok == true) return Colors.green.shade800;
    if (ok == false) return _rojoManta;
    return _azulHorizonte;
  }

  Widget _buildLabelOpcionActividad(String opcion) {
    if (_opcionActividadSeleccionada != opcion) return Text(opcion);
    final ok = _opcionActividadFueCorrecta;
    if (ok == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 20),
          const SizedBox(width: 6),
          Text(opcion),
        ],
      );
    }
    if (ok == false) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, size: 20),
          const SizedBox(width: 6),
          Text(opcion),
        ],
      );
    }
    return Text(opcion);
  }
}
