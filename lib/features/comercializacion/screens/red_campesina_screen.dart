import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';

class RedCampesinaScreen extends StatefulWidget {
  const RedCampesinaScreen({super.key});

  @override
  State<RedCampesinaScreen> createState() => _RedCampesinaScreenState();
}

class _RedCampesinaScreenState extends State<RedCampesinaScreen> {
  List<Map<String, dynamic>> _campesinos = [];
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
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'campesino')
          .neq('id', uid);
      if (mounted) setState(() {
        _campesinos = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red campesina'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _campesinos.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppPagePadding.screen,
                    child: Text(
                      'Aún no hay otros productores en la lista.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _campesinos.length,
                  itemBuilder: (context, i) {
                    final c = _campesinos[i];
                    final nombre = c['full_name'] as String? ?? 'Productor';
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.agriculture),
                        ),
                        title: Text(nombre),
                        subtitle: const Text('Campesino'),
                      ),
                    );
                  },
                ),
    );
  }
}
