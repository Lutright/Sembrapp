import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/beneficio.dart';

class BeneficiosRepository {
  BeneficiosRepository(this._client);
  final SupabaseClient _client;

  /// Puntos ganados en alfabetización menos puntos gastados en beneficios.
  Future<int> getPuntosDisponibles(String campesinoId) async {
    final resProgreso = await _client
        .from('alfabetizacion_progreso')
        .select('puntos')
        .eq('user_id', campesinoId);
    var ganados = 0;
    for (final row in resProgreso as List) {
      ganados += (row['puntos'] as num?)?.toInt() ?? 0;
    }

    final resGastados = await _client
        .from('beneficios_activos')
        .select('puntos_gastados')
        .eq('campesino_id', campesinoId);
    var gastados = 0;
    for (final row in resGastados as List) {
      gastados += (row['puntos_gastados'] as num?)?.toInt() ?? 0;
    }

    return (ganados - gastados).clamp(0, 1 << 31);
  }

  Future<List<Beneficio>> listarBeneficios() async {
    final res = await _client
        .from('beneficios')
        .select()
        .order('orden_prioridad');
    return (res as List)
        .map((e) => Beneficio.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BeneficioActivo>> getBeneficiosActivosDelCampesino(
      String campesinoId) async {
    final res = await _client
        .from('beneficios_activos')
        .select('*, beneficios(nombre)')
        .eq('campesino_id', campesinoId)
        .order('expira_at', ascending: false);
    return (res as List)
        .map((e) => BeneficioActivo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// IDs de campesinos que tienen un beneficio de visibilidad vigente (para ordenar listado).
  Future<Set<String>> getCampesinosConBeneficioVigente() async {
    final now = DateTime.now().toIso8601String();
    final res = await _client
        .from('beneficios_activos')
        .select('campesino_id')
        .gt('expira_at', now);
    return (res as List)
        .map((e) => e['campesino_id'] as String)
        .toSet();
  }

  /// Activa un beneficio: descuenta puntos y crea el registro con expiración.
  Future<void> activarBeneficio({
    required String campesinoId,
    required Beneficio beneficio,
  }) async {
    final ahora = DateTime.now();
    final expiraAt = ahora.add(Duration(hours: beneficio.duracionHoras));
    await _client.from('beneficios_activos').insert({
      'campesino_id': campesinoId,
      'beneficio_id': beneficio.id,
      'puntos_gastados': beneficio.puntosRequeridos,
      'activado_at': ahora.toIso8601String(),
      'expira_at': expiraAt.toIso8601String(),
    });
  }
}
