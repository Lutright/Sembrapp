import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';

class ComercializacionOrdenesScreen extends StatefulWidget {
  const ComercializacionOrdenesScreen({super.key});

  @override
  State<ComercializacionOrdenesScreen> createState() =>
      _ComercializacionOrdenesScreenState();
}

class _ComercializacionOrdenesScreenState
    extends State<ComercializacionOrdenesScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('ordenes')
          .select()
          .or('comprador_id.eq.$uid,campesino_id.eq.$uid')
          .order('created_at', ascending: false);
      if (mounted) setState(() {
        _ordenes = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis órdenes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _ordenes.isEmpty
          ? Center(
              child: Padding(
                padding: AppPagePadding.screen,
                child: Text(
                  'Aún no tienes pedidos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.builder(
              padding: AppPagePadding.screen,
              itemCount: _ordenes.length,
              itemBuilder: (context, i) {
                final o = _ordenes[i];
                final id = o['id'] as String? ?? '';
                final estado = o['estado'] as String? ?? 'pendiente';
                return Card(
                  child: ListTile(
                    title: Text('Orden ${id.length >= 8 ? id.substring(0, 8) : id}...'),
                    subtitle: Text(estado),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/comercializacion/orden/$id',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
