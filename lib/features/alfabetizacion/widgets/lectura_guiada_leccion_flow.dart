import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import 'alfabetizacion_lesson_feedback.dart';
import 'alfabetizacion_lesson_shell.dart';

class LecturaGuiadaLeccionFlow extends StatefulWidget {
  const LecturaGuiadaLeccionFlow({
    super.key,
    required this.leccion,
    required this.onCompletar,
    required this.config,
  });

  final LeccionData leccion;
  final Future<void> Function() onCompletar;
  final LecturaGuiadaConfig config;

  static LecturaGuiadaConfig? configForLeccion(LeccionData leccion) {
    return _configsPorFlujo[leccion.flujoId];
  }

  @override
  State<LecturaGuiadaLeccionFlow> createState() => _LecturaGuiadaLeccionFlowState();
}

class LecturaPaso {
  const LecturaPaso({
    required this.texto,
    required this.pista,
    required this.emoji,
  });

  final String texto;
  final String pista;
  final String emoji;
}

typedef _LecturaPaso = LecturaPaso;

class EjercicioActividad {
  const EjercicioActividad({
    required this.textoPregunta,
    required this.audioInstruccion,
    required this.opciones,
    required this.correcta,
    required this.emojiIlustracion,
  });

  final String textoPregunta;
  final String audioInstruccion;
  final List<String> opciones;
  final String correcta;
  final String emojiIlustracion;
}

typedef _EjercicioActividad = EjercicioActividad;

class LecturaGuiadaConfig {
  const LecturaGuiadaConfig({
    required this.tituloNarrado,
    required this.nombreUnidad,
    required this.pasos,
    required this.ejercicios,
  });

  final String tituloNarrado;
  final String nombreUnidad;
  final List<LecturaPaso> pasos;
  final List<EjercicioActividad> ejercicios;
}

