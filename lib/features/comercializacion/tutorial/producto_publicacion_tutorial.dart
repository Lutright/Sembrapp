import 'package:flutter/material.dart';

import '../../../core/tutorial/models/tutorial_step.dart';
import 'comercializacion_tutorial_keys.dart';

/// Pasos del tutorial de primera vez en "Añadir producto".
List<TutorialStep> buildProductoPublicacionTutorialSteps({
  required GlobalKey infoKey,
  required GlobalKey fotoKey,
  required GlobalKey nombreKey,
  required GlobalKey descripcionKey,
  required GlobalKey precioKey,
  required GlobalKey unidadKey,
  required GlobalKey guardarKey,
}) {
  return [
    TutorialStep(
      id: kTutorialProductoFormStepInfo,
      targetKey: infoKey,
      ttsPhrase:
          'Aquí te explican la disponibilidad. La cantidad exacta la acuerdas con el comprador.',
      hintText: 'Aviso de disponibilidad',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepFoto,
      targetKey: fotoKey,
      ttsPhrase:
          'Toca el recuadro para poner una foto de tu producto. Ayuda a que te compren más rápido.',
      hintText: 'Foto del producto',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepNombre,
      targetKey: nombreKey,
      ttsPhrase: 'Escribe el nombre como lo conocen en el mercado o en tu vereda.',
      hintText: 'Nombre',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepDescripcion,
      targetKey: descripcionKey,
      ttsPhrase: 'Puedes poner una descripción corta. Es opcional pero ayuda.',
      hintText: 'Descripción',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepPrecio,
      targetKey: precioKey,
      ttsPhrase: 'Aquí va el precio por unidad. Solo números.',
      hintText: 'Precio',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepUnidad,
      targetKey: unidadKey,
      ttsPhrase: 'Elige si vendes por kilos, libras o por unidad.',
      hintText: 'Unidad',
    ),
    TutorialStep(
      id: kTutorialProductoFormStepGuardar,
      targetKey: guardarKey,
      ttsPhrase:
          'Cuando termines, pulsa Guardar. Necesitas ubicación encendida para publicar.',
      hintText: 'Guardar',
    ),
  ];
}

/// Frases cortas para el botón de ayuda en el formulario de producto.
List<String> get productoFormHelpPhrases => const [
      'Te guío por el formulario de producto.',
      'Primero la foto, luego nombre y precio, y al final Guardar.',
      'Si no te deja guardar, revisa que la ubicación esté activa.',
    ];
