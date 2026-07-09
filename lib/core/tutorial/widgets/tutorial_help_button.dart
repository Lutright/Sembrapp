import 'dart:async';

import 'package:flutter/material.dart';

import '../tutorial_service.dart';

/// Botón de guía en el header: ayuda por audio y, si aplica, repetir el walkthrough.
class TutorialHelpButton extends StatelessWidget {
  const TutorialHelpButton({
    super.key,
    required this.phrases,
    this.onReplayWalkthrough,
    this.tooltip = 'Guía por voz',
  });

  final List<String> phrases;
  final VoidCallback? onReplayWalkthrough;
  final String tooltip;

  static const Color _azul = Color(0xFF1A4463);

  @override
  Widget build(BuildContext context) {
    final fg = IconTheme.of(context).color ?? Colors.white;

    if (onReplayWalkthrough == null) {
      return _GuiaChip(
        foregroundColor: fg,
        tooltip: tooltip,
        onTap: () => unawaited(_playPhrases(context)),
      );
    }

    return PopupMenuButton<String>(
      tooltip: tooltip,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      child: _GuiaChip(foregroundColor: fg),
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

class _GuiaChip extends StatelessWidget {
  const _GuiaChip({
    required this.foregroundColor,
    this.tooltip,
    this.onTap,
  });

  final Color foregroundColor;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up_rounded, color: foregroundColor, size: 18),
              const SizedBox(width: 5),
              Text(
                'Guía',
                style: TextStyle(
                  color: foregroundColor,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}
