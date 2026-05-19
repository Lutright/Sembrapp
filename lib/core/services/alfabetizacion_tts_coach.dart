import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Devuelve true si esta ruta es la visible (no hay otra encima en la pila).
///
/// Útil para cortar la narración al navegar: [State.mounted] sigue siendo true
/// cuando solo se ha hecho push y la pantalla queda debajo.
bool alfabetizacionTtsRouteActive(BuildContext context) {
  if (!context.mounted) return false;
  final route = ModalRoute.of(context);
  if (route == null) return true;
  return route.isCurrent;
}

/// Utilidad de TTS para guiar al usuario con frases cortas y repetibles.
///
/// Diseño:
/// - Cola serial para evitar superposición.
/// - "Generación" para invalidar audios pendientes al cambiar de pantalla/pregunta.
/// - [dispose] invalida todo lo encolado (evita que suene al salir).
/// - [speakSequence] corta si la generación cambia (p. ej. tras [interrupt]).
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
  bool _disposed = false;
  int _gen = 0;
  Future<void> _queue = Future.value();

  bool get isReady => _ready;

  Future<void> init() async {
    if (_disposed) return;
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
    if (_disposed) return;
    _disposed = true;
    _gen++;
    await _stopSafe();
  }

  Future<void> interrupt() async {
    if (_disposed) return;
    _gen++;
    await _stopSafe();
    await Future<void>.delayed(const Duration(milliseconds: 130));
  }

  Future<void> speak(
    String text, {
    bool slow = false,
    bool Function()? shouldContinue,
  }) async {
    final t = text.trim();
    if (!_ready || t.isEmpty || _disposed) return;
    if (shouldContinue != null && !shouldContinue()) {
      await interrupt();
      return;
    }
    await _enqueue((myGen) async {
      if (myGen != _gen) return;
      try {
        await _tts.setSpeechRate(slow ? rateSlow : rateNormal);
      } catch (_) {}
      if (myGen != _gen) return;
      await _speakSafe(t);
      if (myGen != _gen) return;
      try {
        await _tts.setSpeechRate(rateNormal);
      } catch (_) {}
    });
  }

  Future<void> speakSequence(
    List<String> parts, {
    Duration gap = const Duration(milliseconds: 380),
    bool Function()? shouldContinue,
  }) async {
    if (!_ready || _disposed) return;
    final chainId = _gen;
    bool ok() {
      if (_disposed || _gen != chainId) return false;
      if (shouldContinue == null) return true;
      return shouldContinue();
    }

    for (final p in parts) {
      if (!ok()) {
        if (!_disposed && _gen == chainId) await interrupt();
        return;
      }
      final t = p.trim();
      if (t.isEmpty) continue;
      await speak(t, shouldContinue: shouldContinue);
      if (!ok()) {
        if (!_disposed && _gen == chainId) await interrupt();
        return;
      }
      await Future<void>.delayed(gap);
    }
  }

  Future<void> _enqueue(Future<void> Function(int myGen) action) async {
    if (_disposed) return;
    final myGen = _gen;
    final done = Completer<void>();
    _queue = _queue.then((_) async {
      try {
        if (myGen != _gen || _disposed) return;
        await _stopSafe();
        await Future<void>.delayed(const Duration(milliseconds: 115));
        if (myGen != _gen || _disposed) return;
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
