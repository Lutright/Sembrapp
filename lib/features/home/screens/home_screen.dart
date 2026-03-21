import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sembrapp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isCampesino) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.school),
                ),
                title: const Text('Módulo de alfabetización'),
                subtitle: const Text(
                  'RF-A-01: Lectura y escritura por niveles',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/alfabetizacion'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.store),
              ),
              title: const Text('Módulo de comercialización'),
              subtitle: Text(
                isCampesino
                    ? 'Publicar y gestionar productos'
                    : 'Explorar y comprar productos',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/comercializacion'),
            ),
          ),
        ],
      ),
    );
  }
}
