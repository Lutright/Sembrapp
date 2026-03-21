import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/indicador_economico.dart';

/// Repositorio de indicadores económicos (info_mercado).
/// Los datos se sincronizan vía Edge Function `sync-indicadores` (por defecto desde SIPSA/DANE).
class IndicadoresRepository {
  IndicadoresRepository(this._client);
  final SupabaseClient _client;

  /// Lista todos los indicadores de mercado almacenados en Supabase.
  Future<List<IndicadorEconomico>> listar() async {
    final res = await _client
        .from('info_mercado')
        .select()
        .order('producto_tipo', ascending: true);
    return (res as List)
        .map((e) => IndicadorEconomico.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene la fecha de la última actualización (del registro más reciente).
  Future<DateTime?> ultimaActualizacion() async {
    final res = await _client
        .from('info_mercado')
        .select('updated_at')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    final raw = res['updated_at'];
    return raw != null ? DateTime.tryParse(raw.toString()) : null;
  }

  /// Invoca la Edge Function `sync-indicadores` para sincronizar la tabla `info_mercado`.
  /// Por defecto consulta SIPSA/DANE; opcionalmente puede usarse un override via `INDICADORES_API_URL`.
  Future<SyncIndicadoresResult> sincronizarDesdeFuente() async {
    try {
      final response = await _client.functions.invoke('sync-indicadores');
      if (response.status != 200) {
        final body = response.data is Map ? response.data as Map : null;
        final msg = body?['error'] as String? ?? 'Error ${response.status}';
        return SyncIndicadoresResult(ok: false, error: msg);
      }
      final data = response.data is Map ? response.data as Map : <String, dynamic>{};
      return SyncIndicadoresResult(
        ok: true,
        started: data['started'] as bool? ?? false,
        actualizados: data['actualizados'] as int? ?? 0,
        fuente: data['fuente'] as String? ?? 'fuente',
      );
    } catch (e) {
      return SyncIndicadoresResult(
        ok: false,
        error: e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), ''),
      );
    }
  }
}

class SyncIndicadoresResult {
  const SyncIndicadoresResult({
    required this.ok,
    this.started = false,
    this.actualizados = 0,
    this.fuente,
    this.error,
  });
  final bool ok;
  final bool started;
  final int actualizados;
  final String? fuente;
  final String? error;
}
