import 'package:flutter/material.dart';

import '../alfabetizacion_ui_colors.dart';
import 'alfabetizacion_lesson_shell.dart';

/// Opciones de respuesta apiladas verticalmente (lectura y actividades guiadas).
///
/// Fondo blanco por defecto; al seleccionar muestra ✓ verde o ✗ rojo dentro del botón.
class AlfabetizacionLessonAnswerOptions extends StatelessWidget {
  const AlfabetizacionLessonAnswerOptions({
    super.key,
    required this.opciones,
    required this.onSelected,
    this.selectedOption,
    this.selectedWasCorrect,
    this.enabled = true,
    this.fontSize,
  });

  final List<String> opciones;
  final ValueChanged<String> onSelected;
  final String? selectedOption;
  final bool? selectedWasCorrect;
  final bool enabled;
  final double? fontSize;

  static const Color _azulHorizonte = AlfabetizacionLessonTokens.accentBlue;

  double _fontSizeFor(String opcion) {
    if (fontSize != null) return fontSize!;
    if (opcion.length <= 3) return 22;
    if (opcion.length <= 12) return 18;
    return 16;
  }

  Color _backgroundColor(String opcion) {
    if (selectedOption != opcion) return Colors.white;
    if (selectedWasCorrect == true) return Colors.green.shade100;
    if (selectedWasCorrect == false) {
      return AlfabetizacionUiColors.rojoAcento.withValues(alpha: 0.10);
    }
    return Colors.white;
  }

  Color _borderColor(String opcion) {
    if (selectedOption != opcion) return _azulHorizonte;
    if (selectedWasCorrect == true) return Colors.green.shade700;
    if (selectedWasCorrect == false) return AlfabetizacionUiColors.rojoAcento;
    return _azulHorizonte;
  }

  Color _textColor(String opcion) {
    if (selectedOption != opcion) return _azulHorizonte;
    if (selectedWasCorrect == true) return Colors.green.shade800;
    if (selectedWasCorrect == false) return AlfabetizacionUiColors.rojoAcento;
    return _azulHorizonte;
  }

  Widget _labelFor(String opcion, double size) {
    final text = Text(
      opcion,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );

    if (selectedOption != opcion) return text;

    final IconData icon;
    final Color iconColor;
    if (selectedWasCorrect == true) {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.green.shade700;
    } else if (selectedWasCorrect == false) {
      icon = Icons.cancel_rounded;
      iconColor = AlfabetizacionUiColors.rojoAcento;
    } else {
      return text;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: size + 2, color: iconColor),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < opciones.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OutlinedButton(
            onPressed: !enabled ? null : () => onSelected(opciones[i]),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              side: BorderSide(
                color: _borderColor(opciones[i]),
                width: 1.5,
              ),
              backgroundColor: _backgroundColor(opciones[i]),
              foregroundColor: _textColor(opciones[i]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _labelFor(opciones[i], _fontSizeFor(opciones[i])),
          ),
        ],
      ],
    );
  }
}
