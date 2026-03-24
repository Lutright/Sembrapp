import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';

class AlfabetizacionNivelesScreen extends StatelessWidget {
  const AlfabetizacionNivelesScreen({
    super.key,
    required this.modulo,
  });

  final String modulo;

  @override
  Widget build(BuildContext context) {
    final niveles = nivelesDisponibles(modulo);
    final tituloModulo = modulo == 'lectura' ? 'Lectura' : 'Escritura';

    return Scaffold(
      appBar: AppBar(
        title: Text('$tituloModulo · niveles'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: AppPagePadding.screen,
        children: [
          const MinimalScreenHint(
            'Toca un nivel para ver las lecciones.',
          ),
          ...niveles.map((nivel) {
            final lecciones = leccionesPorModuloNivel(modulo, nivel);
            final total = lecciones.length;
            final IconData nivelIcon = switch (nivel) {
              1 => Icons.looks_one_rounded,
              2 => Icons.looks_two_rounded,
              3 => Icons.looks_3_rounded,
              _ => Icons.layers_rounded,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppPagePadding.tileGap),
              child: BigNavTile(
                icon: nivelIcon,
                title: 'Nivel $nivel',
                subtitle: '$total lección${total != 1 ? 'es' : ''}',
                onTap: () => context.push(
                  '/alfabetizacion/$modulo/nivel/$nivel',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
