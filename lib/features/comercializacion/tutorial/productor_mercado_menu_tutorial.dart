import 'package:flutter/material.dart';

import '../../../core/tutorial/models/tutorial_step.dart';
import 'comercializacion_tutorial_keys.dart';

List<TutorialStep> buildProductorMercadoMenuTutorialSteps({
  required GlobalKey infoKey,
  required GlobalKey misProductosKey,
  required GlobalKey misPedidosKey,
  required GlobalKey redKey,
  required GlobalKey beneficiosKey,
  required GlobalKey indicadoresKey,
  required GlobalKey ayudaKey,
}) {
  return [
    TutorialStep(
      id: kTutorialProductorMercadoStepInfo,
      targetKey: infoKey,
      ttsPhrase:
          'Desde aquí entras a todo el mercado: productos, pedidos y herramientas para vender mejor.',
      hintText: 'Resumen del menú',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepMisProductos,
      targetKey: misProductosKey,
      ttsPhrase:
          'Pulsa Mis productos para publicar o editar lo que ofreces en tu tienda.',
      hintText: 'Mis productos',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepMisPedidos,
      targetKey: misPedidosKey,
      ttsPhrase:
          'En Mis pedidos ves lo que te pidieron y hablas con el comprador por chat.',
      hintText: 'Mis pedidos',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepRed,
      targetKey: redKey,
      ttsPhrase:
          'La red comunitaria es para ver a otros productores y pedir ayuda si la necesitas.',
      hintText: 'Red comunitaria',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepBeneficios,
      targetKey: beneficiosKey,
      ttsPhrase:
          'En Beneficios puedes canjear puntos para que tu tienda destaque más.',
      hintText: 'Beneficios',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepIndicadores,
      targetKey: indicadoresKey,
      ttsPhrase:
          'Precios de referencia te muestra datos para orientar tus precios al mercado.',
      hintText: 'Precios de referencia',
    ),
    TutorialStep(
      id: kTutorialProductorMercadoStepAyuda,
      targetKey: ayudaKey,
      ttsPhrase:
          'Si quieres ver esta guía otra vez, toca el botón Guía arriba a la derecha y elige Ver tutorial de nuevo.',
      hintText: 'Guía por voz',
      padding: const EdgeInsets.all(10),
    ),
  ];
}

List<String> get productorMercadoMenuHelpPhrases => const [
      'Este es tu menú del mercado como productor.',
      'Mis productos para publicar, Mis pedidos para entregar y chatear.',
      'La red comunitaria te conecta con otros campesinos.',
    ];
