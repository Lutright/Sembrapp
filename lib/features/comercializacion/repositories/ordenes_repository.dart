import 'package:supabase_flutter/supabase_flutter.dart';

class OrdenesRepository {
  OrdenesRepository(this._client);
  final SupabaseClient _client;

  /// Crea una orden con los ítems indicados y devuelve el id de la orden.
  /// Cada ítem: { productoId, cantidad, precioUnitario }.
  Future<String> crearOrden({
    required String compradorId,
    required String campesinoId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) throw ArgumentError('La orden debe tener al menos un ítem');

    final ordenRes = await _client.from('ordenes').insert({
      'comprador_id': compradorId,
      'campesino_id': campesinoId,
      'estado': 'pendiente',
    }).select('id').single();

    final ordenId = ordenRes['id'] as String;

    for (final item in items) {
      await _client.from('orden_items').insert({
        'orden_id': ordenId,
        'producto_id': item['producto_id'] as String,
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      });
    }

    return ordenId;
  }

  Future<bool> cancelarOrdenComoCampesino({
    required String ordenId,
    required String campesinoId,
  }) async {
    final res = await _client
        .from('ordenes')
        .update({'estado': 'cancelada'})
        .eq('id', ordenId)
        .eq('campesino_id', campesinoId)
        .not('estado', 'in', '(cancelada,completada,entregada,entregado)')
        .select('id');
    return (res as List).isNotEmpty;
  }
}
