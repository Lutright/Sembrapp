import 'package:supabase_flutter/supabase_flutter.dart';

class AlfabetizacionRepository {
  AlfabetizacionRepository(this._client);
  final SupabaseClient _client;

  Future<int> getPuntosTotales(String userId) async {
    final res = await _client
        .from('alfabetizacion_progreso')
        .select('puntos')
        .eq('user_id', userId);
    if (res.isEmpty) return 0;
    var total = 0;
    for (final row in res as List) {
      total += (row['puntos'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Future<Map<String, dynamic>> getProgresoLeccion(
    String userId,
    String modulo,
    int nivel,
    String leccionId,
  ) async {
    final res = await _client
        .from('alfabetizacion_progreso')
        .select()
        .eq('user_id', userId)
        .eq('modulo', modulo)
        .eq('nivel', nivel)
        .eq('leccion_id', leccionId)
        .maybeSingle();
    return res != null ? res as Map<String, dynamic> : {};
  }

  Future<void> registrarCompletado({
    required String userId,
    required String modulo,
    required int nivel,
    required String leccionId,
    required int puntos,
  }) async {
    await _client.from('alfabetizacion_progreso').upsert({
      'user_id': userId,
      'modulo': modulo,
      'nivel': nivel,
      'leccion_id': leccionId,
      'puntos': puntos,
      'completado_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,modulo,nivel,leccion_id');
  }
}
