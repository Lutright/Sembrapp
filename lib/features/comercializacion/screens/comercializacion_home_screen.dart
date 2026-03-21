import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/productos_repository.dart';
import 'comercializacion_productos_screen.dart';
import 'comercializacion_mis_productos_screen.dart';
import 'comercializacion_ordenes_screen.dart';

class ComercializacionHomeScreen extends StatelessWidget {
  const ComercializacionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comercialización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'RF-C-01 / RF-C-02: Acceso y exploración de productos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.storefront),
              ),
              title: const Text('Ver productos'),
              subtitle: const Text('Explorar productos agrícolas disponibles'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/comercializacion/productos'),
            ),
          ),
          if (isCampesino) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.inventory_2),
                ),
                title: const Text('Mis productos'),
                subtitle: const Text('RF-CV-04: Gestionar tus publicaciones'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/comercializacion/mis-productos'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.people),
                ),
                title: const Text('Red comunitaria'),
                subtitle: const Text(
                  'RF-CCOM: Productores y órdenes compartidas',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/comercializacion/red-comunitaria'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.stars),
                ),
                title: const Text('Beneficios por puntos'),
                subtitle: const Text(
                  'Canjear puntos de alfabetización por visibilidad',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/comercializacion/beneficios'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.analytics),
                ),
                title: const Text('Indicadores económicos'),
                subtitle: const Text(
                  'Precios de referencia del sector (RF-C-05, RF-C-06)',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/comercializacion/indicadores'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.receipt_long),
              ),
              title: const Text('Mis órdenes'),
              subtitle: const Text('RF-CO-02: Ver resumen de órdenes'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/comercializacion/ordenes'),
            ),
          ),
        ],
      ),
    );
  }
}
