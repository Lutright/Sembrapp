/// Resolución consistente de nombres en órdenes (lista, detalle, chat).
library;

final RegExp _nombrePlaceholder = RegExp(
  r'^(campesino|comprador|productor|usuario|cliente|vendedor)\s*\d*$',
  caseSensitive: false,
);

bool esNombreGenericoPlaceholder(String nombre) {
  final n = nombre.trim();
  if (n.isEmpty) return true;
  return _nombrePlaceholder.hasMatch(n);
}

String? nombreDesdePerfilEmbed(dynamic perfil) {
  if (perfil == null) return null;
  if (perfil is Map) {
    return perfil['full_name'] as String?;
  }
  if (perfil is List && perfil.isNotEmpty) {
    final first = perfil.first;
    if (first is Map) return first['full_name'] as String?;
  }
  return null;
}

String _resolverNombreParticipante({
  required dynamic perfilEmbed,
  required List<dynamic> camposOrden,
  required String fallback,
}) {
  final candidatos = <String?>[
    nombreDesdePerfilEmbed(perfilEmbed),
    ...camposOrden.map((c) => c?.toString()),
  ];
  for (final candidato in candidatos) {
    final nombre = candidato?.trim();
    if (nombre != null &&
        nombre.isNotEmpty &&
        !esNombreGenericoPlaceholder(nombre)) {
      return nombre;
    }
  }
  return fallback;
}

String resolverNombreCompradorOrden(Map<String, dynamic> orden) {
  return _resolverNombreParticipante(
    perfilEmbed: orden['comprador'],
    camposOrden: [
      orden['comprador_nombre'],
      orden['buyer_name'],
      orden['cliente_nombre'],
      orden['nombre_comprador'],
    ],
    fallback: 'Cliente',
  );
}

String resolverNombreProductorOrden(Map<String, dynamic> orden) {
  return _resolverNombreParticipante(
    perfilEmbed: orden['campesino'],
    camposOrden: [
      orden['campesino_nombre'],
      orden['productor_nombre'],
      orden['vendedor_nombre'],
      orden['seller_name'],
      orden['tienda_nombre'],
    ],
    fallback: 'Productor',
  );
}

/// Nombre de la otra persona en el pedido según quién está viendo la pantalla.
String resolverContraparteOrden({
  required Map<String, dynamic> orden,
  required String? usuarioActualId,
}) {
  final productorId = orden['campesino_id'] as String?;
  final esVistaProductor =
      usuarioActualId != null && productorId == usuarioActualId;
  return esVistaProductor
      ? resolverNombreCompradorOrden(orden)
      : resolverNombreProductorOrden(orden);
}
