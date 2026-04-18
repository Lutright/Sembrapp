class Producto {
  final String id;
  final String campesinoId;
  final String? campesinoNombre;
  final String nombre;
  final String? imagenUrl;
  final String? descripcion;
  final double precio;
  /// `null`: no se declara stock en catálogo (disponibilidad variable).
  final double? cantidadDisponible;
  final String unidad;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;

  const Producto({
    required this.id,
    required this.campesinoId,
    this.campesinoNombre,
    required this.nombre,
    this.imagenUrl,
    this.descripcion,
    required this.precio,
    this.cantidadDisponible,
    this.unidad = 'kg',
    this.lat,
    this.lng,
    this.createdAt,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    final imagen =
        (map['imagen_url'] as String?) ?? (map['imagen'] as String?);
    return Producto(
      id: map['id'] as String,
      campesinoId: map['campesino_id'] as String,
      campesinoNombre: _campesinoNombreFromMap(map['profiles']),
      nombre: map['nombre'] as String,
      imagenUrl: imagen,
      descripcion: map['descripcion'] as String?,
      precio: (map['precio'] as num).toDouble(),
      cantidadDisponible: map['cantidad_disponible'] != null
          ? (map['cantidad_disponible'] as num).toDouble()
          : null,
      unidad: map['unidad'] as String? ?? 'kg',
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  static String? _campesinoNombreFromMap(dynamic profiles) {
    if (profiles == null) return null;
    if (profiles is Map) return profiles['full_name'] as String?;
    if (profiles is List && profiles.isNotEmpty && profiles.first is Map) {
      return (profiles.first as Map)['full_name'] as String?;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'campesino_id': campesinoId,
      'nombre': nombre,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
      'descripcion': descripcion,
      'precio': precio,
      if (cantidadDisponible != null) 'cantidad_disponible': cantidadDisponible,
      'unidad': unidad,
      'lat': lat,
      'lng': lng,
    };
  }

  /// Tope para cantidad en pedidos (UI y validación). Sin declarar = valor alto simbólico.
  static const double sinTopeSimbolico = 9999;

  double get limiteSuperiorPedido =>
      cantidadDisponible ?? sinTopeSimbolico;

  bool get tieneStockDeclarado => cantidadDisponible != null;
}
