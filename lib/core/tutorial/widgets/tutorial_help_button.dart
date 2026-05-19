import 'dart:async';

import 'package:flutter/material.dart';

import '../tutorial_service.dart';

/// Botón discreto para volver a escuchar la guía (mismo TTS que el tutorial).
class TutorialHelpButton extends StatelessWidget {
  const TutorialHelpButton({
    super.key,
    required this.phrases,
    this.tooltip = 'Ayuda',
  });

  final List<String> phrases;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(
          Icons.help_outline_rounded,
          color: IconTheme.of(context).color ?? const Color(0xFF1A4463),
        ),
        onPressed: () => unawaited(_play(context)),
      ),
    );
  }

  Future<void> _play(BuildContext context) async {
    await TutorialService.instance.ensureTtsReady();
    for (final p in phrases) {
      if (!context.mounted) return;
      final t = p.trim();
      if (t.isEmpty) continue;
      await TutorialService.instance.speakForContext(context, t);
    }
  }
}
