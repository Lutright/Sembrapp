/// RF-A: Contenido de lecciones para alfabetización (lectura y escritura).

/// Flujo multipantalla + TTS usado por la lección [L1-1] Vocales.
const kFlujoVocalesGuiadoId = 'vocales_guiado';
/// Flujo multipantalla + TTS usado por la lección [L1-2] Abecedario.
const kFlujoAbecedarioGuiadoId = 'abecedario_guiado';
/// Niveles progresivos; cada lección puede ser de tipo lectura o escritura.
class PreguntaData {
  const PreguntaData({
    required this.contenido,
    this.opciones,
    this.respuestaCorrecta,
    this.audioAsset,
  });

  final String contenido;
  final List<String>? opciones;
  final String? respuestaCorrecta;
  final String? audioAsset;
}

class SubleccionData {
  const SubleccionData({
    required this.titulo,
    required this.preguntas,
  });

  final String titulo;
  final List<PreguntaData> preguntas;
}

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
    this.sublecciones,
    /// Si no es null, la pantalla de lección usa un flujo guiado propio (p. ej. multipantalla + TTS).
    this.flujoId,
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
  final List<SubleccionData>? sublecciones;
  final String? flujoId;

  bool get esLectura => modulo == 'lectura';
  bool get esEscritura => modulo == 'escritura';

  List<PreguntaData> get preguntas {
    final sub = sublecciones;
    if (sub != null && sub.isNotEmpty) {
      return sub.expand((s) => s.preguntas).toList();
    }
    return [
      PreguntaData(
        contenido: contenido,
        opciones: opciones,
        respuestaCorrecta: respuestaCorrecta,
        audioAsset: audioAsset,
      ),
    ];
  }
}

/// Contenido fijo para el prototipo (RF-A-03, RF-A-04).
final alfabetizacionLecciones = <LeccionData>[
  // --- Lectura nivel 1: vocales y abecedario ---
  const LeccionData(
    id: 'L1-1',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'Vocales',
    contenido: 'Vocales',
    flujoId: kFlujoVocalesGuiadoId,
    puntos: 10,
  ),
  const LeccionData(
    id: 'L1-2',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'Abecedario',
    contenido: 'Abecedario',
    flujoId: kFlujoAbecedarioGuiadoId,
    sublecciones: [
      SubleccionData(
        titulo: 'Inicio del abecedario',
        preguntas: [
          PreguntaData(
            contenido: '¿Qué letra va después de A?',
            opciones: ['B', 'D', 'E'],
            respuestaCorrecta: 'B',
          ),
          PreguntaData(
            contenido: '¿Cuál grupo está en orden correcto?',
            opciones: ['A B C', 'A C B', 'C A B'],
            respuestaCorrecta: 'A B C',
          ),
        ],
      ),
      SubleccionData(
        titulo: 'Orden alfabético',
        preguntas: [
          PreguntaData(
            contenido: '¿Qué letra va después de M?',
            opciones: ['N', 'P', 'L'],
            respuestaCorrecta: 'N',
          ),
          PreguntaData(
            contenido: 'Selecciona el abecedario',
            opciones: [
              'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z',
              'A E I O U',
              'M A M A',
            ],
            respuestaCorrecta: 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z',
          ),
        ],
      ),
    ],
    puntos: 10,
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
  ),
  const LeccionData(
    id: 'E1-2',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe la letra E',
    contenido: 'E',
    respuestaCorrecta: 'E',
    puntos: 10,
  ),
  const LeccionData(
    id: 'E1-3',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe la sílaba MA',
    contenido: 'MA',
    respuestaCorrecta: 'MA',
    puntos: 15,
  ),
  const LeccionData(
    id: 'E1-4',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escribe: MAMA',
    contenido: 'MAMA',
    respuestaCorrecta: 'MAMA',
    puntos: 20,
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

/// Devuelve true si todas las lecciones de [nivel] tienen id en [completadas].
bool nivelEstaCompleto(
  String modulo,
  int nivel,
  Set<String> completadas,
) {
  final lecciones = leccionesPorModuloNivel(modulo, nivel);
  if (lecciones.isEmpty) return true;
  return lecciones.every((l) => completadas.contains(l.id));
}

/// Nivel 1 siempre desbloqueado. Nivel N>1 exige completar todas las lecciones del nivel anterior.
bool nivelDesbloqueado(
  String modulo,
  int nivel,
  Set<String> leccionesCompletadasIds,
) {
  if (nivel <= 1) return true;
  return nivelEstaCompleto(modulo, nivel - 1, leccionesCompletadasIds);
}

/// El orden es el de [leccionesPorModuloNivel] (orden en el contenido).
/// Hace falta tener el nivel abierto; la 1.ª lección del nivel queda disponible entonces;
/// cada lección siguiente exige haber aprobado la inmediatamente anterior.
bool leccionDesbloqueada(
  LeccionData leccion,
  Set<String> leccionesCompletadasIds,
) {
  if (!nivelDesbloqueado(
    leccion.modulo,
    leccion.nivel,
    leccionesCompletadasIds,
  )) {
    return false;
  }
  final lista = leccionesPorModuloNivel(leccion.modulo, leccion.nivel);
  final idx = lista.indexWhere((l) => l.id == leccion.id);
  if (idx < 0) return false;
  if (idx == 0) return true;
  return leccionesCompletadasIds.contains(lista[idx - 1].id);
}

/// Título de la lección previa en el mismo nivel, o null si no hay previa en lista.
String? tituloLeccionAnteriorMismoNivel(LeccionData leccion) {
  final lista = leccionesPorModuloNivel(leccion.modulo, leccion.nivel);
  final idx = lista.indexWhere((l) => l.id == leccion.id);
  if (idx <= 0) return null;
  return lista[idx - 1].titulo;
}