const Map<String?, LecturaGuiadaConfig> _configsPorFlujo = {
  kFlujoOrdenAlfabeticoBasicoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Orden alfabético básico',
    nombreUnidad: 'Grupo',
    pasos: [
      LecturaPaso(texto: 'A B C', pista: 'A B C', emoji: '🔤'),
      LecturaPaso(texto: 'D E F', pista: 'D E F', emoji: '🔤'),
      LecturaPaso(texto: 'M N Ñ', pista: 'M N Ñ', emoji: '🔤'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona el grupo en orden correcto',
        audioInstruccion: 'Selecciona el grupo en orden correcto',
        opciones: ['A B C', 'A C B', 'C A B'],
        correcta: 'A B C',
        emojiIlustracion: '🔤',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Qué letra va después de M?',
        audioInstruccion: '¿Qué letra va después de M?',
        opciones: ['N', 'P', 'L'],
        correcta: 'N',
        emojiIlustracion: '🔠',
      ),
    ],
  ),
  kFlujoSilabasDirectasGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Sílabas directas uno',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'MA', pista: 'MA de mano', emoji: '✋'),
      _LecturaPaso(texto: 'ME', pista: 'ME de mesa', emoji: '🪑'),
      _LecturaPaso(texto: 'MI', pista: 'MI de maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'MO', pista: 'MO de molino', emoji: '🌾'),
      _LecturaPaso(texto: 'MU', pista: 'MU de mula', emoji: '🐴'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba MA',
        audioInstruccion: 'Selecciona la sílaba MA',
        opciones: ['MA', 'ME', 'MI'],
        correcta: 'MA',
        emojiIlustracion: '✋',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál es la sílaba MO?',
        audioInstruccion: '¿Cuál es la sílaba MO?',
        opciones: ['MU', 'MO', 'MA'],
        correcta: 'MO',
        emojiIlustracion: '🌾',
      ),
    ],
  ),
  kFlujoSilabasDirectasDosGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Sílabas directas dos',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'PA', pista: 'PA de pala', emoji: '🪏'),
      _LecturaPaso(texto: 'PE', pista: 'PE de pera', emoji: '🍐'),
      _LecturaPaso(texto: 'PI', pista: 'PI de pila', emoji: '🔋'),
      _LecturaPaso(texto: 'PO', pista: 'PO de pozo', emoji: '🪣'),
      _LecturaPaso(texto: 'PU', pista: 'PU de pulpa', emoji: '🍊'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba PE',
        audioInstruccion: 'Selecciona la sílaba PE',
        opciones: ['PE', 'PA', 'PO'],
        correcta: 'PE',
        emojiIlustracion: '🍐',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál es la sílaba PU?',
        audioInstruccion: '¿Cuál es la sílaba PU?',
        opciones: ['PI', 'PU', 'PE'],
        correcta: 'PU',
        emojiIlustracion: '🍊',
      ),
    ],
  ),
  kFlujoSilabasDirectasTresGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Sílabas directas tres',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'LA', pista: 'LA de lana', emoji: '🧶'),
      _LecturaPaso(texto: 'LE', pista: 'LE de leche', emoji: '🥛'),
      _LecturaPaso(texto: 'LI', pista: 'LI de lima', emoji: '🍋'),
      _LecturaPaso(texto: 'LO', pista: 'LO de loma', emoji: '⛰️'),
      _LecturaPaso(texto: 'LU', pista: 'LU de luna', emoji: '🌙'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba LA',
        audioInstruccion: 'Selecciona la sílaba LA',
        opciones: ['LA', 'LE', 'LI'],
        correcta: 'LA',
        emojiIlustracion: '🧶',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál es la sílaba LU?',
        audioInstruccion: '¿Cuál es la sílaba LU?',
        opciones: ['LO', 'LU', 'LA'],
        correcta: 'LU',
        emojiIlustracion: '🌙',
      ),
    ],
  ),
  kFlujoSilabasDirectasCuatroGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Sílabas directas cuatro',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'TA', pista: 'TA de taza', emoji: '☕'),
      _LecturaPaso(texto: 'TE', pista: 'TE de tela', emoji: '🧵'),
      _LecturaPaso(texto: 'TI', pista: 'TI de tierra', emoji: '🌱'),
      _LecturaPaso(texto: 'TO', pista: 'TO de tomate', emoji: '🍅'),
      _LecturaPaso(texto: 'TU', pista: 'TU de túnel', emoji: '🚇'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba TO',
        audioInstruccion: 'Selecciona la sílaba TO',
        opciones: ['TU', 'TA', 'TO'],
        correcta: 'TO',
        emojiIlustracion: '🍅',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál es la sílaba TI?',
        audioInstruccion: '¿Cuál es la sílaba TI?',
        opciones: ['TE', 'TI', 'TA'],
        correcta: 'TI',
        emojiIlustracion: '🌱',
      ),
    ],
  ),
  kFlujoSilabasDirectasCincoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Sílabas directas cinco',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'SA', pista: 'SA de saco', emoji: '🧺'),
      _LecturaPaso(texto: 'SE', pista: 'SE de semilla', emoji: '🌱'),
      _LecturaPaso(texto: 'SI', pista: 'SI de silla', emoji: '🪑'),
      _LecturaPaso(texto: 'SO', pista: 'SO de sol', emoji: '☀️'),
      _LecturaPaso(texto: 'SU', pista: 'SU de surco', emoji: '🚜'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba SE',
        audioInstruccion: 'Selecciona la sílaba SE',
        opciones: ['SA', 'SE', 'SI'],
        correcta: 'SE',
        emojiIlustracion: '🌱',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál es la sílaba SU?',
        audioInstruccion: '¿Cuál es la sílaba SU?',
        opciones: ['SO', 'SU', 'SE'],
        correcta: 'SU',
        emojiIlustracion: '🚜',
      ),
    ],
  ),
  kFlujoSilabasMezclaGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Mezcla de sílabas',
    nombreUnidad: 'Sílaba',
    pasos: [
      _LecturaPaso(texto: 'MA', pista: 'MA', emoji: '🔠'),
      _LecturaPaso(texto: 'PA', pista: 'PA', emoji: '🔠'),
      _LecturaPaso(texto: 'LA', pista: 'LA', emoji: '🔠'),
      _LecturaPaso(texto: 'SA', pista: 'SA', emoji: '🔠'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la sílaba PA',
        audioInstruccion: 'Selecciona la sílaba PA',
        opciones: ['MA', 'LA', 'PA'],
        correcta: 'PA',
        emojiIlustracion: '🔤',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál combinación está correcta?',
        audioInstruccion: '¿Cuál combinación está correcta?',
        opciones: ['MA SA', 'SA PA', 'LA MA'],
        correcta: 'SA PA',
        emojiIlustracion: '🔡',
      ),
    ],
  ),
  kFlujoPalabrasCortasGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Palabras cortas',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'MAMA', pista: 'MAMA', emoji: '👩'),
      _LecturaPaso(texto: 'PAPA', pista: 'PAPA', emoji: '👨'),
      _LecturaPaso(texto: 'MESA', pista: 'MESA', emoji: '🪑'),
      _LecturaPaso(texto: 'PUMA', pista: 'PUMA', emoji: '🐆'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la palabra MAMA',
        audioInstruccion: 'Selecciona la palabra MAMA',
        opciones: ['MAMA', 'PAPA', 'MESA'],
        correcta: 'MAMA',
        emojiIlustracion: '👩',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál palabra dice PUMA?',
        audioInstruccion: '¿Cuál palabra dice PUMA?',
        opciones: ['PUMA', 'MULA', 'PAPA'],
        correcta: 'PUMA',
        emojiIlustracion: '🐆',
      ),
    ],
  ),
  kFlujoPalabrasCampoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Palabras del campo',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'MAIZ', pista: 'MAÍZ', emoji: '🌽'),
      _LecturaPaso(texto: 'PALA', pista: 'PALA', emoji: '🪏'),
      _LecturaPaso(texto: 'VACA', pista: 'VACA', emoji: '🐄'),
      _LecturaPaso(texto: 'RIEGO', pista: 'RIEGO', emoji: '💧'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la palabra VACA',
        audioInstruccion: 'Selecciona la palabra VACA',
        opciones: ['VACA', 'PALA', 'CASA'],
        correcta: 'VACA',
        emojiIlustracion: '🐄',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál palabra corresponde al agua en el cultivo?',
        audioInstruccion: '¿Cuál palabra corresponde al agua en el cultivo?',
        opciones: ['RIEGO', 'MAIZ', 'MULA'],
        correcta: 'RIEGO',
        emojiIlustracion: '💧',
      ),
    ],
  ),
  kFlujoPalabraImagenUnoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Asociación palabra imagen uno',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'PALA', pista: 'PALA', emoji: '🪏'),
      _LecturaPaso(texto: 'MESA', pista: 'MESA', emoji: '🪑'),
      _LecturaPaso(texto: 'VACA', pista: 'VACA', emoji: '🐄'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la palabra de la imagen 🪏',
        audioInstruccion: 'Selecciona la palabra de la pala',
        opciones: ['PALA', 'MESA', 'VACA'],
        correcta: 'PALA',
        emojiIlustracion: '🪏',
      ),
      _EjercicioActividad(
        textoPregunta: 'Selecciona la palabra de la imagen 🐄',
        audioInstruccion: 'Selecciona la palabra de la vaca',
        opciones: ['MULA', 'VACA', 'PALA'],
        correcta: 'VACA',
        emojiIlustracion: '🐄',
      ),
    ],
  ),
  kFlujoPalabraImagenDosGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Asociación palabra imagen dos',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'MAIZ', pista: 'MAÍZ', emoji: '🌽'),
      _LecturaPaso(texto: 'RIEGO', pista: 'RIEGO', emoji: '💧'),
      _LecturaPaso(texto: 'MULA', pista: 'MULA', emoji: '🐴'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: '¿Cuál palabra corresponde a 🌽?',
        audioInstruccion: '¿Cuál palabra corresponde a maíz?',
        opciones: ['MULA', 'MAIZ', 'RIEGO'],
        correcta: 'MAIZ',
        emojiIlustracion: '🌽',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál palabra corresponde a 💧?',
        audioInstruccion: '¿Cuál palabra corresponde al riego?',
        opciones: ['RIEGO', 'PALA', 'MESA'],
        correcta: 'RIEGO',
        emojiIlustracion: '💧',
      ),
    ],
  ),
  kFlujoCompletarPalabraUnoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Completar palabras uno',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'MA _ _', pista: 'MA MA', emoji: '👩'),
      _LecturaPaso(texto: 'PA _ _', pista: 'PA PA', emoji: '👨'),
      _LecturaPaso(texto: 'MA _ Z', pista: 'MA IZ', emoji: '🌽'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Completa: MA _ _',
        audioInstruccion: 'Completa la palabra ma',
        opciones: ['MAMA', 'PALA', 'MESA'],
        correcta: 'MAMA',
        emojiIlustracion: '👩',
      ),
      _EjercicioActividad(
        textoPregunta: 'Completa: PA _ _',
        audioInstruccion: 'Completa la palabra pa',
        opciones: ['PAPA', 'VACA', 'MULA'],
        correcta: 'PAPA',
        emojiIlustracion: '👨',
      ),
    ],
  ),
  kFlujoCompletarPalabraDosGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Completar palabras dos',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'LA _ A', pista: 'LA NA', emoji: '🧶'),
      _LecturaPaso(texto: 'SA _ O', pista: 'SA CO', emoji: '🧺'),
      _LecturaPaso(texto: 'LA _ A', pista: 'LA MA', emoji: '🦙'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Completa: SA _ O',
        audioInstruccion: 'Completa saco',
        opciones: ['SACO', 'LANA', 'MESA'],
        correcta: 'SACO',
        emojiIlustracion: '🧺',
      ),
      _EjercicioActividad(
        textoPregunta: 'Completa: LA _ A',
        audioInstruccion: 'Completa lama',
        opciones: ['LAMA', 'PALA', 'VACA'],
        correcta: 'LAMA',
        emojiIlustracion: '🦙',
      ),
    ],
  ),
  kFlujoFrasesCortasGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Frases cortas',
    nombreUnidad: 'Frase',
    pasos: [
      _LecturaPaso(texto: 'MI MAMA ME AMA', pista: 'Mi mamá me ama', emoji: '❤️'),
      _LecturaPaso(texto: 'MI PAPA RIEGA', pista: 'Mi papá riega', emoji: '💧'),
      _LecturaPaso(texto: 'LA VACA COME', pista: 'La vaca come', emoji: '🐄'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la frase: MI PAPA RIEGA',
        audioInstruccion: 'Selecciona la frase mi papá riega',
        opciones: ['MI PAPA RIEGA', 'LA VACA COME', 'MI MAMA ME AMA'],
        correcta: 'MI PAPA RIEGA',
        emojiIlustracion: '💧',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál frase habla de la vaca?',
        audioInstruccion: '¿Cuál frase habla de la vaca?',
        opciones: ['LA VACA COME', 'MI MAMA ME AMA', 'MI PAPA RIEGA'],
        correcta: 'LA VACA COME',
        emojiIlustracion: '🐄',
      ),
    ],
  ),
  kFlujoFrasesRutinaUnoGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Frases de rutina agrícola uno',
    nombreUnidad: 'Frase',
    pasos: [
      _LecturaPaso(texto: 'PAPA USA LA PALA', pista: 'Papá usa la pala', emoji: '🪏'),
      _LecturaPaso(texto: 'MAMA RIEGA EL MAIZ', pista: 'Mamá riega el maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'LA VACA COME PASTO', pista: 'La vaca come pasto', emoji: '🐄'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la frase de la pala',
        audioInstruccion: 'Selecciona la frase de la pala',
        opciones: ['PAPA USA LA PALA', 'MAMA RIEGA EL MAIZ', 'LA VACA COME PASTO'],
        correcta: 'PAPA USA LA PALA',
        emojiIlustracion: '🪏',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál frase habla de regar?',
        audioInstruccion: '¿Cuál frase habla de regar?',
        opciones: ['LA VACA COME PASTO', 'MAMA RIEGA EL MAIZ', 'PAPA USA LA PALA'],
        correcta: 'MAMA RIEGA EL MAIZ',
        emojiIlustracion: '💧',
      ),
    ],
  ),
  kFlujoFrasesRutinaDosGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Frases de rutina agrícola dos',
    nombreUnidad: 'Frase',
    pasos: [
      _LecturaPaso(texto: 'EL CAMPESINO CARGA SACO', pista: 'El campesino carga saco', emoji: '🧺'),
      _LecturaPaso(texto: 'LA FAMILIA VENDE MAIZ', pista: 'La familia vende maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'EL RIEGO LLEGA AL SURCO', pista: 'El riego llega al surco', emoji: '🚜'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la frase del saco',
        audioInstruccion: 'Selecciona la frase del saco',
        opciones: ['EL CAMPESINO CARGA SACO', 'LA FAMILIA VENDE MAIZ', 'EL RIEGO LLEGA AL SURCO'],
        correcta: 'EL CAMPESINO CARGA SACO',
        emojiIlustracion: '🧺',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál frase habla de vender?',
        audioInstruccion: '¿Cuál frase habla de vender?',
        opciones: ['EL RIEGO LLEGA AL SURCO', 'LA FAMILIA VENDE MAIZ', 'EL CAMPESINO CARGA SACO'],
        correcta: 'LA FAMILIA VENDE MAIZ',
        emojiIlustracion: '🛒',
      ),
    ],
  ),
  kFlujoOrdenarFraseGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Ordenar frase',
    nombreUnidad: 'Frase',
    pasos: [
      _LecturaPaso(texto: 'MAMA / RIEGA / MAIZ', pista: 'Mamá riega maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'PAPA / USA / PALA', pista: 'Papá usa pala', emoji: '🪏'),
      _LecturaPaso(texto: 'VACA / TOMA / AGUA', pista: 'Vaca toma agua', emoji: '💧'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Elige la frase bien ordenada',
        audioInstruccion: 'Elige la frase bien ordenada',
        opciones: ['MAMA RIEGA MAIZ', 'RIEGA MAMA MAIZ', 'MAIZ MAMA RIEGA'],
        correcta: 'MAMA RIEGA MAIZ',
        emojiIlustracion: '🌽',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál oración está en orden correcto?',
        audioInstruccion: '¿Cuál oración está en orden correcto?',
        opciones: ['PALA USA PAPA', 'PAPA USA PALA', 'USA PAPA PALA'],
        correcta: 'PAPA USA PALA',
        emojiIlustracion: '🪏',
      ),
    ],
  ),
  kFlujoFraseImagenGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Frase según imagen',
    nombreUnidad: 'Frase',
    pasos: [
      _LecturaPaso(texto: 'LA VACA TOMA AGUA', pista: 'La vaca toma agua', emoji: '🐄'),
      _LecturaPaso(texto: 'EL CAMPESINO SIEMBRA', pista: 'El campesino siembra', emoji: '🌱'),
      _LecturaPaso(texto: 'MAMA LLEVA LA CANASTA', pista: 'Mamá lleva la canasta', emoji: '🧺'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la frase para la imagen 🐄💧',
        audioInstruccion: 'Selecciona la frase de la vaca tomando agua',
        opciones: ['LA VACA TOMA AGUA', 'EL CAMPESINO SIEMBRA', 'MAMA LLEVA LA CANASTA'],
        correcta: 'LA VACA TOMA AGUA',
        emojiIlustracion: '🐄',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Qué frase corresponde a 🌱?',
        audioInstruccion: '¿Qué frase corresponde a sembrar?',
        opciones: ['EL CAMPESINO SIEMBRA', 'LA VACA TOMA AGUA', 'MAMA LLEVA LA CANASTA'],
        correcta: 'EL CAMPESINO SIEMBRA',
        emojiIlustracion: '🌱',
      ),
    ],
  ),
  kFlujoComprensionBasicaGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Comprensión básica',
    nombreUnidad: 'Lectura',
    pasos: [
      _LecturaPaso(texto: 'EL CAMPESINO RIEGA MAIZ', pista: 'El campesino riega maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'LA VACA TOMA AGUA', pista: 'La vaca toma agua', emoji: '🐄'),
      _LecturaPaso(texto: 'MAMA LLEVA LA PALA', pista: 'Mamá lleva la pala', emoji: '🪏'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'En la frase “EL CAMPESINO RIEGA MAIZ”, ¿qué riega?',
        audioInstruccion: 'En la frase el campesino riega maíz, ¿qué riega?',
        opciones: ['MAIZ', 'VACA', 'PALA'],
        correcta: 'MAIZ',
        emojiIlustracion: '🌽',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Quién toma agua?',
        audioInstruccion: '¿Quién toma agua?',
        opciones: ['LA VACA', 'MAMA', 'EL PAPA'],
        correcta: 'LA VACA',
        emojiIlustracion: '🐄',
      ),
    ],
  ),
  kFlujoComprensionQuienQueGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Comprensión quién y qué',
    nombreUnidad: 'Lectura',
    pasos: [
      _LecturaPaso(texto: 'PAPA SIEMBRA MAIZ', pista: 'Papá siembra maíz', emoji: '🌽'),
      _LecturaPaso(texto: 'MAMA VENDE QUESO', pista: 'Mamá vende queso', emoji: '🧀'),
      _LecturaPaso(texto: 'LA VACA COME PASTO', pista: 'La vaca come pasto', emoji: '🐄'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: '¿Quién siembra maíz?',
        audioInstruccion: '¿Quién siembra maíz?',
        opciones: ['PAPA', 'MAMA', 'LA VACA'],
        correcta: 'PAPA',
        emojiIlustracion: '🌽',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Qué vende mamá?',
        audioInstruccion: '¿Qué vende mamá?',
        opciones: ['QUESO', 'MAIZ', 'PALA'],
        correcta: 'QUESO',
        emojiIlustracion: '🧀',
      ),
    ],
  ),
  kFlujoComprensionDondeGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Comprensión dónde',
    nombreUnidad: 'Lectura',
    pasos: [
      _LecturaPaso(texto: 'EL MAIZ ESTA EN LA CHACRA', pista: 'El maíz está en la chacra', emoji: '🌽'),
      _LecturaPaso(texto: 'LA VACA ESTA EN EL CORRAL', pista: 'La vaca está en el corral', emoji: '🐄'),
      _LecturaPaso(texto: 'LA PALA ESTA EN LA BODEGA', pista: 'La pala está en la bodega', emoji: '🪏'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: '¿Dónde está la vaca?',
        audioInstruccion: '¿Dónde está la vaca?',
        opciones: ['EN EL CORRAL', 'EN LA CHACRA', 'EN LA CASA'],
        correcta: 'EN EL CORRAL',
        emojiIlustracion: '🐄',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Dónde está la pala?',
        audioInstruccion: '¿Dónde está la pala?',
        opciones: ['EN LA BODEGA', 'EN EL MERCADO', 'EN EL CORRAL'],
        correcta: 'EN LA BODEGA',
        emojiIlustracion: '🪏',
      ),
    ],
  ),
  kFlujoSecuenciaBasicaGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Secuencia primero y después',
    nombreUnidad: 'Secuencia',
    pasos: [
      _LecturaPaso(texto: 'PRIMERO SIEMBRA, DESPUES RIEGA', pista: 'Primero siembra, después riega', emoji: '🌱'),
      _LecturaPaso(texto: 'PRIMERO COSECHA, DESPUES VENDE', pista: 'Primero cosecha, después vende', emoji: '🛒'),
      _LecturaPaso(texto: 'PRIMERO ORDEÑA, DESPUES GUARDA', pista: 'Primero ordeña, después guarda', emoji: '🥛'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'En la secuencia de siembra, ¿qué va primero?',
        audioInstruccion: 'En la secuencia de siembra, ¿qué va primero?',
        opciones: ['SEMBRAR', 'REGAR', 'COSECHAR'],
        correcta: 'SEMBRAR',
        emojiIlustracion: '🌱',
      ),
      _EjercicioActividad(
        textoPregunta: 'Después de cosechar, ¿qué sigue?',
        audioInstruccion: 'Después de cosechar, ¿qué sigue?',
        opciones: ['VENDER', 'SEMBRAR', 'ORDENAR'],
        correcta: 'VENDER',
        emojiIlustracion: '🛒',
      ),
    ],
  ),
  kFlujoVocabularioContextualGuiadoId: LecturaGuiadaConfig(
    tituloNarrado: 'Vocabulario contextual',
    nombreUnidad: 'Palabra',
    pasos: [
      _LecturaPaso(texto: 'COSECHA', pista: 'COSECHA', emoji: '🌾'),
      _LecturaPaso(texto: 'MERCADO', pista: 'MERCADO', emoji: '🏪'),
      _LecturaPaso(texto: 'SEMILLA', pista: 'SEMILLA', emoji: '🌱'),
      _LecturaPaso(texto: 'SURCO', pista: 'SURCO', emoji: '🚜'),
    ],
    ejercicios: [
      _EjercicioActividad(
        textoPregunta: 'Selecciona la palabra que significa recoger del cultivo',
        audioInstruccion: 'Selecciona la palabra que significa recoger del cultivo',
        opciones: ['COSECHA', 'MERCADO', 'SEMILLA'],
        correcta: 'COSECHA',
        emojiIlustracion: '🌾',
      ),
      _EjercicioActividad(
        textoPregunta: '¿Cuál palabra se relaciona con vender productos?',
        audioInstruccion: '¿Cuál palabra se relaciona con vender productos?',
        opciones: ['MERCADO', 'SURCO', 'SEMILLA'],
        correcta: 'MERCADO',
        emojiIlustracion: '🏪',
      ),
    ],
  ),
};

