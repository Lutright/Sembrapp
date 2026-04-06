import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';

/// Flujo en 6 etapas para la lección Vocales: intro → presentación → práctica →
/// actividad (con retroalimentación) → recompensa. Audio con TTS en español.
class VocalesLeccionFlow extends StatefulWidget {
  const VocalesLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;

  @override
  State<VocalesLeccionFlow> createState() => _VocalesLeccionFlowState();
}

class _VocalPaso {
  const _VocalPaso({
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

  /// Texto que ve el usuario (pregunta clara).
  final String textoPregunta;

  /// Lo que dice la voz al presentar y al repetir tras un fallo.
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

class _VocalesLeccionFlowState extends State<VocalesLeccionFlow>
    with SingleTickerProviderStateMixin {
  static const _vocales = <_VocalPaso>[
    _VocalPaso(letra: 'A', deEjemplo: 'A de árbol', emoji: '🌳'),
    _VocalPaso(letra: 'E', deEjemplo: 'E de escoba', emoji: '🧹'),
    _VocalPaso(letra: 'I', deEjemplo: 'I de iguana', emoji: '🦎'),
    _VocalPaso(letra: 'O', deEjemplo: 'O de oveja', emoji: '🐑'),
    _VocalPaso(letra: 'U', deEjemplo: 'U de uva', emoji: '🍇'),
  ];

  static const _ejercicios = <_EjercicioActividad>[
    _EjercicioActividad(
      textoPregunta: 'Selecciona la letra A',
      audioInstruccion: 'Selecciona la letra A',
      opciones: ['A', 'E', 'O'],
      correcta: 'A',
      emojiIlustracion: '🌳',
    ),
    _EjercicioActividad(
      textoPregunta: '¿Cuál es la letra O?',
      audioInstruccion: '¿Cuál es la O?',
      opciones: ['U', 'O', 'I'],
      correcta: 'O',
      emojiIlustracion: '🐑',
    ),
    _EjercicioActividad(
      textoPregunta: '¿Con qué letra empieza esta palabra?',
      audioInstruccion: '¿Con qué letra empieza la palabra oveja?',
      opciones: ['A', 'O', 'E'],
      correcta: 'O',
      emojiIlustracion: '🐑',
    ),
  ];

  static const double _ttsRateNormal = 0.42;
  static const double _ttsRateLetra = 0.26;
  static const Duration _ttsStopTimeout = Duration(milliseconds: 900);
  static const Duration _ttsSpeakTimeout = Duration(seconds: 7);

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _ttsListo = false;
  bool _introAudioYa = false;
  bool _progresoGuardado = false;

  /// Invalida audios encolados al cambiar de pantalla / avanzar antes de que termine la voz.
  int _ttsGen = 0;
  Future<void> _ttsQueue = Future.value();

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

  bool _speechDisponible = false;
  bool _escuchandoVoz = false;
  String? _localeIdVoz;
  String _ultimoReconocido = '';

  _Fase _fase = _Fase.intro;
  int _indicePresentacion = 0;
  int _indicePractica = 0;
  int _indiceEjercicio = 0;

  bool _actividadBloqueada = false;
  bool _mostrarMuyBien = false;
  bool _mostrarIntentaDeNuevo = false;

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
    _inicializarSpeech();
  }

  Future<void> _inicializarSpeech() async {
    if (kIsWeb) return;
    try {
      final ok = await _speech.initialize(
        onStatus: (status) {
          if (status == stt.SpeechToText.doneStatus ||
              status == stt.SpeechToText.notListeningStatus) {
            if (mounted) setState(() => _escuchandoVoz = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _escuchandoVoz = false);
        },
      );
      if (!ok || !mounted) return;
      final locales = await _speech.locales();
      setState(() {
        _speechDisponible = true;
        _localeIdVoz = _elegirLocaleEspanol(locales);
      });
    } catch (_) {
      if (mounted) setState(() => _speechDisponible = false);
    }
  }

  String? _elegirLocaleEspanol(List<stt.LocaleName> locales) {
    final es = locales
        .where((l) => l.localeId.toLowerCase().startsWith('es'))
        .toList();
    if (es.isEmpty) return null;
    const preferidos = ['es_ES', 'es_MX', 'es_AR', 'es_CO'];
    for (final id in preferidos) {
      for (final l in es) {
        if (l.localeId == id) return l.localeId;
      }
    }
    return es.first.localeId;
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

  /// Para el motor TTS y deja un margen antes del siguiente [speak] (evita audios en silencio en Android).
  Future<void> _ttsInterrumpir() async {
    _ttsGen++;
    await _ttsStopSeguro();
    await Future<void>.delayed(const Duration(milliseconds: 130));
  }

  /// Ejecuta un bloque de TTS en serie; si el usuario avanza, [miGen] deja de coincidir y se omite.
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

  /// Nombre claro de la vocal (el motor suele fallar o confundir la «E» suelta).
  Future<void> _hablarLetraVocal(String letra) async {
    if (!_ttsListo || letra.isEmpty) return;
    final texto = 'Vocal $letra';
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
    await _hablar('Vamos a aprender las vocales');
    if (!mounted || _fase != _Fase.intro) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _fase != _Fase.intro) return;
    await _hablar('Pulsa el botón verde para empezar');
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    if (_speechDisponible) {
      try {
        unawaited(_speech.stop());
      } catch (_) {}
    }
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
        return 'Pantalla 2 · Las vocales (${_indicePresentacion + 1} de ${_vocales.length})';
      case _Fase.practica:
        return 'Pantalla 3 · Práctica guiada (${_indicePractica + 1} de ${_vocales.length})';
      case _Fase.actividad:
        return 'Pantalla 4 · Actividad (${_indiceEjercicio + 1} de ${_ejercicios.length})';
      case _Fase.recompensa:
        return 'Pantalla 6 · Recompensa';
    }
  }

  Future<void> _anunciarInstruccionesPresentacion() async {
    final v = _vocales[_indicePresentacion];
    await _hablar(v.deEjemplo);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.presentacion) return;
    await _hablar('Pulsa el botón blanco para escuchar la vocal');
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

  Future<void> _repetirSonidoVocalPresentacion() async {
    await _hablarLetraVocal(_vocales[_indicePresentacion].letra);
  }

  Future<void> _siguientePresentacion() async {
    await _ttsInterrumpir();
    if (!mounted) return;
    if (_indicePresentacion < _vocales.length - 1) {
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
    // [_siguientePresentacion] / [_siguientePractica] ya llamaron a [_ttsInterrumpir].
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Escucha y repite');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablarLetraVocal(_vocales[_indicePractica].letra);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Pulsa el botón blanco para escuchar de nuevo');
    if (_speechDisponible) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _fase != _Fase.practica) return;
      await _hablar(
        'Pulsa el botón del micrófono, di la vocal en voz alta y espera un momento',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _fase != _Fase.practica) return;
    await _hablar('Pulsa el botón verde para continuar');
  }

  Future<void> _repetirPractica() async {
    await _hablarLetraVocal(_vocales[_indicePractica].letra);
  }

  Future<void> _tocarLetraPractica() async {
    await _hablarLetraVocal(_vocales[_indicePractica].letra);
  }

  bool _textoCoincideConVocal(String reconocido, String letra) {
    final L = letra.toUpperCase().trim();
    if (L.isEmpty) return false;
    var t = reconocido.toUpperCase().trim();
    t = t.replaceAll(RegExp('[^A-ZÁÉÍÓÚÑ\\s]'), '');
    if (t.isEmpty) return false;
    if (t == L) return true;
    final partes = t.split(RegExp('\\s+'));
    if (partes.any((p) => p == L)) return true;
    if (partes.contains('VOCAL') && partes.any((p) => p == L)) return true;
    if (t.length == 1 && t == L) return true;
    return false;
  }

  void _onResultadoVozPractica(SpeechRecognitionResult result) {
    if (!result.finalResult) {
      if (mounted) {
        setState(() => _ultimoReconocido = result.recognizedWords);
      }
      return;
    }
    unawaited(_evaluarVozPractica(result.recognizedWords));
  }

  Future<void> _evaluarVozPractica(String palabras) async {
    if (!mounted) return;
    setState(() {
      _escuchandoVoz = false;
      _ultimoReconocido = palabras;
    });
    try {
      await _speech.stop();
    } catch (_) {}
    if (palabras.trim().isEmpty) {
      await _hablar('No te escuché bien. Intenta otra vez.');
      return;
    }
    final letra = _vocales[_indicePractica].letra;
    if (_textoCoincideConVocal(palabras, letra)) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      await _hablar('¡Muy bien!');
    } else {
      await _hablar('Intenta otra vez. Di la vocal $letra.');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _fase != _Fase.practica) return;
      await _hablarLetraVocal(letra);
    }
  }

  Future<void> _pulsarMicrofonoPractica() async {
    if (!_speechDisponible) {
      await _hablar(
        'En este aparato no está disponible el micrófono. Pulsa el botón blanco para escuchar.',
      );
      return;
    }
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      return;
    }
    await _ttsInterrumpir();
    setState(() {
      _escuchandoVoz = true;
      _ultimoReconocido = '';
    });
    try {
      await _speech.listen(
        onResult: _onResultadoVozPractica,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        localeId: _localeIdVoz,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _escuchandoVoz = false);
      await _hablar('No se pudo usar el micrófono. Intenta de nuevo.');
    }
  }

  Future<void> _siguientePractica() async {
    await _ttsInterrumpir();
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _escuchandoVoz = false);
    if (_indicePractica < _vocales.length - 1) {
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

  /// Repite consigna completa tras un fallo (voz automática).
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
        });
        await _hablarInstruccionEjercicio();
      } else {
        await _finalizarConRecompensa();
      }
    } else {
      setState(() => _mostrarIntentaDeNuevo = true);
      await _hablar('Intenta de nuevo');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || _fase != _Fase.actividad) return;
      await _repetirPreguntaActividadPorVoz();
      if (mounted) {
        setState(() => _mostrarIntentaDeNuevo = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leccion.titulo),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          style: IconButton.styleFrom(
            minimumSize: const Size(kMinimalTouchTarget, kMinimalTouchTarget),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
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
            child: SingleChildScrollView(
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
                    Icons.agriculture_rounded,
                    size: 96,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.nature_people_rounded,
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
          'Vamos a aprender las vocales',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Botón verde: empezar. Botón blanco: escuchar. Sigue la voz.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _ttsListo ? _empezarPresentacion : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          child: const Text('Empezar'),
        ),
        if (!_ttsListo) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildPresentacion(BuildContext context) {
    final v = _vocales[_indicePresentacion];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vocal ${v.letra}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 20),
        Text(
          v.letra,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 96,
                height: 1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          v.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 88),
        ),
        const SizedBox(height: 8),
        Text(
          v.deEjemplo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: _repetirSonidoVocalPresentacion,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Escuchar la vocal (botón blanco)'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _siguientePresentacion,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(
            _indicePresentacion < _vocales.length - 1
                ? 'Siguiente vocal (botón verde)'
                : 'Ir a la práctica (botón verde)',
          ),
        ),
      ],
    );
  }

  Widget _buildPractica(BuildContext context) {
    final v = _vocales[_indicePractica];
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
          'Toca la letra, el botón blanco o el micrófono.',
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
                v.letra,
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
        if (_speechDisponible && !kIsWeb) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _pulsarMicrofonoPractica,
            icon: Icon(_escuchandoVoz ? Icons.mic_rounded : Icons.mic_none_rounded),
            label: Text(
              _escuchandoVoz ? 'Toca otra vez para terminar' : 'Micrófono: di la vocal',
            ),
          ),
          if (_ultimoReconocido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Escuché: $_ultimoReconocido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        FilledButton.tonalIcon(
          onPressed: _repetirPractica,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Escuchar otra vez (botón blanco)'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _siguientePractica,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(
            _indicePractica < _vocales.length - 1
                ? 'Siguiente (botón verde)'
                : 'Ir a la actividad (botón verde)',
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
                child: FilledButton.tonal(
                  onPressed: _actividadBloqueada
                      ? null
                      : () => _elegirOpcionActividad(ej.opciones[i]),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(ej.opciones[i]),
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.emoji_events_rounded, size: 80, color: scheme.tertiary),
        const SizedBox(height: 16),
        Text(
          'Completaste la lección',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          '🏆 +${widget.leccion.puntos} puntos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '⭐ Progreso: 10%',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Volver (botón verde)'),
        ),
      ],
    );
  }
}
