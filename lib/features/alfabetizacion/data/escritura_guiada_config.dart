/// Configuración de lecciones guiadas de escritura (trazos y teclado).

class EscrituraPaso {
  const EscrituraPaso({
    required this.texto,
    required this.pista,
    required this.emoji,
  });

  final String texto;
  final String pista;
  final String emoji;
}

class EscrituraGuiadaConfig {
  const EscrituraGuiadaConfig({
    required this.tituloNarrado,
    required this.nombreUnidad,
    required this.introNarracion,
    required this.mensajeCompletado,
    required this.pasos,
  });

  final String tituloNarrado;
  final String nombreUnidad;
  final String introNarracion;
  final String mensajeCompletado;
  final List<EscrituraPaso> pasos;
}

// --- Sílabas (paralelo a lectura nivel 2) ---
const kFlujoEscrituraTrazosSilabasMaId = 'escritura_trazos_silabas_ma';
const kFlujoEscrituraTecladoSilabasMaId = 'escritura_teclado_silabas_ma';
const kFlujoEscrituraTrazosSilabasPaId = 'escritura_trazos_silabas_pa';
const kFlujoEscrituraTecladoSilabasPaId = 'escritura_teclado_silabas_pa';
const kFlujoEscrituraTrazosSilabasLaId = 'escritura_trazos_silabas_la';
const kFlujoEscrituraTecladoSilabasLaId = 'escritura_teclado_silabas_la';
const kFlujoEscrituraTrazosSilabasTaId = 'escritura_trazos_silabas_ta';
const kFlujoEscrituraTecladoSilabasTaId = 'escritura_teclado_silabas_ta';
const kFlujoEscrituraTrazosSilabasSaId = 'escritura_trazos_silabas_sa';
const kFlujoEscrituraTecladoSilabasSaId = 'escritura_teclado_silabas_sa';
const kFlujoEscrituraTrazosSilabasMezclaId = 'escritura_trazos_silabas_mezcla';
const kFlujoEscrituraTecladoSilabasMezclaId = 'escritura_teclado_silabas_mezcla';

// --- Palabras comunes (escritura nivel 2) ---
const kFlujoEscrituraTrazosPalabrasComunesId = 'escritura_trazos_palabras_comunes';
const kFlujoEscrituraTecladoPalabrasComunesId = 'escritura_teclado_palabras_comunes';

// --- Frases simples (escritura nivel 3, paralelo a lectura L3 en estructura) ---
const kFlujoEscrituraTrazosFrasesCortasId = 'escritura_trazos_frases_cortas';
const kFlujoEscrituraTecladoFrasesCortasId = 'escritura_teclado_frases_cortas';
const kFlujoEscrituraTrazosFrasesRutinaUnoId = 'escritura_trazos_frases_rutina_uno';
const kFlujoEscrituraTecladoFrasesRutinaUnoId = 'escritura_teclado_frases_rutina_uno';
const kFlujoEscrituraTrazosFrasesRutinaDosId = 'escritura_trazos_frases_rutina_dos';
const kFlujoEscrituraTecladoFrasesRutinaDosId = 'escritura_teclado_frases_rutina_dos';
const kFlujoEscrituraTrazosFrasesOrdenId = 'escritura_trazos_frases_orden';
const kFlujoEscrituraTecladoFrasesOrdenId = 'escritura_teclado_frases_orden';
const kFlujoEscrituraTrazosFrasesImagenId = 'escritura_trazos_frases_imagen';
const kFlujoEscrituraTecladoFrasesImagenId = 'escritura_teclado_frases_imagen';
const kFlujoEscrituraTrazosFrasesMezclaId = 'escritura_trazos_frases_mezcla';
const kFlujoEscrituraTecladoFrasesMezclaId = 'escritura_teclado_frases_mezcla';

// --- Orden alfabético (escritura nivel 1, paralelo a lectura L1-4) ---
const kFlujoEscrituraTrazosOrdenAlfabeticoId = 'escritura_trazos_orden_alfabetico';
const kFlujoEscrituraTecladoOrdenAlfabeticoId = 'escritura_teclado_orden_alfabetico';