enum _Fase { intro, presentacion, practica, actividad, recompensa }

class _LecturaGuiadaLeccionFlowState extends State<LecturaGuiadaLeccionFlow> {
  static const Color _azulHorizonte = Color(0xFF1A4463);

  final _tts = AlfabetizacionTtsCoach();
  bool _ttsListo = false;
  bool _introAudioYa = false;
  bool _progresoGuardado = false;

  _Fase _fase = _Fase.intro;
  int _indicePresentacion = 0;
  int _indicePractica = 0;
  int _indiceEjercicio = 0;

  bool _actividadBloqueada = false;
  bool _mostrarMuyBien = false;
  bool _mostrarIntentaDeNuevo = false;

  int _aciertoAnimacion = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _tts.isReady);
    await _reproducirIntroSiCorresponde();
  }

  @override
  void dispose() {
    unawaited(_tts.dispose());
    super.dispose();
  }

  bool _ttsFlujoOk() =>
      mounted && alfabetizacionTtsRouteActive(context);

  Future<void> _ttsDecir(String text, {bool slow = false}) =>
      _tts.speak(text, slow: slow, shouldContinue: _ttsFlujoOk);

  double get _progresoLineal {
    switch (_fase) {
      case _Fase.intro:
        return 1 / 6;
      case _Fase.presentacion:
        return 2 / 6;
      case _Fase.practica:
        return 3 / 6;
      case _Fase.actividad:
        final fraccion = (_indiceEjercicio + 1) / widget.config.ejercicios.length;
        return 4 / 6 + fraccion * (1 / 6);
      case _Fase.recompensa:
        return 1;
    }
  }

  String get _etiquetaPaso {
    switch (_fase) {
      case _Fase.intro:
        return 'Introducción';
      case _Fase.presentacion:
        return 'Enseñanza · ${_indicePresentacion + 1} de ${widget.config.pasos.length}';
      case _Fase.practica:
        return 'Práctica · ${_indicePractica + 1} de ${widget.config.pasos.length}';
      case _Fase.actividad:
        return 'Actividad · ${_indiceEjercicio + 1} de ${widget.config.ejercicios.length}';
      case _Fase.recompensa:
        return '¡Lección completada!';
    }
  }

  Future<void> _reproducirIntroSiCorresponde() async {
    if (_introAudioYa || _fase != _Fase.intro || !_ttsListo) return;
    _introAudioYa = true;
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted || _fase != _Fase.intro || !_ttsFlujoOk()) return;
    await _ttsDecir('Vamos a aprender ${widget.config.tituloNarrado}');
    if (!mounted || _fase != _Fase.intro || !_ttsFlujoOk()) return;
    await _ttsDecir('Primero enseñanza y luego práctica');
    if (!mounted || _fase != _Fase.intro || !_ttsFlujoOk()) return;
    await _ttsDecir('Pulsa el botón verde para empezar');
  }

  Future<void> _escucharIntroduccion() async {
    await _tts.interrupt();
    await _ttsDecir('Vamos a aprender ${widget.config.tituloNarrado}');
  }

  Future<void> _empezarPresentacion() async {
    await _tts.interrupt();
    if (!mounted) return;
    setState(() {
      _fase = _Fase.presentacion;
      _indicePresentacion = 0;
    });
    await _anunciarInstruccionesPresentacion();
  }

  Future<void> _anunciarInstruccionesPresentacion() async {
    final p = widget.config.pasos[_indicePresentacion];
    await _ttsDecir(p.pista);
    await _ttsDecir('Pulsa Escuchar si quieres oírla de nuevo');
    await _ttsDecir('Pulsa el botón verde para continuar');
  }

  Future<void> _repetirSonidoUnidadPresentacion() async {
    await _ttsDecir(widget.config.pasos[_indicePresentacion].texto, slow: true);
  }

  Future<void> _siguientePresentacion() async {
    await _tts.interrupt();
    if (!mounted) return;
    if (_indicePresentacion < widget.config.pasos.length - 1) {
      setState(() => _indicePresentacion++);
      await _anunciarInstruccionesPresentacion();
    } else {
      setState(() {
        _fase = _Fase.practica;
        _indicePractica = 0;
      });
      await _entradaPracticaActual();
    }
  }

  Future<void> _entradaPracticaActual() async {
    if (!mounted || _fase != _Fase.practica || !_ttsFlujoOk()) return;
    final p = widget.config.pasos[_indicePractica];
    await _ttsDecir('Escucha y repite');
    await _ttsDecir(p.texto, slow: true);
    await _ttsDecir('Toca el recuadro o pulsa Escuchar otra vez');
    await _ttsDecir('Pulsa el botón verde para continuar');
  }

  Future<void> _repetirPractica() async {
    await _ttsDecir(widget.config.pasos[_indicePractica].texto, slow: true);
  }

  Future<void> _siguientePractica() async {
    await _tts.interrupt();
    if (!mounted) return;
    if (_indicePractica < widget.config.pasos.length - 1) {
      setState(() => _indicePractica++);
      await _entradaPracticaActual();
    } else {
      setState(() {
        _fase = _Fase.actividad;
        _indiceEjercicio = 0;
        _actividadBloqueada = false;
        _mostrarMuyBien = false;
      });
      await _hablarInstruccionEjercicio();
    }
  }

  Future<void> _hablarInstruccionEjercicio() async {
    final ej = widget.config.ejercicios[_indiceEjercicio];
    await _ttsDecir('Selecciona la respuesta correcta');
    await _ttsDecir(ej.audioInstruccion);
  }

  Future<void> _elegirOpcionActividad(String opcion) async {
    if (_actividadBloqueada || _fase != _Fase.actividad) return;
    final ej = widget.config.ejercicios[_indiceEjercicio];
    if (opcion == ej.correcta) {
      setState(() {
        _actividadBloqueada = true;
        _mostrarMuyBien = true;
        _aciertoAnimacion++;
      });
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      await _ttsDecir('¡Muy bien!');
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      if (_indiceEjercicio < widget.config.ejercicios.length - 1) {
        setState(() {
          _indiceEjercicio++;
          _actividadBloqueada = false;
          _mostrarMuyBien = false;
        });
        await _hablarInstruccionEjercicio();
      } else {
        await _finalizarConRecompensa();
      }
    } else {
      setState(() {
        _mostrarIntentaDeNuevo = true;
      });
      await _ttsDecir('Intenta de nuevo');
      await _hablarInstruccionEjercicio();
      if (mounted) {
        setState(() {
          _mostrarIntentaDeNuevo = false;
        });
      }
    }
  }

  Future<void> _finalizarConRecompensa() async {
    if (!_progresoGuardado) {
      _progresoGuardado = true;
      await widget.onCompletar();
    }
    if (!mounted) return;
    setState(() {
      _fase = _Fase.recompensa;
      _mostrarMuyBien = false;
      _actividadBloqueada = false;
    });
    await _ttsDecir('Completaste la lección. Muy bien.');
    await _ttsDecir('Pulsa volver para regresar');
  }

  @override
  Widget build(BuildContext context) {
    return AlfabetizacionLessonShell(
      title: widget.leccion.titulo,
      subtitle: 'Lectura · Nivel ${widget.leccion.nivel}',
      progress: _progresoLineal,
      stepLabel: _etiquetaPaso,
      centerChild: _fase == _Fase.recompensa,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: KeyedSubtree(
          key: ValueKey((_fase, _indicePresentacion, _indicePractica, _indiceEjercicio)),
          child: _cuerpoFase(context),
        ),
      ),
    );
  }

  Widget _cuerpoFase(BuildContext context) {
    switch (_fase) {
      case _Fase.intro:
        return _buildIntro(context);
      case _Fase.presentacion:
        return _buildPresentacion(context);
      case _Fase.practica:
        return _buildPractica(context);
      case _Fase.actividad:
        return _buildActividad(context);
      case _Fase.recompensa:
        return _buildRecompensa(context);
    }
  }

  Widget _buildIntro(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AlfabetizacionLessonTokens.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.92),
                      scheme.tertiaryContainer.withValues(alpha: 0.65),
                      scheme.secondaryContainer.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 88, color: scheme.primary),
                    const SizedBox(height: 14),
                    Icon(Icons.record_voice_over_rounded, size: 58, color: scheme.tertiary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AlfabetizacionLessonSurface(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aprendizaje guiado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Primero aprendemos y luego practicamos.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _ttsListo ? _escucharIntroduccion : null,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Escuchar introducción'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: _azulHorizonte, width: 1.5),
                  foregroundColor: _azulHorizonte,
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _ttsListo ? _empezarPresentacion : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AlfabetizacionUiColors.verdeContinuar,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Empezar lección'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresentacion(BuildContext context) {
    final p = widget.config.pasos[_indicePresentacion];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlfabetizacionLessonSurface(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.config.nombreUnidad} ${_indicePresentacion + 1}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AlfabetizacionLessonTokens.accentBlue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                p.texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 88,
                      height: 1.05,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(p.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 76)),
              const SizedBox(height: 10),
              Text(
                p.pista,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _repetirSonidoUnidadPresentacion,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Escuchar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _azulHorizonte, width: 1.5),
            foregroundColor: _azulHorizonte,
            shape: const StadiumBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _siguientePresentacion,
          style: FilledButton.styleFrom(
            backgroundColor: AlfabetizacionUiColors.verdeContinuar,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: Text(_indicePresentacion < widget.config.pasos.length - 1 ? 'Siguiente' : 'Ir a la práctica'),
        ),
      ],
    );
  }

  Widget _buildPractica(BuildContext context) {
    final p = widget.config.pasos[_indicePractica];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escucha y repite',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        Material(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _repetirPractica,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Text(
                p.texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 104,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _repetirPractica,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Escuchar otra vez'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _azulHorizonte, width: 1.5),
            foregroundColor: _azulHorizonte,
            shape: const StadiumBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _siguientePractica,
          style: FilledButton.styleFrom(
            backgroundColor: AlfabetizacionUiColors.verdeContinuar,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: Text(_indicePractica < widget.config.pasos.length - 1 ? 'Siguiente' : 'Ir a la actividad'),
        ),
      ],
    );
  }

  Widget _buildActividad(BuildContext context) {
    final ej = widget.config.ejercicios[_indiceEjercicio];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mostrarMuyBien) ...[
          AlfabetizacionLessonCorrectBanner(animationTick: _aciertoAnimacion),
          const SizedBox(height: 12),
        ],
        if (_mostrarIntentaDeNuevo) ...[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Intenta de nuevo', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(ej.emojiIlustracion, style: const TextStyle(fontSize: 90)),
                const SizedBox(height: 10),
                Text(
                  ej.textoPregunta,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...ej.opciones.map(
          (op) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: _actividadBloqueada ? null : () => _elegirOpcionActividad(op),
              child: Text(op),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecompensa(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlfabetizacionLessonCompletionPanel(
          headline: '¡Lo lograste!',
          detail: 'Lección: ${widget.leccion.titulo}',
          pointsLabel: '+${widget.leccion.puntos} puntos',
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AlfabetizacionUiColors.verdeContinuar,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: const Text('Volver al módulo'),
        ),
      ],
    );
  }
}

