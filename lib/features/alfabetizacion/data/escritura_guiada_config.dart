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
};

EscrituraGuiadaConfig? escrituraTrazosConfigForLeccion(String? flujoId) =>
    escrituraTrazosConfigs[flujoId];

EscrituraGuiadaConfig? escrituraTecladoConfigForLeccion(String? flujoId) =>
    escrituraTecladoConfigs[flujoId];