// --- Palabras (escritura nivel 4, paralelo a lectura L3) ---
const kFlujoEscrituraTrazosPalabrasCortasId = 'escritura_trazos_palabras_cortas';
const kFlujoEscrituraTecladoPalabrasCortasId = 'escritura_teclado_palabras_cortas';
const kFlujoEscrituraTrazosPalabrasCampoId = 'escritura_trazos_palabras_campo';
const kFlujoEscrituraTecladoPalabrasCampoId = 'escritura_teclado_palabras_campo';
const kFlujoEscrituraTrazosPalabraImagenUnoId = 'escritura_trazos_palabra_imagen_uno';
const kFlujoEscrituraTecladoPalabraImagenUnoId = 'escritura_teclado_palabra_imagen_uno';
const kFlujoEscrituraTrazosPalabraImagenDosId = 'escritura_trazos_palabra_imagen_dos';
const kFlujoEscrituraTecladoPalabraImagenDosId = 'escritura_teclado_palabra_imagen_dos';
const kFlujoEscrituraTrazosCompletarPalabraUnoId = 'escritura_trazos_completar_palabra_uno';
const kFlujoEscrituraTecladoCompletarPalabraUnoId = 'escritura_teclado_completar_palabra_uno';
const kFlujoEscrituraTrazosCompletarPalabraDosId = 'escritura_trazos_completar_palabra_dos';
const kFlujoEscrituraTecladoCompletarPalabraDosId = 'escritura_teclado_completar_palabra_dos';

// --- Comprensión / escritura contextual (escritura nivel 5, paralelo a lectura L5) ---
const kFlujoEscrituraTrazosComprensionBasicaId = 'escritura_trazos_comprension_basica';
const kFlujoEscrituraTecladoComprensionBasicaId = 'escritura_teclado_comprension_basica';
const kFlujoEscrituraTrazosComprensionQuienQueId = 'escritura_trazos_comprension_quien_que';
const kFlujoEscrituraTecladoComprensionQuienQueId = 'escritura_teclado_comprension_quien_que';
const kFlujoEscrituraTrazosComprensionDondeId = 'escritura_trazos_comprension_donde';
const kFlujoEscrituraTecladoComprensionDondeId = 'escritura_teclado_comprension_donde';
const kFlujoEscrituraTrazosSecuenciaBasicaId = 'escritura_trazos_secuencia_basica';
const kFlujoEscrituraTecladoSecuenciaBasicaId = 'escritura_teclado_secuencia_basica';
const kFlujoEscrituraTrazosVocabularioContextualId = 'escritura_trazos_vocabulario_contextual';
const kFlujoEscrituraTecladoVocabularioContextualId = 'escritura_teclado_vocabulario_contextual';

const _pasosSilabasMa = [
  EscrituraPaso(texto: 'MA', pista: 'MA de mano', emoji: '✋'),
  EscrituraPaso(texto: 'ME', pista: 'ME de mesa', emoji: '🪑'),
  EscrituraPaso(texto: 'MI', pista: 'MI de maíz', emoji: '🌽'),
  EscrituraPaso(texto: 'MO', pista: 'MO de molino', emoji: '🌾'),
  EscrituraPaso(texto: 'MU', pista: 'MU de mula', emoji: '🐴'),
];

const _pasosSilabasPa = [
  EscrituraPaso(texto: 'PA', pista: 'PA de pala', emoji: '🪏'),
  EscrituraPaso(texto: 'PE', pista: 'PE de pera', emoji: '🍐'),
  EscrituraPaso(texto: 'PI', pista: 'PI de pila', emoji: '🔋'),
  EscrituraPaso(texto: 'PO', pista: 'PO de pozo', emoji: '🪣'),
  EscrituraPaso(texto: 'PU', pista: 'PU de pulpa', emoji: '🍊'),
];

const _pasosSilabasLa = [
  EscrituraPaso(texto: 'LA', pista: 'LA de lana', emoji: '🧶'),
  EscrituraPaso(texto: 'LE', pista: 'LE de leche', emoji: '🥛'),
  EscrituraPaso(texto: 'LI', pista: 'LI de lima', emoji: '🍋'),
  EscrituraPaso(texto: 'LO', pista: 'LO de loma', emoji: '⛰️'),
  EscrituraPaso(texto: 'LU', pista: 'LU de luna', emoji: '🌙'),
];

const _pasosSilabasTa = [
  EscrituraPaso(texto: 'TA', pista: 'TA de taza', emoji: '☕'),
  EscrituraPaso(texto: 'TE', pista: 'TE de tela', emoji: '🧵'),
  EscrituraPaso(texto: 'TI', pista: 'TI de tierra', emoji: '🌱'),
  EscrituraPaso(texto: 'TO', pista: 'TO de tomate', emoji: '🍅'),
  EscrituraPaso(texto: 'TU', pista: 'TU de túnel', emoji: '🚇'),
];

const _pasosSilabasSa = [
  EscrituraPaso(texto: 'SA', pista: 'SA de saco', emoji: '🧺'),
  EscrituraPaso(texto: 'SE', pista: 'SE de semilla', emoji: '🌱'),
  EscrituraPaso(texto: 'SI', pista: 'SI de silla', emoji: '🪑'),
  EscrituraPaso(texto: 'SO', pista: 'SO de sol', emoji: '☀️'),
  EscrituraPaso(texto: 'SU', pista: 'SU de surco', emoji: '🚜'),
];

