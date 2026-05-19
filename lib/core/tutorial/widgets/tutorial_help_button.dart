import 'dart:async';

import 'package:flutter/material.dart';

import '../tutorial_service.dart';

/// Botón ? en el header: ayuda por audio y, si aplica, repetir el walkthrough de la pantalla.
class TutorialHelpButton extends StatelessWidget {
  const TutorialHelpButton({
    super.key,
    required this.phrases,
    this.onReplayWalkthrough,
    this.tooltip = 'Ayuda',
  });

  final List<String> phrases;
  final VoidCallback? onReplayWalkthrough;
  final String tooltip;

  static const Color _azul = Color(0xFF1A4463);

  @override
  Widget build(BuildContext context) {
    final iconColor = IconTheme.of(context).color ?? _azul;

    if (onReplayWalkthrough == null) {
      return IconButton(
        tooltip: tooltip,
        icon: Icon(Icons.help_outline_rounded, color: iconColor),
        onPressed: () => unawaited(_playPhrases(context)),
      );
    }

    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: Icon(Icons.help_outline_rounded, color: iconColor),
      onSelected: (value) {
        if (value == 'audio') {
          unawaited(_playPhrases(context));
        } else if (value == 'replay') {
          onReplayWalkthrough!();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'audio',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.volume_up_outlined, color: _azul),
            title: Text(
              'Escuchar ayuda rápida',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'replay',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.play_lesson_outlined, color: _azul),
            title: Text(
              'Ver tutorial de nuevo',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _playPhrases(BuildContext context) async {
    await TutorialService.instance.ensureTtsReady();
    for (final p in phrases) {
      if (!context.mounted) return;
      final t = p.trim();
      if (t.isEmpty) continue;
      await TutorialService.instance.speakForContext(context, t);
    }
  }
}
