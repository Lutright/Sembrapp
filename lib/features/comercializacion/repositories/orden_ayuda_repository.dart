import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import 'productos_repository.dart';

class OrdenAyudaRepository {
  OrdenAyudaRepository(this._client);
  final SupabaseClient _client;

  /// Solicitud abierta para esta orden (si existe).
  Future<Map<String, dynamic>?> solicitudAbiertaPorOrden(String ordenId) async {
    final res = await _client
        .from('orden_ayuda_solicitud')
        .select()
        .eq('orden_id', ordenId)
        .eq('estado', 'abierta')
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }

  /// Todas las solicitudes abiertas (filtrar distancia en cliente).
  Future<List<Map<String, dynamic>>> listarSolicitudesAbiertas() async {
    final res = await _client
        .from('orden_ayuda_solicitud')
        .select('id, orden_id, lat, lng, nota, item_ids, created_at, solicitante_id')
        .eq('estado', 'abierta')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> obtenerSolicitud(String solicitudId) async {
    final res = await _client
        .from('orden_ayuda_solicitud')
        .select()
        .eq('id', solicitudId)
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }

  Future<void> crearSolicitud({
    required String ordenId,
    required String solicitanteId,
    required List<String> itemIds,
    required double lat,
    required double lng,
    String? nota,
  }) async {
    if (itemIds.isEmpty) {
      throw ArgumentError('Debes indicar al menos un producto');
    }
    await _client.from('orden_ayuda_solicitud').insert({
      'orden_id': ordenId,
      'solicitante_id': solicitanteId,
      'lat': lat,
      'lng': lng,
      'nota': nota?.trim().isEmpty == true ? null : nota?.trim(),
      'item_ids': itemIds,
      'estado': 'abierta',
    });
  }

  Future<void> cancelarSolicitud(String solicitudId) async {
    await _client.from('orden_ayuda_solicitud').update({
      'estado': 'cerrada',
      'ayudante_id': null,
    }).eq('id', solicitudId);
  }

  /// `true` si se asignó correctamente.
  Future<bool> aceptarSolicitud(String solicitudId) async {
    final res = await _client.rpc(
      'aceptar_solicitud_ayuda',
      params: {'p_solicitud_id': solicitudId},
    );
    if (res is Map && res['ok'] == true) return true;
    return false;
  }

  Future<Map<String, String>> nombresCampesinos(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return {};
    final rows =
        await _client.from('profiles').select('id, full_name').inFilter('id', list);
    final out = <String, String>{};
    for (final r in rows as List) {
      final m = r as Map<String, dynamic>;
      final id = m['id'] as String?;
      if (id != null) {
        out[id] = (m['full_name'] as String?)?.trim().isNotEmpty == true
            ? m['full_name'] as String
            : 'Productor';
      }
    }
    return out;
  }

  /// Ubicación para publicar la solicitud: GPS actual o centroide de tus productos.
  Future<({double lat, double lng})?> ubicacionParaPublicar(
    String campesinoId,
  ) async {
    final pos = await LocationService.instance.getLastKnownOrFetch();
    if (pos != null) {
      return (lat: pos.latitude, lng: pos.longitude);
    }
    final prods = await ProductosRepository(_client).productosPorCampesino(campesinoId);
    var slat = 0.0;
    var slng = 0.0;
    var n = 0;
    for (final p in prods) {
      if (p.lat != null && p.lng != null) {
        slat += p.lat!;
        slng += p.lng!;
        n++;
      }
    }
    if (n == 0) return null;
    return (lat: slat / n, lng: slng / n);
  }

  Future<List<Map<String, dynamic>>> listarMensajesSolicitud(
    String solicitudId,
  ) async {
    final res = await _client
        .from('ayuda_mensajes')
        .select('*, profiles(full_name)')
        .eq('solicitud_id', solicitudId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> enviarMensajeSolicitud(String solicitudId, String texto) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No sesión');
    await _client.from('ayuda_mensajes').insert({
      'solicitud_id': solicitudId,
      'sender_id': uid,
      'mensaje': texto,
    });
  }
}