const _pasosSilabasMezcla = [
  EscrituraPaso(texto: 'MA', pista: 'MA', emoji: '🔠'),
  EscrituraPaso(texto: 'PA', pista: 'PA', emoji: '🔠'),
  EscrituraPaso(texto: 'LA', pista: 'LA', emoji: '🔠'),
  EscrituraPaso(texto: 'SA', pista: 'SA', emoji: '🔠'),
];

const _pasosPalabrasComunes = [
  EscrituraPaso(texto: 'MAMA', pista: 'MAMA', emoji: '👩'),
  EscrituraPaso(texto: 'PAPA', pista: 'PAPA', emoji: '👨'),
  EscrituraPaso(texto: 'MESA', pista: 'MESA', emoji: '🪑'),
  EscrituraPaso(texto: 'PALA', pista: 'PALA', emoji: '🪏'),
  EscrituraPaso(texto: 'VACA', pista: 'VACA', emoji: '🐄'),
];

EscrituraGuiadaConfig _cfgSilabas({
  required String titulo,
  required List<EscrituraPaso> pasos,
  required String introTrazos,
  required String introTeclado,
  required String finTrazos,
  required String finTeclado,
  required bool esTrazos,
}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: titulo,
    nombreUnidad: 'Sílaba',
    introNarracion: esTrazos ? introTrazos : introTeclado,
    mensajeCompletado: esTrazos ? finTrazos : finTeclado,
    pasos: pasos,
  );
}

const _pasosFrasesCortas = [
  EscrituraPaso(texto: 'MI MAMA ME AMA', pista: 'Mi mamá me ama', emoji: '❤️'),
  EscrituraPaso(texto: 'MI PAPA RIEGA', pista: 'Mi papá riega', emoji: '💧'),
  EscrituraPaso(texto: 'LA VACA COME', pista: 'La vaca come', emoji: '🐄'),
];

const _pasosFrasesRutinaUno = [
  EscrituraPaso(texto: 'PAPA USA LA PALA', pista: 'Papá usa la pala', emoji: '🪏'),
  EscrituraPaso(texto: 'MAMA RIEGA EL MAIZ', pista: 'Mamá riega el maíz', emoji: '🌽'),
  EscrituraPaso(texto: 'LA VACA COME PASTO', pista: 'La vaca come pasto', emoji: '🐄'),
];

const _pasosFrasesRutinaDos = [
  EscrituraPaso(texto: 'EL CAMPESINO CARGA SACO', pista: 'El campesino carga saco', emoji: '🧺'),
  EscrituraPaso(texto: 'LA FAMILIA VENDE MAIZ', pista: 'La familia vende maíz', emoji: '🌽'),
  EscrituraPaso(texto: 'EL RIEGO LLEGA AL SURCO', pista: 'El riego llega al surco', emoji: '🚜'),
];

const _pasosFrasesOrden = [
  EscrituraPaso(texto: 'MAMA RIEGA MAIZ', pista: 'Mamá riega maíz', emoji: '🌽'),
  EscrituraPaso(texto: 'PAPA USA PALA', pista: 'Papá usa pala', emoji: '🪏'),
  EscrituraPaso(texto: 'VACA TOMA AGUA', pista: 'Vaca toma agua', emoji: '💧'),
];

const _pasosFrasesImagen = [
  EscrituraPaso(texto: 'LA VACA TOMA AGUA', pista: 'La vaca toma agua', emoji: '🐄'),
  EscrituraPaso(texto: 'EL CAMPESINO SIEMBRA', pista: 'El campesino siembra', emoji: '🌱'),
  EscrituraPaso(texto: 'MAMA LLEVA CANASTA', pista: 'Mamá lleva canasta', emoji: '🧺'),
];

const _pasosFrasesMezcla = [
  EscrituraPaso(texto: 'MI PAPA RIEGA', pista: 'Mi papá riega', emoji: '💧'),
  EscrituraPaso(texto: 'LA VACA COME', pista: 'La vaca come', emoji: '🐄'),
  EscrituraPaso(texto: 'MAMA USA PALA', pista: 'Mamá usa pala', emoji: '🪏'),
];

const _pasosOrdenAlfabetico = [
  EscrituraPaso(texto: 'A B C', pista: 'A B C en orden', emoji: '🔤'),
  EscrituraPaso(texto: 'D E F', pista: 'D E F en orden', emoji: '🔤'),
  EscrituraPaso(texto: 'M N Ñ', pista: 'M N Ñ en orden', emoji: '🔤'),
];

