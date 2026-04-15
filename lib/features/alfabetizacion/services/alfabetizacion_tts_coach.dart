import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Utilidad de TTS para guiar al usuario con frases cortas y repetibles.
///
/// Diseño:
/// - Cola serial para evitar superposición.
/// - "Generación" para invalidar audios pendientes al cambiar de pantalla/pregunta.
/// - Timeouts defensivos (algunos dispositivos se quedan colgados).
final class AlfabetizacionTtsCoach {
  AlfabetizacionTtsCoach({
    FlutterTts? tts,
    this.languagePrimary = 'es-ES',
    this.languageFallback = 'es-MX',
    this.rateNormal = 0.42,
    this.rateSlow = 0.30,
  }) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  final String languagePrimary;
  final String languageFallback;
  final double rateNormal;
  final double rateSlow;

  static const Duration _stopTimeout = Duration(milliseconds: 900);
  static const Duration _speakTimeout = Duration(seconds: 9);

  bool _ready = false;
  int _gen = 0;
  Future<void> _queue = Future.value();

  bool get isReady => _ready;

  Future<void> init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(languagePrimary);
      await _tts.setSpeechRate(rateNormal);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      try {
        await _tts.setLanguage(languageFallback);
      } catch (_) {}
    }
    _ready = true;
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> interrupt() async {
    _gen++;
    await _stopSafe();
    await Future<void>.delayed(const Duration(milliseconds: 130));
  }

  Future<void> speak(String text, {bool slow = false}) async {
    final t = text.trim();
    if (!_ready || t.isEmpty) return;
    await _enqueue((myGen) async {
      if (myGen != _gen) return;
      try {
        await _tts.setSpeechRate(slow ? rateSlow : rateNormal);
      } catch (_) {}
      if (myGen != _gen) return;
      await _speakSafe(t);
      // Regresa a normal por si el siguiente mensaje no especifica.
      try {
        await _tts.setSpeechRate(rateNormal);
      } catch (_) {}
    });
  }

  Future<void> speakSequence(
    List<String> parts, {
    Duration gap = const Duration(milliseconds: 380),
  }) async {
    if (!_ready) return;
    for (final p in parts) {
      final t = p.trim();
      if (t.isEmpty) continue;
      await speak(t);
      await Future<void>.delayed(gap);
    }
  }

  Future<void> _enqueue(Future<void> Function(int myGen) action) async {
    final myGen = _gen;
    final done = Completer<void>();
    _queue = _queue.then((_) async {
      try {
        if (myGen != _gen) return;
        await _stopSafe();
        await Future<void>.delayed(const Duration(milliseconds: 115));
        if (myGen != _gen) return;
        await action(myGen);
      } catch (_) {
      } finally {
        if (!done.isCompleted) done.complete();
      }
    });
    await done.future;
  }

  Future<void> _stopSafe() async {
    try {
      await _tts.stop().timeout(_stopTimeout);
    } catch (_) {}
  }

  Future<void> _speakSafe(String text) async {
    try {
      await _tts.speak(text).timeout(_speakTimeout);
    } catch (_) {}
  }
}

