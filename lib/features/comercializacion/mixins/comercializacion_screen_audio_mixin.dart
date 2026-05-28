import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/tutorial/tutorial_runner.dart';
import '../services/comercializacion_audio_guide.dart';
import '../widgets/comercializacion_audio_coach_bar.dart';

/// Audio guía reutilizable en pantallas de Comercialización (campesino).
mixin ComercializacionScreenAudio<T extends StatefulWidget> on State<T> {
  final ComercializacionAudioGuide audioGuide = ComercializacionAudioGuide();
  bool audioTtsListo = false;
  bool _audioAutoYa = false;
  bool audioNarrando = false;

  /// Override en pantallas con tutorial walkthrough (home, formulario producto).
  bool get audioGuideSuppressed => TutorialRunner.isShowing;

  Future<void> initComercializacionScreenAudio(List<String> welcomePhrases) async {
    try {
      await audioGuide.ensureReady();
    } catch (_) {}
    if (!mounted) return;
    setState(() => audioTtsListo = audioGuide.isReady);
    if (audioTtsListo && !_audioAutoYa) {
      _audioAutoYa = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(narrarEntradaComercializacion(welcomePhrases));
      });
    }
  }

  Future<void> narrarEntradaComercializacion(List<String> phrases) async {
    if (audioGuideSuppressed) return;
    if (!audioTtsListo || audioNarrando) return;
    setState(() => audioNarrando = true);
    try {
      await audioGuide.interrupt();
      if (!mounted) return;
      await audioGuide.speakSequence(context, phrases);
    } finally {
      if (mounted) setState(() => audioNarrando = false);
    }
  }

  Widget buildComercializacionAudioCoachBar({VoidCallback? onRepeat}) {
    return ComercializacionAudioCoachBar(
      listo: audioTtsListo,
      narrando: audioNarrando,
      enabled: !audioGuideSuppressed,
      onRepeat: onRepeat ?? () => unawaited(narrarEntradaComercializacion([])),
    );
  }

  /// Coach bar con frases de bienvenida conocidas (evita pasar lista vacía por error).
  Widget buildComercializacionAudioCoachBarFor(
    List<String> welcomePhrases,
  ) {
    return ComercializacionAudioCoachBar(
      listo: audioTtsListo,
      narrando: audioNarrando,
      enabled: !audioGuideSuppressed,
      onRepeat: () => unawaited(narrarEntradaComercializacion(welcomePhrases)),
    );
  }

  Future<void> audioSpeakAction(String phrase) async {
    if (audioGuideSuppressed) return;
    await audioGuide.interruptAndSpeak(context, phrase);
  }
}
