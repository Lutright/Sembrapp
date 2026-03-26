/// RF-A: Contenido de lecciones para alfabetización (lectura y escritura).
/// Niveles progresivos; cada lección puede ser de tipo lectura o escritura.
class LeccionData {
  const LeccionData({
    required this.id,
    required this.modulo,
    required this.nivel,
    required this.titulo,
    required this.contenido,
    this.opciones,
    this.respuestaCorrecta,
    this.puntos = 10,
    this.audioAsset,
  });

  final String id;
  final String modulo; // 'lectura' | 'escritura'
  final int nivel;
  final String titulo;
  final String contenido;
  final List<String>? opciones; // para reconocimiento (RF-L-02)
  final String? respuestaCorrecta; // para escritura o validación
  final int puntos;
  final String? audioAsset; // RF-A-12

  bool get esLectura => modulo == 'lectura';
  bool get esEscritura => modulo == 'escritura';
}

/// Contenido fijo para el prototipo (RF-A-03, RF-A-04).
final alfabetizacionLecciones = <LeccionData>[
  // --- Lectura nivel 1: letras ---
  const LeccionData(
    id: 'L1-1',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'La letra A',
    contenido: 'A',
    opciones: ['A', 'E', 'O'],
    respuestaCorrecta: 'A',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/L1-1.mp3',
  ),
  const LeccionData(
    id: 'L1-2',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'La letra E',
    contenido: 'E',
    opciones: ['A', 'E', 'I'],
    respuestaCorrecta: 'E',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/L1-2.mp3',
  ),
  const LeccionData(
    id: 'L1-3',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'La letra I',
    contenido: 'I',
    opciones: ['I', 'O', 'U'],
    respuestaCorrecta: 'I',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/L1-3.mp3',
  ),
  const LeccionData(
    id: 'L1-4',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'La letra O',
    contenido: 'O',
    opciones: ['O', 'U', 'A'],
    respuestaCorrecta: 'O',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/L1-4.mp3',
  ),
  const LeccionData(
    id: 'L1-5',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'La letra U',
    contenido: 'U',
    opciones: ['U', 'A', 'E'],
    respuestaCorrecta: 'U',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/L1-5.mp3',
  ),
  // --- Lectura nivel 2: sílabas ---
  const LeccionData(
    id: 'L2-1',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílaba MA',
    contenido: 'MA',
    opciones: ['MA', 'ME', 'MO'],
    respuestaCorrecta: 'MA',
    puntos: 15,
    audioAsset: 'alfabetizacion/audio/L2-1.mp3',
  ),
  const LeccionData(
    id: 'L2-2',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílaba PA',
    contenido: 'PA',
    opciones: ['PA', 'PE', 'PO'],
    respuestaCorrecta: 'PA',
    puntos: 15,
    audioAsset: 'alfabetizacion/audio/L2-2.mp3',
  ),
  const LeccionData(
    id: 'L2-3',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílaba LA',
    contenido: 'LA',
    opciones: ['LA', 'LE', 'LI'],
    respuestaCorrecta: 'LA',
    puntos: 15,
    audioAsset: 'alfabetizacion/audio/L2-3.mp3',
  ),
  // --- Lectura nivel 3: palabras ---
  const LeccionData(
    id: 'L3-1',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Palabra: MAMA',
    contenido: 'MAMA',
    opciones: ['MAMA', 'PAPA', 'CASA'],
    respuestaCorrecta: 'MAMA',
    puntos: 20,
    audioAsset: 'alfabetizacion/audio/L3-1.mp3',
  ),
  const LeccionData(
    id: 'L3-2',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Palabra: PAPA',
    contenido: 'PAPA',
    opciones: ['PAPA', 'MAMA', 'PATO'],
    respuestaCorrecta: 'PAPA',
    puntos: 20,
    audioAsset: 'alfabetizacion/audio/L3-2.mp3',
  ),
  // --- Escritura nivel 1 ---
  const LeccionData(
    id: 'E1-1',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe la letra A',
    contenido: 'A',
    respuestaCorrecta: 'A',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/E1-1.mp3',
  ),
  const LeccionData(
    id: 'E1-2',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe la letra E',
    contenido: 'E',
    respuestaCorrecta: 'E',
    puntos: 10,
    audioAsset: 'alfabetizacion/audio/E1-2.mp3',
  ),
  const LeccionData(
    id: 'E1-3',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe la sílaba MA',
    contenido: 'MA',
    respuestaCorrecta: 'MA',
    puntos: 15,
    audioAsset: 'alfabetizacion/audio/E1-3.mp3',
  ),
  const LeccionData(
    id: 'E1-4',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe: MAMA',
    contenido: 'MAMA',
    respuestaCorrecta: 'MAMA',
    puntos: 20,
    audioAsset: 'alfabetizacion/audio/E1-4.mp3',
  ),
];

List<LeccionData> leccionesPorModuloNivel(String modulo, int nivel) {
  return alfabetizacionLecciones
      .where((l) => l.modulo == modulo && l.nivel == nivel)
      .toList();
}

List<int> nivelesDisponibles(String modulo) {
  return alfabetizacionLecciones
      .where((l) => l.modulo == modulo)
      .map((l) => l.nivel)
      .toSet()
      .toList()
    ..sort();
}

LeccionData? leccionPorId(String id) {
  try {
    return alfabetizacionLecciones.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
}
