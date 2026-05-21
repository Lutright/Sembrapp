import 'package:flutter/material.dart';

/// Identificador estable para SharedPreferences y Supabase.
typedef TutorialStepKey = String;

enum TutorialHighlightShape {
  roundedRect,
  circle,
}

/// Un paso del tutorial: un solo foco visual + frase TTS (canal principal).
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.targetKey,
    required this.ttsPhrase,
    this.hintText,
    this.shape = TutorialHighlightShape.roundedRect,
    this.padding = const EdgeInsets.all(8),
  });

  final TutorialStepKey id;
  final GlobalKey targetKey;
  final String ttsPhrase;
  final String? hintText;
  final TutorialHighlightShape shape;
  final EdgeInsets padding;
}
