/// RF-A: Contenido de lecciones para alfabetización (lectura y escritura).

import 'escritura_guiada_config.dart';

/// Flujo multipantalla + TTS usado por la lección [L1-1] Vocales.
const kFlujoVocalesGuiadoId = 'vocales_guiado';
/// Flujo multipantalla + TTS usado por la lección [L1-2] Abecedario.
const kFlujoAbecedarioGuiadoId = 'abecedario_guiado';
/// Flujo multipantalla + trazo guiado para Escritura de vocales.
const kFlujoEscrituraVocalesGuiadoId = 'escritura_vocales_guiado';
/// Flujo teclado: animación de vocal resaltada + práctica de escritura.
const kFlujoEscrituraTecladoVocalesGuiadoId = 'escritura_teclado_vocales_guiado';
/// Flujo de trazos del abecedario (primer acercamiento).
const kFlujoEscrituraTrazosAbecedarioGuiadoId = 'escritura_trazos_abecedario_guiado';
/// Flujo de teclado del abecedario (primer acercamiento).
const kFlujoEscrituraTecladoAbecedarioGuiadoId = 'escritura_teclado_abecedario_guiado';
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
  // --- Lectura nivel 1: fundamentos ---
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
  const LeccionData(
    id: 'L1-4',
    modulo: 'lectura',
    nivel: 1,
    titulo: 'Orden alfabético básico',
    contenido: 'Orden alfabético básico',
    flujoId: kFlujoOrdenAlfabeticoBasicoGuiadoId,
    puntos: 10,
  ),
  // --- Lectura nivel 2: sílabas directas ---
  const LeccionData(
    id: 'L2-1',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílabas MA-ME-MI-MO-MU',
    contenido: 'Sílabas directas 1',
    flujoId: kFlujoSilabasDirectasGuiadoId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'L2-2',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílabas PA-PE-PI-PO-PU',
    contenido: 'Sílabas directas 2',
    flujoId: kFlujoSilabasDirectasDosGuiadoId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'L2-3',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílabas LA-LE-LI-LO-LU',
    contenido: 'Sílabas directas 3',
    flujoId: kFlujoSilabasDirectasTresGuiadoId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'L2-4',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílabas TA-TE-TI-TO-TU',
    contenido: 'Sílabas directas 4',
    flujoId: kFlujoSilabasDirectasCuatroGuiadoId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'L2-5',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Sílabas SA-SE-SI-SO-SU',
    contenido: 'Sílabas directas 5',
    flujoId: kFlujoSilabasDirectasCincoGuiadoId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'L2-6',
    modulo: 'lectura',
    nivel: 2,
    titulo: 'Mezcla de sílabas',
    contenido: 'Mezcla de sílabas',
    flujoId: kFlujoSilabasMezclaGuiadoId,
    puntos: 15,
  ),
  // --- Lectura nivel 3: palabras ---
  const LeccionData(
    id: 'L3-1',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Palabras cortas',
    contenido: 'Palabras cortas',
    flujoId: kFlujoPalabrasCortasGuiadoId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'L3-2',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Palabras del campo',
    contenido: 'Palabras del campo',
    flujoId: kFlujoPalabrasCampoGuiadoId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'L3-3',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Asociación palabra-imagen 1',
    contenido: 'Palabra e imagen 1',
    flujoId: kFlujoPalabraImagenUnoGuiadoId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'L3-4',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Asociación palabra-imagen 2',
    contenido: 'Palabra e imagen 2',
    flujoId: kFlujoPalabraImagenDosGuiadoId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'L3-5',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Completa palabras MA y PA',
    contenido: 'Completar palabras 1',
    flujoId: kFlujoCompletarPalabraUnoGuiadoId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'L3-6',
    modulo: 'lectura',
    nivel: 3,
    titulo: 'Completa palabras LA y SA',
    contenido: 'Completar palabras 2',
    flujoId: kFlujoCompletarPalabraDosGuiadoId,
    puntos: 20,
  ),
  // --- Lectura nivel 4: frases ---
  const LeccionData(
    id: 'L4-1',
    modulo: 'lectura',
    nivel: 4,
    titulo: 'Frases cortas',
    contenido: 'Frases cortas',
    flujoId: kFlujoFrasesCortasGuiadoId,
    puntos: 25,
  ),
  const LeccionData(
    id: 'L4-2',
    modulo: 'lectura',
    nivel: 4,
    titulo: 'Frases de rutina agrícola 1',
    contenido: 'Frases de rutina 1',
    flujoId: kFlujoFrasesRutinaUnoGuiadoId,
    puntos: 25,
  ),
  const LeccionData(
    id: 'L4-3',
    modulo: 'lectura',
    nivel: 4,
    titulo: 'Frases de rutina agrícola 2',
    contenido: 'Frases de rutina 2',
    flujoId: kFlujoFrasesRutinaDosGuiadoId,
    puntos: 25,
  ),
  const LeccionData(
    id: 'L4-4',
    modulo: 'lectura',
    nivel: 4,
    titulo: 'Ordenar palabras en frase',
    contenido: 'Ordenar frase',
    flujoId: kFlujoOrdenarFraseGuiadoId,
    puntos: 25,
  ),
  const LeccionData(
    id: 'L4-5',
    modulo: 'lectura',
    nivel: 4,
    titulo: 'Elegir frase según imagen',
    contenido: 'Frase e imagen',
    flujoId: kFlujoFraseImagenGuiadoId,
    puntos: 25,
  ),
  // --- Lectura nivel 5: comprensión ---
  const LeccionData(
    id: 'L5-1',
    modulo: 'lectura',
    nivel: 5,
    titulo: 'Comprensión básica',
    contenido: 'Comprensión básica',
    flujoId: kFlujoComprensionBasicaGuiadoId,
    puntos: 30,
  ),
  const LeccionData(
    id: 'L5-2',
    modulo: 'lectura',
    nivel: 5,
    titulo: 'Comprensión: quién y qué',
    contenido: 'Comprensión quién y qué',
    flujoId: kFlujoComprensionQuienQueGuiadoId,
    puntos: 30,
  ),
  const LeccionData(
    id: 'L5-3',
    modulo: 'lectura',
    nivel: 5,
    titulo: 'Comprensión: dónde',
    contenido: 'Comprensión dónde',
    flujoId: kFlujoComprensionDondeGuiadoId,
    puntos: 30,
  ),
  const LeccionData(
    id: 'L5-4',
    modulo: 'lectura',
    nivel: 5,
    titulo: 'Secuencia: primero y después',
    contenido: 'Secuencia básica',
    flujoId: kFlujoSecuenciaBasicaGuiadoId,
    puntos: 30,
  ),
  const LeccionData(
    id: 'L5-5',
    modulo: 'lectura',
    nivel: 5,
    titulo: 'Vocabulario contextual',
    contenido: 'Vocabulario contextual',
    flujoId: kFlujoVocabularioContextualGuiadoId,
    puntos: 30,
  ),
  // --- Escritura nivel 1 ---
  const LeccionData(
    id: 'E1-1',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Escritura de vocales',
    contenido: 'A E I O U',
    flujoId: kFlujoEscrituraVocalesGuiadoId,
    puntos: 10,
  ),
  const LeccionData(
    id: 'E1-2',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Teclado y vocales',
    contenido: 'A E I O U',
    flujoId: kFlujoEscrituraTecladoVocalesGuiadoId,
    puntos: 10,
  ),
  const LeccionData(
    id: 'E1-3',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Abecedario: trazos',
    contenido: 'A B C',
    flujoId: kFlujoEscrituraTrazosAbecedarioGuiadoId,
    puntos: 10,
  ),
  const LeccionData(
    id: 'E1-4',
    modulo: 'escritura',
    nivel: 1,
    titulo: 'Abecedario: teclado',
    contenido: 'A B C',
    flujoId: kFlujoEscrituraTecladoAbecedarioGuiadoId,
    puntos: 10,
  ),
  // --- Escritura nivel 2: sílabas (trazos → teclado) y palabras comunes ---
  const LeccionData(
    id: 'E2-1',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas MA: trazos',
    contenido: 'MA ME MI MO MU',
    flujoId: kFlujoEscrituraTrazosSilabasMaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-2',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas MA: teclado',
    contenido: 'MA ME MI MO MU',
    flujoId: kFlujoEscrituraTecladoSilabasMaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-3',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas PA: trazos',
    contenido: 'PA PE PI PO PU',
    flujoId: kFlujoEscrituraTrazosSilabasPaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-4',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas PA: teclado',
    contenido: 'PA PE PI PO PU',
    flujoId: kFlujoEscrituraTecladoSilabasPaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-5',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas LA: trazos',
    contenido: 'LA LE LI LO LU',
    flujoId: kFlujoEscrituraTrazosSilabasLaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-6',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas LA: teclado',
    contenido: 'LA LE LI LO LU',
    flujoId: kFlujoEscrituraTecladoSilabasLaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-7',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas TA: trazos',
    contenido: 'TA TE TI TO TU',
    flujoId: kFlujoEscrituraTrazosSilabasTaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-8',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas TA: teclado',
    contenido: 'TA TE TI TO TU',
    flujoId: kFlujoEscrituraTecladoSilabasTaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-9',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas SA: trazos',
    contenido: 'SA SE SI SO SU',
    flujoId: kFlujoEscrituraTrazosSilabasSaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-10',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Sílabas SA: teclado',
    contenido: 'SA SE SI SO SU',
    flujoId: kFlujoEscrituraTecladoSilabasSaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-11',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Mezcla de sílabas: trazos',
    contenido: 'MA PA LA SA',
    flujoId: kFlujoEscrituraTrazosSilabasMezclaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-12',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Mezcla de sílabas: teclado',
    contenido: 'MA PA LA SA',
    flujoId: kFlujoEscrituraTecladoSilabasMezclaId,
    puntos: 15,
  ),
  const LeccionData(
    id: 'E2-13',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Palabras comunes: trazos',
    contenido: 'MAMA PAPA MESA PALA VACA',
    flujoId: kFlujoEscrituraTrazosPalabrasComunesId,
    puntos: 20,
  ),
  const LeccionData(
    id: 'E2-14',
    modulo: 'escritura',
    nivel: 2,
    titulo: 'Palabras comunes: teclado',
    contenido: 'MAMA PAPA MESA PALA VACA',
    flujoId: kFlujoEscrituraTecladoPalabrasComunesId,
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
