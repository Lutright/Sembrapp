import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'RF-A-04: Inicio de lección / RF-A-10: Acceso a lecciones completadas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          ...lecciones.map((l) => Card(
                child: ListTile(
                  leading: Icon(
                    l.esLectura ? Icons.menu_book : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l.titulo),
                  subtitle: Text('${l.puntos} puntos'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => context.push(
                    '/alfabetizacion/leccion/${l.id}',
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
