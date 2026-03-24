import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';

class ComercializacionHomeScreen extends StatelessWidget {
  const ComercializacionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'campesino';
    final isCampesino = role == 'campesino';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: AppPagePadding.screen,
        children: [
          const MinimalScreenHint(
            'Aquí ves productos, pedidos y herramientas.',
          ),
          BigNavTile(
            icon: Icons.storefront_rounded,
            title: 'Ver productos',
            subtitle: 'Explorar lo que hay a la venta',
            onTap: () => context.push('/comercializacion/productos'),
          ),
          if (isCampesino) ...[
            const SizedBox(height: AppPagePadding.tileGap),
            BigNavTile(
              icon: Icons.inventory_2_rounded,
              title: 'Mis productos',
              subtitle: 'Lo que tú publicas',
              onTap: () => context.push('/comercializacion/mis-productos'),
            ),
            const SizedBox(height: AppPagePadding.tileGap),
            BigNavTile(
              icon: Icons.groups_rounded,
              title: 'Red comunitaria',
              subtitle: 'Otros productores y pedidos juntos',
              onTap: () => context.push('/comercializacion/red-comunitaria'),
            ),
            const SizedBox(height: AppPagePadding.tileGap),
            BigNavTile(
              icon: Icons.stars_rounded,
              title: 'Beneficios',
              subtitle: 'Canjear puntos por visibilidad',
              onTap: () => context.push('/comercializacion/beneficios'),
            ),
            const SizedBox(height: AppPagePadding.tileGap),
            BigNavTile(
              icon: Icons.analytics_rounded,
              title: 'Precios de referencia',
              subtitle: 'Indicadores para ayudarte a fijar precios',
              onTap: () => context.push('/comercializacion/indicadores'),
            ),
          ],
          const SizedBox(height: AppPagePadding.tileGap),
          BigNavTile(
            icon: Icons.receipt_long_rounded,
            title: 'Mis pedidos',
            subtitle: 'Pedidos que hiciste o recibiste',
            onTap: () => context.push('/comercializacion/ordenes'),
          ),
        ],
      ),
    );
  }
}