const _pasosPalabrasCortas = [
  EscrituraPaso(texto: 'MAMA', pista: 'MAMA', emoji: '👩'),
  EscrituraPaso(texto: 'PAPA', pista: 'PAPA', emoji: '👨'),
  EscrituraPaso(texto: 'MESA', pista: 'MESA', emoji: '🪑'),
  EscrituraPaso(texto: 'PUMA', pista: 'PUMA', emoji: '🐆'),
];

const _pasosPalabrasCampo = [
  EscrituraPaso(texto: 'MAIZ', pista: 'MAÍZ', emoji: '🌽'),
  EscrituraPaso(texto: 'PALA', pista: 'PALA', emoji: '🪏'),
  EscrituraPaso(texto: 'VACA', pista: 'VACA', emoji: '🐄'),
  EscrituraPaso(texto: 'RIEGO', pista: 'RIEGO', emoji: '💧'),
];

const _pasosPalabraImagenUno = [
  EscrituraPaso(texto: 'PALA', pista: 'PALA · imagen 🪏', emoji: '🪏'),
  EscrituraPaso(texto: 'MESA', pista: 'MESA · imagen 🪑', emoji: '🪑'),
  EscrituraPaso(texto: 'VACA', pista: 'VACA · imagen 🐄', emoji: '🐄'),
];

const _pasosPalabraImagenDos = [
  EscrituraPaso(texto: 'MAIZ', pista: 'MAÍZ · imagen 🌽', emoji: '🌽'),
  EscrituraPaso(texto: 'RIEGO', pista: 'RIEGO · imagen 💧', emoji: '💧'),
  EscrituraPaso(texto: 'MULA', pista: 'MULA · imagen 🐴', emoji: '🐴'),
];

const _pasosCompletarPalabraUno = [
  EscrituraPaso(texto: 'MAMA', pista: 'Completa: MA __', emoji: '👩'),
  EscrituraPaso(texto: 'PAPA', pista: 'Completa: PA __', emoji: '👨'),
  EscrituraPaso(texto: 'MAIZ', pista: 'Completa: MA __ Z', emoji: '🌽'),
];

const _pasosCompletarPalabraDos = [
  EscrituraPaso(texto: 'LANA', pista: 'Completa: LA __ A', emoji: '🧶'),
  EscrituraPaso(texto: 'SACO', pista: 'Completa: SA __ O', emoji: '🧺'),
  EscrituraPaso(texto: 'LAMA', pista: 'Completa: LA __ A', emoji: '🦙'),
];

const _pasosComprensionBasica = [
  EscrituraPaso(
    texto: 'EL CAMPESINO RIEGA MAIZ',
    pista: 'El campesino riega maíz',
    emoji: '🌽',
  ),
  EscrituraPaso(
    texto: 'LA VACA TOMA AGUA',
    pista: 'La vaca toma agua',
    emoji: '🐄',
  ),
  EscrituraPaso(
    texto: 'MAMA LLEVA LA PALA',
    pista: 'Mamá lleva la pala',
    emoji: '🪏',
  ),
];

const _pasosComprensionQuienQue = [
  EscrituraPaso(texto: 'PAPA SIEMBRA MAIZ', pista: 'Papá siembra maíz', emoji: '🌽'),
  EscrituraPaso(texto: 'MAMA VENDE QUESO', pista: 'Mamá vende queso', emoji: '🧀'),
  EscrituraPaso(
    texto: 'LA VACA COME PASTO',
    pista: 'La vaca come pasto',
    emoji: '🐄',
  ),
];

const _pasosComprensionDonde = [
  EscrituraPaso(
    texto: 'EL MAIZ ESTA EN LA CHACRA',
    pista: 'El maíz está en la chacra',
    emoji: '🌽',
  ),
  EscrituraPaso(
    texto: 'LA VACA ESTA EN EL CORRAL',
    pista: 'La vaca está en el corral',
    emoji: '🐄',
  ),
  EscrituraPaso(
    texto: 'LA PALA ESTA EN LA BODEGA',
    pista: 'La pala está en la bodega',
    emoji: '🪏',
  ),
];

const _pasosSecuenciaBasica = [
  EscrituraPaso(
    texto: 'PRIMERO SIEMBRA DESPUES RIEGA',
    pista: 'Primero siembra, después riega',
    emoji: '🌱',
  ),
  EscrituraPaso(
    texto: 'PRIMERO COSECHA DESPUES VENDE',
    pista: 'Primero cosecha, después vende',
    emoji: '🛒',
  ),
  EscrituraPaso(
    texto: 'PRIMERO ORDEÑA DESPUES GUARDA',
    pista: 'Primero ordeña, después guarda',
    emoji: '🥛',
  ),
];

const _pasosVocabularioContextual = [
  EscrituraPaso(texto: 'COSECHA', pista: 'Recoger del cultivo', emoji: '🌾'),
  EscrituraPaso(texto: 'MERCADO', pista: 'Donde se vende', emoji: '🏪'),
  EscrituraPaso(texto: 'SEMILLA', pista: 'Para sembrar', emoji: '🌱'),
  EscrituraPaso(texto: 'SURCO', pista: 'En el campo', emoji: '🚜'),
];

