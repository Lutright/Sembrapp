import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/geo_utils.dart';
import '../models/producto.dart';

class ProductosRepository {
  ProductosRepository(this._client);
  final SupabaseClient _client;

  Future<List<Producto>> listarProductos({String? busqueda}) async {
    var query = _client
        .from('productos')
        .select('*, profiles(full_name)');
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query = query.ilike('nombre', '%${busqueda.trim()}%');
    }
    final orderedQuery = query.order('created_at', ascending: false);
    final res = await orderedQuery;
    return (res as List)
        .map((e) => Producto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Producto>> listarProductosCercanos({
    required double buyerLat,
    required double buyerLng,
    double maxDistanceKm = 25,
    String? busqueda,
  }) async {
    final all = await listarProductos(busqueda: busqueda);
    return all.where((p) {
      if (p.lat == null || p.lng == null) return false;
      final d = distanceKm(
        lat1: buyerLat,
        lng1: buyerLng,
        lat2: p.lat!,
        lng2: p.lng!,
      );
      return d <= maxDistanceKm;
    }).toList();
  }

  Future<List<Producto>> misProductos(String campesinoId) async {
    final res = await _client
        .from('productos')
        .select('*, profiles(full_name)')
        .eq('campesino_id', campesinoId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Producto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Producto?> obtenerProducto(String id) async {
    final res = await _client
        .from('productos')
        .select('*, profiles(full_name)')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return Producto.fromMap(res as Map<String, dynamic>);
  }

  Future<void> crearProducto(Producto p) async {
    await _client.from('productos').insert(p.toMap());
  }

  Future<void> actualizarProducto(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('productos').update(data).eq('id', id);
  }

  Future<void> eliminarProducto(String id) async {
    await _client.from('productos').delete().eq('id', id);
  }
}
