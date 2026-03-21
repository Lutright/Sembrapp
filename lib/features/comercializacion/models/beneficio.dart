class Beneficio {
  const Beneficio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.puntosRequeridos,
    required this.duracionHoras,
    this.ordenPrioridad = 0,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final int puntosRequeridos;
  final int duracionHoras;
  final int ordenPrioridad;

  factory Beneficio.fromMap(Map<String, dynamic> map) {
    return Beneficio(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      puntosRequeridos: map['puntos_requeridos'] as int,
      duracionHoras: map['duracion_horas'] as int,
      ordenPrioridad: map['orden_prioridad'] as int? ?? 0,
    );
  }

  String get duracionTexto {
    if (duracionHoras < 24) return '$duracionHoras h';
    if (duracionHoras < 72) return '${duracionHoras ~/ 24} días';
    return '${duracionHoras ~/ 168} semana(s)';
  }
}

class BeneficioActivo {
  const BeneficioActivo({
    required this.id,
    required this.campesinoId,
    required this.beneficioId,
    required this.puntosGastados,
    required this.activadoAt,
    required this.expiraAt,
    this.beneficioNombre,
  });

  final String id;
  final String campesinoId;
  final String beneficioId;
  final int puntosGastados;
  final DateTime activadoAt;
  final DateTime expiraAt;
  final String? beneficioNombre;

  factory BeneficioActivo.fromMap(Map<String, dynamic> map) {
    String? nombre;
    final b = map['beneficios'];
    if (b is Map) nombre = b['nombre'] as String?;
    if (b is List && b.isNotEmpty && b.first is Map) {
      nombre = (b.first as Map)['nombre'] as String?;
    }
    return BeneficioActivo(
      id: map['id'] as String,
      campesinoId: map['campesino_id'] as String,
      beneficioId: map['beneficio_id'] as String,
      puntosGastados: map['puntos_gastados'] as int,
      activadoAt: DateTime.parse(map['activado_at'] as String),
      expiraAt: DateTime.parse(map['expira_at'] as String),
      beneficioNombre: nombre,
    );
  }

  bool get estaVigente => DateTime.now().isBefore(expiraAt);
}