EscrituraGuiadaConfig _cfgFrases({
  required String titulo,
  required List<EscrituraPaso> pasos,
  required bool esTrazos,
  String? introTrazos,
  String? introTeclado,
  String? finTrazos,
  String? finTeclado,
}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: titulo,
    nombreUnidad: 'Frase',
    introNarracion: esTrazos
        ? (introTrazos ?? 'Vamos a escribir frases simples con trazos')
        : (introTeclado ?? 'Vamos a escribir frases simples en el teclado'),
    mensajeCompletado: esTrazos
        ? (finTrazos ?? '¡Muy bien! Ya escribes frases con trazos')
        : (finTeclado ?? '¡Muy bien! Ya escribes frases en el teclado'),
    pasos: pasos,
  );
}

EscrituraGuiadaConfig _cfgPalabras({
  required bool esTrazos,
}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: 'Palabras comunes',
    nombreUnidad: 'Palabra',
    introNarracion: esTrazos
        ? 'Vamos a escribir palabras comunes con trazos'
        : 'Vamos a escribir palabras comunes en el teclado',
    mensajeCompletado: esTrazos
        ? '¡Muy bien! Ya escribes palabras con trazos'
        : '¡Muy bien! Ya escribes palabras en el teclado',
    pasos: _pasosPalabrasComunes,
  );
}

EscrituraGuiadaConfig _cfgOrdenAlfabetico({required bool esTrazos}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: 'Orden alfabético básico',
    nombreUnidad: 'Grupo',
    introNarracion: esTrazos
        ? 'Vamos a escribir letras en orden alfabético con trazos'
        : 'Vamos a escribir letras en orden alfabético en el teclado',
    mensajeCompletado: esTrazos
        ? '¡Muy bien! Ya escribes grupos en orden alfabético'
        : '¡Muy bien! Ya dominas el orden alfabético en el teclado',
    pasos: _pasosOrdenAlfabetico,
  );
}

EscrituraGuiadaConfig _cfgPalabrasTema({
  required String titulo,
  required List<EscrituraPaso> pasos,
  required bool esTrazos,
  required String introTrazos,
  required String introTeclado,
  required String finTrazos,
  required String finTeclado,
}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: titulo,
    nombreUnidad: 'Palabra',
    introNarracion: esTrazos ? introTrazos : introTeclado,
    mensajeCompletado: esTrazos ? finTrazos : finTeclado,
    pasos: pasos,
  );
}

EscrituraGuiadaConfig _cfgComprension({
  required String titulo,
  required List<EscrituraPaso> pasos,
  required bool esTrazos,
  required String introTrazos,
  required String introTeclado,
  required String finTrazos,
  required String finTeclado,
  String nombreUnidad = 'Escritura',
}) {
  return EscrituraGuiadaConfig(
    tituloNarrado: titulo,
    nombreUnidad: nombreUnidad,
    introNarracion: esTrazos ? introTrazos : introTeclado,
    mensajeCompletado: esTrazos ? finTrazos : finTeclado,
    pasos: pasos,
  );
}

