import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/lecciones_data.dart';
import 'alfabetizacion_niveles_screen.dart';
import 'alfabetizacion_leccion_screen.dart';

class AlfabetizacionHomeScreen extends StatelessWidget {
  const AlfabetizacionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alfabetización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'RF-A-01: Acceso al módulo de alfabetización',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'RF-A-02: Submódulos disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.menu_book),
              ),
              title: const Text('Lectura'),
              subtitle: const Text(
                'Reconocer letras, sílabas y palabras',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push(
                '/alfabetizacion/lectura',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.edit),
              ),
              title: const Text('Escritura'),
              subtitle: const Text(
                'Escribir letras, sílabas y palabras',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push(
                '/alfabetizacion/escritura',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
