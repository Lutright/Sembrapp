/// RF-A: Contenido de lecciones para alfabetización (lectura y escritura).
<<<<<<< Updated upstream
=======

/// Flujo multipantalla + TTS usado por la lección [L1-1] Vocales.
const kFlujoVocalesGuiadoId = 'vocales_guiado';
/// Flujo multipantalla + TTS usado por la lección [L1-2] Abecedario.
const kFlujoAbecedarioGuiadoId = 'abecedario_guiado';
/// Flujo multipantalla + trazo guiado para Escritura de vocales.
const kFlujoEscrituraVocalesGuiadoId = 'escritura_vocales_guiado';
/// Flujo teclado: animación de vocal resaltada + práctica de escritura.
const kFlujoEscrituraTecladoVocalesGuiadoId = 'escritura_teclado_vocales_guiado';
/// Flujo teclado: recorrido por letras del abecedario + práctica de escritura.
const kFlujoEscrituraTecladoAbecedarioGuiadoId =
    'escritura_teclado_abecedario_guiado';
/// Flujos guiados progresivos para Lectura (enseñanza + práctica + actividad).
const kFlujoSilabasDirectasGuiadoId = 'silabas_directas_guiado';
const kFlujoSilabasDirectasDosGuiadoId = 'silabas_directas_dos_guiado';
const kFlujoPalabrasCortasGuiadoId = 'palabras_cortas_guiado';
const kFlujoPalabrasCampoGuiadoId = 'palabras_campo_guiado';
const kFlujoFrasesCortasGuiadoId = 'frases_cortas_guiado';
const kFlujoComprensionBasicaGuiadoId = 'comprension_basica_guiado';
const kFlujoOrdenAlfabeticoBasicoGuiadoId = 'orden_alfabetico_basico_guiado';
const kFlujoSilabasDirectasTresGuiadoId = 'silabas_directas_tres_guiado';
const kFlujoSilabasDirectasCuatroGuiadoId = 'silabas_directas_cuatro_guiado';
const kFlujoSilabasDirectasCincoGuiadoId = 'silabas_directas_cinco_guiado';
const kFlujoSilabasMezclaGuiadoId = 'silabas_mezcla_guiado';
const kFlujoPalabraImagenUnoGuiadoId = 'palabra_imagen_uno_guiado';
const kFlujoPalabraImagenDosGuiadoId = 'palabra_imagen_dos_guiado';
const kFlujoCompletarPalabraUnoGuiadoId = 'completar_palabra_uno_guiado';
const kFlujoCompletarPalabraDosGuiadoId = 'completar_palabra_dos_guiado';
const kFlujoFrasesRutinaUnoGuiadoId = 'frases_rutina_uno_guiado';
const kFlujoFrasesRutinaDosGuiadoId = 'frases_rutina_dos_guiado';
const kFlujoOrdenarFraseGuiadoId = 'ordenar_frase_guiado';
const kFlujoFraseImagenGuiadoId = 'frase_imagen_guiado';
const kFlujoComprensionQuienQueGuiadoId = 'comprension_quien_que_guiado';
const kFlujoComprensionDondeGuiadoId = 'comprension_donde_guiado';
const kFlujoSecuenciaBasicaGuiadoId = 'secuencia_basica_guiado';
const kFlujoVocabularioContextualGuiadoId = 'vocabulario_contextual_guiado';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    titulo: 'Escribe la sílaba MA',
    contenido: 'MA',
    respuestaCorrecta: 'MA',
=======
    titulo: 'Teclado y abecedario 1',
    contenido: 'A - M',
    flujoId: kFlujoEscrituraTecladoAbecedarioGuiadoId,
>>>>>>> Stashed changes
    puntos: 15,
  ),
  const LeccionData(
    id: 'E1-4',
    modulo: 'escritura',
    nivel: 1,
<<<<<<< Updated upstream
    titulo: 'Escribe: MAMA',
    contenido: 'MAMA',
    respuestaCorrecta: 'MAMA',
    puntos: 20,
=======
    titulo: 'Teclado y abecedario 2',
    contenido: 'N - Z',
    flujoId: kFlujoEscrituraTecladoAbecedarioGuiadoId,
    puntos: 15,
>>>>>>> Stashed changes
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
