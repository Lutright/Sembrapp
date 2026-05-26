import 'package:flutter/material.dart';

/// Barra simple de guía por voz con botón "Repetir".
class ComercializacionAudioCoachBar extends StatelessWidget {
  const ComercializacionAudioCoachBar({
    super.key,
    required this.listo,
    required this.narrando,
    required this.enabled,
    required this.onRepeat,
  });

  final bool listo;
  final bool narrando;
  final bool enabled;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = !enabled || !listo || narrando;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.headphones_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !enabled
                  ? 'Guía por voz: tutorial activo'
                  : (listo ? 'Guía por voz: pulsa para repetir' : 'Preparando audio…'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: disabled ? null : onRepeat,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Repetir'),
          ),
        ],
      ),
    );
  }
}

