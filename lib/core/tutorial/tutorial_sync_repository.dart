import 'package:supabase_flutter/supabase_flutter.dart';

/// Sincronización remota de pasos de tutorial completados.
class TutorialSyncRepository {
  TutorialSyncRepository(this._client);

  final SupabaseClient _client;

  Future<void> recordCompletion({
    required String userId,
    required String tutorialKey,
  }) async {
    await _client.from('tutorial_completions').upsert(
      {
        'user_id': userId,
        'tutorial_key': tutorialKey,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,tutorial_key',
    );
  }

  Future<List<String>> fetchCompletedKeys(String userId) async {
    final res = await _client
        .from('tutorial_completions')
        .select('tutorial_key')
        .eq('user_id', userId);
    final list = res as List<dynamic>;
    return list
        .map((e) => (e as Map<String, dynamic>)['tutorial_key'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Borra en servidor las filas cuyo [tutorial_key] empieza por [prefix].
  Future<void> deleteKeysWithPrefix({
    required String userId,
    required String prefix,
  }) async {
    final res = await _client
        .from('tutorial_completions')
        .select('id, tutorial_key')
        .eq('user_id', userId);
    final rows = res as List<dynamic>;
    for (final row in rows) {
      final m = row as Map<String, dynamic>;
      final key = m['tutorial_key'] as String?;
      final id = m['id'] as String?;
      if (key != null && id != null && key.startsWith(prefix)) {
        await _client.from('tutorial_completions').delete().eq('id', id);
      }
    }
  }
}
