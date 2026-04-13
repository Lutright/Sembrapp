import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../../../core/widgets/schedule_cold_start_deep_link.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return ScheduleColdStartDeepLink(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          actions: [
            IconButton(
              tooltip: 'Mi perfil',
              icon: const Icon(Icons.person_rounded),
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              tooltip: 'Salir',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
        body: ListView(
          padding: AppPagePadding.screen,
          children: [
            const MinimalScreenHint(
              'Elige qué quieres hacer. Toca una opción.',
            ),
            if (isCampesino) ...[
              BigNavTile(
                icon: Icons.school_rounded,
                title: 'Aprender',
                subtitle: 'Lectura y escritura, paso a paso',
                onTap: () => context.push('/alfabetizacion'),
              ),
              const SizedBox(height: AppPagePadding.tileGap),
            ],
            BigNavTile(
              icon: Icons.storefront_rounded,
              title: 'Vender y comprar',
              subtitle: isCampesino
                  ? 'Publicar productos y ver el mercado'
                  : 'Ver productos y hacer pedidos',
              onTap: () => context.push('/comercializacion'),
            ),
          ],
        ),
      ),
    );
  }
}
