/// Modelo para un indicador de precios de mercado (info_mercado).
/// RF-C-05, RF-C-06.
class IndicadorEconomico {
  const IndicadorEconomico({
    required this.id,
    required this.productoTipo,
    this.precioPromedio,
    this.rangoMin,
    this.rangoMax,
    this.unidad = 'kg',
    this.fuente,
    this.updatedAt,
  });

  final String id;
  final String productoTipo;
  final double? precioPromedio;
  final double? rangoMin;
  final double? rangoMax;
  final String unidad;
  final String? fuente;
  final DateTime? updatedAt;

  static IndicadorEconomico fromMap(Map<String, dynamic> map) {
    final updatedAtRaw = map['updated_at'];
    return IndicadorEconomico(
      id: map['id'] as String? ?? '',
      productoTipo: map['producto_tipo'] as String? ?? '',
      precioPromedio: _toDouble(map['precio_promedio']),
      rangoMin: _toDouble(map['rango_min']),
      rangoMax: _toDouble(map['rango_max']),
      unidad: map['unidad'] as String? ?? 'kg',
      fuente: map['fuente'] as String?,
      updatedAt: updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw.toString()) : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String get precioFormateado {
    if (precioPromedio == null) return '—';
    return '\$${precioPromedio!.toStringAsFixed(0)}';
  }

  String get rangoFormateado {
    if (rangoMin == null && rangoMax == null) return '—';
    if (rangoMin != null && rangoMax != null) {
      return '\$${rangoMin!.toStringAsFixed(0)} – \$${rangoMax!.toStringAsFixed(0)}';
    }
    if (rangoMin != null) return 'Mín. \$${rangoMin!.toStringAsFixed(0)}';
    return 'Máx. \$${rangoMax!.toStringAsFixed(0)}';
  }
}
