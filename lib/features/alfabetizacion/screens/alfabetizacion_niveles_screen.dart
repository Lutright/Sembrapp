import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: Text('$tituloModulo - Niveles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'RF-A-03: Organización por niveles',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          ...niveles.map((nivel) {
            final lecciones = leccionesPorModuloNivel(modulo, nivel);
            final total = lecciones.length;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('$nivel'),
                ),
                title: Text('Nivel $nivel'),
                subtitle: Text('$total lección${total != 1 ? 'es' : ''}'),
                trailing: const Icon(Icons.arrow_forward),
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
