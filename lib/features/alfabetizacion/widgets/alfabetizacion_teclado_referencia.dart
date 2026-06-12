import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alfabetizacion_lesson_shell.dart';

/// Teclado QWERTY de referencia (solo visual) para lecciones de escritura.
///
/// Escala al ancho disponible y reserva espacio para teclas resaltadas animadas,
/// evitando overflow horizontal por [Transform.scale].
class AlfabetizacionTecladoReferencia extends StatelessWidget {
  const AlfabetizacionTecladoReferencia({
    super.key,
    required this.filas,
    required this.teclasResaltadas,
    required this.colorResaltado,
    required this.fondoResaltado,
    this.opacidadReferencia = 1.0,
    this.escalaResaltado = 1.0,
    this.onLetraTap,
  });

  final List<List<String>> filas;
  final Set<String> teclasResaltadas;
  final Color colorResaltado;
  final Color fondoResaltado;
  final double opacidadReferencia;
  final double escalaResaltado;
  final ValueChanged<String>? onLetraTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacidadReferencia,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 40;

          return Align(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: AlfabetizacionLessonTokens.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < filas.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < filas.length - 1 ? 6 : 0,
                            ),
                            child: _filaTeclado(filas[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaTeclado(List<String> letras) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letras.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _tecla(letras[i], teclasResaltadas.contains(letras[i])),
        ],
      ],
    );
  }

  Widget _tecla(String letra, bool resaltada) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: resaltada ? fondoResaltado : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: resaltada ? colorResaltado : Colors.grey.shade400,
          width: resaltada ? 2.5 : 1,
        ),
        boxShadow: resaltada
            ? [
                BoxShadow(
                  color: colorResaltado.withValues(alpha: 0.45),
                  blurRadius: 8 * escalaResaltado,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Text(
        letra,
        style: TextStyle(
          fontSize: 13,
          fontWeight: resaltada ? FontWeight.w800 : FontWeight.w600,
          color: resaltada ? colorResaltado : Colors.grey.shade800,
        ),
      ),
    );

    Widget wrapped = child;
    if (resaltada) {
      wrapped = SizedBox(
        width: 30,
        height: 38,
        child: Center(
          child: Transform.scale(
            scale: escalaResaltado,
            child: child,
          ),
        ),
      );
    }

    if (onLetraTap == null) return wrapped;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onLetraTap!(letra);
        },
        borderRadius: BorderRadius.circular(8),
        child: wrapped,
      ),
    );
  }
}
