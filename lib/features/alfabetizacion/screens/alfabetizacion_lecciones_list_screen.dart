import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';

class AlfabetizacionLeccionesListScreen extends StatelessWidget {
  const AlfabetizacionLeccionesListScreen({
    super.key,
    required this.modulo,
    required this.nivel,
  });

  final String modulo;
  final int nivel;

  @override
  Widget build(BuildContext context) {
    final lecciones = leccionesPorModuloNivel(modulo, nivel);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nivel $nivel'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: AppPagePadding.screen,
        children: [
          const MinimalScreenHint(
            'Toca una lección para empezar.',
          ),
          ...lecciones.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: AppPagePadding.tileGap),
              child: BigNavTile(
                icon: l.esLectura ? Icons.menu_book_rounded : Icons.edit_rounded,
                title: l.titulo,
                subtitle: '+${l.puntos} puntos si aciertas',
                onTap: () => context.push(
                  '/alfabetizacion/leccion/${l.id}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
