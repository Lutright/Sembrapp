import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/minimal_ui.dart';

class AlfabetizacionHomeScreen extends StatelessWidget {
  const AlfabetizacionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprender'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: AppPagePadding.screen,
        children: [
          const MinimalScreenHint(
            'Elige si quieres practicar leer o escribir.',
          ),
          BigNavTile(
            icon: Icons.menu_book_rounded,
            title: 'Lectura',
            subtitle: 'Letras, sílabas y palabras',
            onTap: () => context.push('/alfabetizacion/lectura'),
          ),
          const SizedBox(height: AppPagePadding.tileGap),
          BigNavTile(
            icon: Icons.edit_rounded,
            title: 'Escritura',
            subtitle: 'Escribir letras y palabras',
            onTap: () => context.push('/alfabetizacion/escritura'),
          ),
        ],
      ),
    );
  }
}
