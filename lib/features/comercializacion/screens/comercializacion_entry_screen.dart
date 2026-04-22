import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/schedule_cold_start_deep_link.dart';
import 'comercializacion_home_screen.dart';
import 'marketplace_screen.dart';

/// Redirige según rol: comprador → marketplace (estilo Rappi), campesino → menú comercialización.
class ComercializacionEntryScreen extends StatelessWidget {
  const ComercializacionEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Supabase.instance.client.auth.currentUser?.userMetadata?['role']
        as String?;
    final isComprador = role == 'comprador';

    return ScheduleColdStartDeepLink(
      child: isComprador
          ? const MarketplaceScreen()
          : const ComercializacionHomeScreen(),
    );
  }
}
