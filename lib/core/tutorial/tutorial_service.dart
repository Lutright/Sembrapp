import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/alfabetizacion_tts_coach.dart';
import 'models/tutorial_step.dart';
import 'tutorial_sync_repository.dart';

/// Estado global del tutorial: local primero, sync con Supabase cuando hay sesión.
final class TutorialService {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  static const String _prefsDonePrefix = 'tutorial_done::';
  static const String _prefsSkipPrefix = 'tutorial_flow_skipped::';

  SharedPreferences? _prefs;
  SupabaseClient? _client;
  TutorialSyncRepository? _sync;
  bool _initialized = false;
  bool _tutorialsGloballyEnabled = true;
  final AlfabetizacionTtsCoach _ttsCoach = AlfabetizacionTtsCoach();
  bool _ttsReady = false;

  AlfabetizacionTtsCoach get ttsCoach => _ttsCoach;

  Future<void> ensureTtsReady() async {
    if (_ttsReady) return;
    await _ttsCoach.init();
    _ttsReady = true;
  }

  Future<void> interruptTts() => _ttsCoach.interrupt();

  Future<void> speakForContext(
    BuildContext context,
    String phrase, {
    bool slow = false,
  }) async {
    await ensureTtsReady();
    await _ttsCoach.speak(
      phrase,
      slow: slow,
      shouldContinue: () =>
          context.mounted && alfabetizacionTtsRouteActive(context),
    );
  }

  /// TTS para walkthroughs: solo exige [context.mounted] (no [alfabetizacionTtsRouteActive]),
  /// porque el overlay del tutorial no debe cortar la frase al estar encima de la pantalla.
  static const Duration _tutorialSpeakTimeout = Duration(seconds: 8);

  Future<void> speakTutorialPhrase(
    BuildContext context,
    String phrase, {
    bool slow = false,
  }) async {
    await ensureTtsReady();
    try {
      await _ttsCoach
          .speak(
            phrase,
            slow: slow,
            shouldContinue: () => context.mounted,
          )
          .timeout(_tutorialSpeakTimeout);
    } on TimeoutException {
      await interruptTts();
    }
  }

  bool get initialized => _initialized;

  bool get tutorialsGloballyEnabled => _tutorialsGloballyEnabled;

  Future<void> init(SupabaseClient client) async {
    if (_initialized) return;
    _client = client;
    _sync = TutorialSyncRepository(client);
    _prefs = await SharedPreferences.getInstance();
    await refreshTutorialsEnabledFromProfile();
    await _mergeRemoteCompletions();
    _initialized = true;
  }

  /// Recarga desde `profiles.tutorials_enabled` (default true si falla o no existe).
  Future<void> refreshTutorialsEnabledFromProfile() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      _tutorialsGloballyEnabled = true;
      return;
    }
    try {
      final row = await client
          .from('profiles')
          .select('tutorials_enabled')
          .eq('id', uid)
          .maybeSingle();
      final v = row?['tutorials_enabled'];
      if (v is bool) {
        _tutorialsGloballyEnabled = v;
      } else {
        _tutorialsGloballyEnabled = true;
      }
    } catch (_) {
      _tutorialsGloballyEnabled = true;
    }
  }

  Future<void> _mergeRemoteCompletions() async {
    final client = _client;
    final sync = _sync;
    final prefs = _prefs;
    final uid = client?.auth.currentUser?.id;
    if (client == null || sync == null || prefs == null || uid == null) return;
    try {
      final keys = await sync.fetchCompletedKeys(uid);
      for (final k in keys) {
        await prefs.setBool('$_prefsDonePrefix$k', true);
      }
    } catch (_) {}
  }

  bool isStepCompleted(TutorialStepKey stepId) {
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.getBool('$_prefsDonePrefix$stepId') ?? false;
  }

  bool isFlowSkipped(String flowId) {
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.getBool('$_prefsSkipPrefix$flowId') ?? false;
  }

  Future<void> markStepCompleted(TutorialStepKey stepId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool('$_prefsDonePrefix$stepId', true);
    final client = _client;
    final sync = _sync;
    final uid = client?.auth.currentUser?.id;
    if (client != null && sync != null && uid != null) {
      unawaited(_syncCompletion(uid, stepId));
    }
  }

  Future<void> _syncCompletion(String userId, String stepId) async {
    try {
      await _sync?.recordCompletion(userId: userId, tutorialKey: stepId);
    } catch (e) {
      debugPrint('TutorialService: sync $e');
    }
  }

  Future<void> markFlowSkipped(String flowId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool('$_prefsSkipPrefix$flowId', true);
  }

  /// Borra flags locales de pasos cuyo id empieza por [stepIdPrefix] y opcionalmente el remoto.
  Future<void> resetFlow({
    required String stepIdPrefix,
    bool deleteRemote = false,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().toList();
    for (final k in keys) {
      if (k.startsWith(_prefsDonePrefix) &&
          k.substring(_prefsDonePrefix.length).startsWith(stepIdPrefix)) {
        await prefs.remove(k);
      }
    }
    await prefs.remove('$_prefsSkipPrefix$stepIdPrefix');

    final client = _client;
    final sync = _sync;
    final uid = client?.auth.currentUser?.id;
    if (deleteRemote && sync != null && uid != null) {
      try {
        await sync.deleteKeysWithPrefix(userId: uid, prefix: stepIdPrefix);
      } catch (e) {
        debugPrint('TutorialService: reset remote $e');
      }
    }
  }
}