final Map<String, EscrituraGuiadaConfig> escrituraTrazosConfigs = {
  kFlujoEscrituraTrazosSilabasMaId: _cfgSilabas(
    titulo: 'Sílabas MA-ME-MI-MO-MU',
    pasos: _pasosSilabasMa,
    introTrazos: 'Vamos a escribir sílabas con M',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes las sílabas con M',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosSilabasPaId: _cfgSilabas(
    titulo: 'Sílabas PA-PE-PI-PO-PU',
    pasos: _pasosSilabasPa,
    introTrazos: 'Vamos a escribir sílabas con P',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes las sílabas con P',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosSilabasLaId: _cfgSilabas(
    titulo: 'Sílabas LA-LE-LI-LO-LU',
    pasos: _pasosSilabasLa,
    introTrazos: 'Vamos a escribir sílabas con L',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes las sílabas con L',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosSilabasTaId: _cfgSilabas(
    titulo: 'Sílabas TA-TE-TI-TO-TU',
    pasos: _pasosSilabasTa,
    introTrazos: 'Vamos a escribir sílabas con T',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes las sílabas con T',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosSilabasSaId: _cfgSilabas(
    titulo: 'Sílabas SA-SE-SI-SO-SU',
    pasos: _pasosSilabasSa,
    introTrazos: 'Vamos a escribir sílabas con S',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes las sílabas con S',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosSilabasMezclaId: _cfgSilabas(
    titulo: 'Mezcla de sílabas',
    pasos: _pasosSilabasMezcla,
    introTrazos: 'Vamos a repasar sílabas mezcladas con trazos',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya dominas la mezcla de sílabas',
    finTeclado: '',
    esTrazos: true,
  ),
  kFlujoEscrituraTrazosPalabrasComunesId: _cfgPalabras(esTrazos: true),
  kFlujoEscrituraTrazosFrasesCortasId: _cfgFrases(
    titulo: 'Frases cortas',
    pasos: _pasosFrasesCortas,
    esTrazos: true,
    introTrazos: 'Vamos a escribir frases cortas con trazos',
    finTrazos: '¡Muy bien! Ya escribes frases cortas',
  ),
  kFlujoEscrituraTrazosFrasesRutinaUnoId: _cfgFrases(
    titulo: 'Frases de rutina agrícola 1',
    pasos: _pasosFrasesRutinaUno,
    esTrazos: true,
    introTrazos: 'Frases del campo con trazos',
    finTrazos: '¡Muy bien! Frases de rutina con trazos',
  ),
  kFlujoEscrituraTrazosFrasesRutinaDosId: _cfgFrases(
    titulo: 'Frases de rutina agrícola 2',
    pasos: _pasosFrasesRutinaDos,
    esTrazos: true,
    introTrazos: 'Más frases del campo con trazos',
    finTrazos: '¡Muy bien! Sigues con frases del campo',
  ),
  kFlujoEscrituraTrazosFrasesOrdenId: _cfgFrases(
    titulo: 'Construir frases en orden',
    pasos: _pasosFrasesOrden,
    esTrazos: true,
    introTrazos: 'Construye frases en el orden correcto',
    finTrazos: '¡Muy bien! Ordenas frases con trazos',
  ),
  kFlujoEscrituraTrazosFrasesImagenId: _cfgFrases(
    titulo: 'Frases con imagen',
    pasos: _pasosFrasesImagen,
    esTrazos: true,
    introTrazos: 'Escribe frases que describen la imagen',
    finTrazos: '¡Muy bien! Frases con imagen en trazos',
  ),
  kFlujoEscrituraTrazosFrasesMezclaId: _cfgFrases(
    titulo: 'Mezcla de frases',
    pasos: _pasosFrasesMezcla,
    esTrazos: true,
    introTrazos: 'Repaso de frases simples con trazos',
    finTrazos: '¡Muy bien! Dominas frases simples',
  ),
  kFlujoEscrituraTrazosOrdenAlfabeticoId: _cfgOrdenAlfabetico(esTrazos: true),
  kFlujoEscrituraTrazosPalabrasCortasId: _cfgPalabrasTema(
    titulo: 'Palabras cortas',
    pasos: _pasosPalabrasCortas,
    esTrazos: true,
    introTrazos: 'Vamos a escribir palabras cortas con trazos',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes palabras cortas',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosPalabrasCampoId: _cfgPalabrasTema(
    titulo: 'Palabras del campo',
    pasos: _pasosPalabrasCampo,
    esTrazos: true,
    introTrazos: 'Palabras del campo con trazos',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya escribes palabras del campo',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosPalabraImagenUnoId: _cfgPalabrasTema(
    titulo: 'Asociación palabra-imagen 1',
    pasos: _pasosPalabraImagenUno,
    esTrazos: true,
    introTrazos: 'Escribe la palabra que corresponde a cada imagen',
    introTeclado: '',
    finTrazos: '¡Muy bien! Asocias palabras e imágenes',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosPalabraImagenDosId: _cfgPalabrasTema(
    titulo: 'Asociación palabra-imagen 2',
    pasos: _pasosPalabraImagenDos,
    esTrazos: true,
    introTrazos: 'Más palabras según la imagen con trazos',
    introTeclado: '',
    finTrazos: '¡Muy bien! Sigues con palabra e imagen',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosCompletarPalabraUnoId: _cfgPalabrasTema(
    titulo: 'Completa palabras MA y PA',
    pasos: _pasosCompletarPalabraUno,
    esTrazos: true,
    introTrazos: 'Completa y escribe palabras con MA y PA',
    introTeclado: '',
    finTrazos: '¡Muy bien! Completas palabras con trazos',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosCompletarPalabraDosId: _cfgPalabrasTema(
    titulo: 'Completa palabras LA y SA',
    pasos: _pasosCompletarPalabraDos,
    esTrazos: true,
    introTrazos: 'Completa y escribe palabras con LA y SA',
    introTeclado: '',
    finTrazos: '¡Muy bien! Completas más palabras',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosComprensionBasicaId: _cfgComprension(
    titulo: 'Comprensión básica',
    pasos: _pasosComprensionBasica,
    esTrazos: true,
    introTrazos: 'Escribe frases que entiendes del campo',
    introTeclado: '',
    finTrazos: '¡Muy bien! Comprendes y escribes frases',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosComprensionQuienQueId: _cfgComprension(
    titulo: 'Comprensión: quién y qué',
    pasos: _pasosComprensionQuienQue,
    esTrazos: true,
    introTrazos: 'Escribe quién hace qué en el campo',
    introTeclado: '',
    finTrazos: '¡Muy bien! Identificas quién y qué',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosComprensionDondeId: _cfgComprension(
    titulo: 'Comprensión: dónde',
    pasos: _pasosComprensionDonde,
    esTrazos: true,
    introTrazos: 'Escribe dónde están las cosas del campo',
    introTeclado: '',
    finTrazos: '¡Muy bien! Escribes dónde está cada cosa',
    finTeclado: '',
  ),
  kFlujoEscrituraTrazosSecuenciaBasicaId: _cfgComprension(
    titulo: 'Secuencia: primero y después',
    pasos: _pasosSecuenciaBasica,
    esTrazos: true,
    introTrazos: 'Escribe secuencias del trabajo en el campo',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ordenas primero y después',
    finTeclado: '',
    nombreUnidad: 'Secuencia',
  ),
  kFlujoEscrituraTrazosVocabularioContextualId: _cfgComprension(
    titulo: 'Vocabulario contextual',
    pasos: _pasosVocabularioContextual,
    esTrazos: true,
    introTrazos: 'Escribe palabras importantes del campo',
    introTeclado: '',
    finTrazos: '¡Muy bien! Ya dominas vocabulario del campo',
    finTeclado: '',
  ),
};

final Map<String, EscrituraGuiadaConfig> escrituraTecladoConfigs = {
  kFlujoEscrituraTecladoSilabasMaId: _cfgSilabas(
    titulo: 'Sílabas MA-ME-MI-MO-MU',
    pasos: _pasosSilabasMa,
    introTrazos: '',
    introTeclado: 'Vamos a escribir sílabas con M en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya escribes las sílabas con M en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoSilabasPaId: _cfgSilabas(
    titulo: 'Sílabas PA-PE-PI-PO-PU',
    pasos: _pasosSilabasPa,
    introTrazos: '',
    introTeclado: 'Vamos a escribir sílabas con P en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya escribes las sílabas con P en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoSilabasLaId: _cfgSilabas(
    titulo: 'Sílabas LA-LE-LI-LO-LU',
    pasos: _pasosSilabasLa,
    introTrazos: '',
    introTeclado: 'Vamos a escribir sílabas con L en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya escribes las sílabas con L en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoSilabasTaId: _cfgSilabas(
    titulo: 'Sílabas TA-TE-TI-TO-TU',
    pasos: _pasosSilabasTa,
    introTrazos: '',
    introTeclado: 'Vamos a escribir sílabas con T en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya escribes las sílabas con T en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoSilabasSaId: _cfgSilabas(
    titulo: 'Sílabas SA-SE-SI-SO-SU',
    pasos: _pasosSilabasSa,
    introTrazos: '',
    introTeclado: 'Vamos a escribir sílabas con S en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya escribes las sílabas con S en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoSilabasMezclaId: _cfgSilabas(
    titulo: 'Mezcla de sílabas',
    pasos: _pasosSilabasMezcla,
    introTrazos: '',
    introTeclado: 'Vamos a repasar sílabas mezcladas en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Ya dominas la mezcla en el teclado',
    esTrazos: false,
  ),
  kFlujoEscrituraTecladoPalabrasComunesId: _cfgPalabras(esTrazos: false),
  kFlujoEscrituraTecladoFrasesCortasId: _cfgFrases(
    titulo: 'Frases cortas',
    pasos: _pasosFrasesCortas,
    esTrazos: false,
    introTeclado: 'Escribe frases cortas en el teclado',
    finTeclado: '¡Muy bien! Frases cortas en el teclado',
  ),
  kFlujoEscrituraTecladoFrasesRutinaUnoId: _cfgFrases(
    titulo: 'Frases de rutina agrícola 1',
    pasos: _pasosFrasesRutinaUno,
    esTrazos: false,
    introTeclado: 'Frases del campo en el teclado',
    finTeclado: '¡Muy bien! Frases de rutina en el teclado',
  ),
  kFlujoEscrituraTecladoFrasesRutinaDosId: _cfgFrases(
    titulo: 'Frases de rutina agrícola 2',
    pasos: _pasosFrasesRutinaDos,
    esTrazos: false,
    introTeclado: 'Más frases del campo en el teclado',
    finTeclado: '¡Muy bien! Sigues con frases del campo',
  ),
  kFlujoEscrituraTecladoFrasesOrdenId: _cfgFrases(
    titulo: 'Construir frases en orden',
    pasos: _pasosFrasesOrden,
    esTrazos: false,
    introTeclado: 'Ordena y escribe frases en el teclado',
    finTeclado: '¡Muy bien! Ordenas frases en el teclado',
  ),
  kFlujoEscrituraTecladoFrasesImagenId: _cfgFrases(
    titulo: 'Frases con imagen',
    pasos: _pasosFrasesImagen,
    esTrazos: false,
    introTeclado: 'Escribe frases según la imagen',
    finTeclado: '¡Muy bien! Frases con imagen en el teclado',
  ),
  kFlujoEscrituraTecladoFrasesMezclaId: _cfgFrases(
    titulo: 'Mezcla de frases',
    pasos: _pasosFrasesMezcla,
    esTrazos: false,
    introTeclado: 'Repaso de frases en el teclado',
    finTeclado: '¡Muy bien! Dominas frases en el teclado',
  ),
  kFlujoEscrituraTecladoOrdenAlfabeticoId: _cfgOrdenAlfabetico(esTrazos: false),
  kFlujoEscrituraTecladoPalabrasCortasId: _cfgPalabrasTema(
    titulo: 'Palabras cortas',
    pasos: _pasosPalabrasCortas,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe palabras cortas en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Palabras cortas en el teclado',
  ),
  kFlujoEscrituraTecladoPalabrasCampoId: _cfgPalabrasTema(
    titulo: 'Palabras del campo',
    pasos: _pasosPalabrasCampo,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Palabras del campo en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Palabras del campo en el teclado',
  ),
  kFlujoEscrituraTecladoPalabraImagenUnoId: _cfgPalabrasTema(
    titulo: 'Asociación palabra-imagen 1',
    pasos: _pasosPalabraImagenUno,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe la palabra de cada imagen',
    finTrazos: '',
    finTeclado: '¡Muy bien! Palabra e imagen en el teclado',
  ),
  kFlujoEscrituraTecladoPalabraImagenDosId: _cfgPalabrasTema(
    titulo: 'Asociación palabra-imagen 2',
    pasos: _pasosPalabraImagenDos,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Más palabras según la imagen',
    finTrazos: '',
    finTeclado: '¡Muy bien! Sigues con palabra e imagen',
  ),
  kFlujoEscrituraTecladoCompletarPalabraUnoId: _cfgPalabrasTema(
    titulo: 'Completa palabras MA y PA',
    pasos: _pasosCompletarPalabraUno,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Completa palabras con MA y PA en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Completas palabras en el teclado',
  ),
  kFlujoEscrituraTecladoCompletarPalabraDosId: _cfgPalabrasTema(
    titulo: 'Completa palabras LA y SA',
    pasos: _pasosCompletarPalabraDos,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Completa palabras con LA y SA en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Completas más palabras',
  ),
  kFlujoEscrituraTecladoComprensionBasicaId: _cfgComprension(
    titulo: 'Comprensión básica',
    pasos: _pasosComprensionBasica,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe frases que comprendes del campo',
    finTrazos: '',
    finTeclado: '¡Muy bien! Comprendes y escribes en el teclado',
  ),
  kFlujoEscrituraTecladoComprensionQuienQueId: _cfgComprension(
    titulo: 'Comprensión: quién y qué',
    pasos: _pasosComprensionQuienQue,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe quién hace qué en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Quién y qué en el teclado',
  ),
  kFlujoEscrituraTecladoComprensionDondeId: _cfgComprension(
    titulo: 'Comprensión: dónde',
    pasos: _pasosComprensionDonde,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe dónde están las cosas',
    finTrazos: '',
    finTeclado: '¡Muy bien! Dónde en el teclado',
  ),
  kFlujoEscrituraTecladoSecuenciaBasicaId: _cfgComprension(
    titulo: 'Secuencia: primero y después',
    pasos: _pasosSecuenciaBasica,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe secuencias en el teclado',
    finTrazos: '',
    finTeclado: '¡Muy bien! Secuencias en el teclado',
    nombreUnidad: 'Secuencia',
  ),
  kFlujoEscrituraTecladoVocabularioContextualId: _cfgComprension(
    titulo: 'Vocabulario contextual',
    pasos: _pasosVocabularioContextual,
    esTrazos: false,
    introTrazos: '',
    introTeclado: 'Escribe vocabulario del campo',
    finTrazos: '',
    finTeclado: '¡Muy bien! Vocabulario en el teclado',
  ),
};

EscrituraGuiadaConfig? escrituraTrazosConfigForLeccion(String? flujoId) =>
    escrituraTrazosConfigs[flujoId];

EscrituraGuiadaConfig? escrituraTecladoConfigForLeccion(String? flujoId) =>
    escrituraTecladoConfigs[flujoId];
