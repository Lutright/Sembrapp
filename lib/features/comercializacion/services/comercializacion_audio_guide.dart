import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../../../core/tutorial/tutorial_runner.dart';
import '../../../core/tutorial/tutorial_service.dart';

/// Guía por voz para Comercialización (campesino).
///
/// Reutiliza el mismo motor TTS del tutorial (TutorialService.ttsCoach) para
/// evitar instancias múltiples de FlutterTts y para que el audio sea consistente.
final class ComercializacionAudioGuide {
  ComercializacionAudioGuide();

  AlfabetizacionTtsCoach get _tts => TutorialService.instance.ttsCoach;

  bool get isReady => _tts.isReady;

  /// El tutorial usa la misma voz. Si el walkthrough está activo, evitamos
  /// hablar desde la pantalla para no interrumpirlo ni competir.
  bool canSpeakWhileTutorialInactive({
    bool tutorialStepsActive = false,
  }) {
    return !TutorialRunner.isShowing && !tutorialStepsActive;
  }

  Future<void> ensureReady() async {
    await TutorialService.instance.ensureTtsReady();
  }

  Future<void> interrupt() => TutorialService.instance.interruptTts();

  Future<void> speak(
    BuildContext context,
    String text, {
    bool slow = false,
    bool tutorialStepsActive = false,
  }) async {
    if (!canSpeakWhileTutorialInactive(tutorialStepsActive: tutorialStepsActive)) {
      return;
    }
    await ensureReady();
    await _tts.speak(
      text,
      slow: slow,
      shouldContinue: () =>
          context.mounted && alfabetizacionTtsRouteActive(context),
    );
  }

  Future<void> speakSequence(
    BuildContext context,
    List<String> parts, {
    Duration gap = const Duration(milliseconds: 380),
    bool tutorialStepsActive = false,
  }) async {
    if (!canSpeakWhileTutorialInactive(tutorialStepsActive: tutorialStepsActive)) {
      return;
    }
    await ensureReady();
    await _tts.speakSequence(
      parts,
      gap: gap,
      shouldContinue: () =>
          context.mounted && alfabetizacionTtsRouteActive(context),
    );
  }

  /// Helper para acciones: corta la voz anterior y habla una frase corta.
  Future<void> interruptAndSpeak(
    BuildContext context,
    String text, {
    bool slow = false,
    bool tutorialStepsActive = false,
  }) async {
    if (!canSpeakWhileTutorialInactive(tutorialStepsActive: tutorialStepsActive)) {
      return;
    }
    await ensureReady();
    await interrupt();
    if (!context.mounted) return;
    await speak(
      context,
      text,
      slow: slow,
      tutorialStepsActive: tutorialStepsActive,
    );
  }
}

