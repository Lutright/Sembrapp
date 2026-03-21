import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Red comunitaria dentro del módulo de comercialización (solo vista campesino).
/// RF-CCOM-01: Red de campesinos + RF-CCOM-02: Órdenes compartidas.
class RedComunitariaScreen extends StatefulWidget {
  const RedComunitariaScreen({super.key});

  @override
  State<RedComunitariaScreen> createState() => _RedComunitariaScreenState();
}

class _RedComunitariaScreenState extends State<RedComunitariaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _campesinos = [];
  List<Map<String, dynamic>> _ordenesCompartidas = [];
  bool _loadingRed = true;
  bool _loadingOrdenes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCampesinos();
    _loadOrdenesCompartidas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCampesinos() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loadingRed = false);
      return;
    }
    setState(() => _loadingRed = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'campesino')
          .neq('id', uid);
      if (mounted) setState(() {
        _campesinos = List<Map<String, dynamic>>.from(res as List);
        _loadingRed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRed = false);
    }
  }

  Future<void> _loadOrdenesCompartidas() async {
    setState(() => _loadingOrdenes = true);
    try {
      final res = await Supabase.instance.client
          .from('ordenes')
          .select()
          .eq('compartida_en_red', true)
          .order('compartida_at', ascending: false);
      if (mounted) setState(() {
        _ordenesCompartidas = List<Map<String, dynamic>>.from(res as List);
        _loadingOrdenes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOrdenes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red comunitaria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Productores', icon: Icon(Icons.people)),
            Tab(text: 'Órdenes compartidas', icon: Icon(Icons.share)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingRed
              ? const Center(child: CircularProgressIndicator())
              : _campesinos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay otros productores registrados aún',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _campesinos.length,
                      itemBuilder: (context, i) {
                        final c = _campesinos[i];
                        final nombre =
                            c['full_name'] as String? ?? 'Productor';
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
          _loadingOrdenes
              ? const Center(child: CircularProgressIndicator())
              : _ordenesCompartidas.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay órdenes compartidas en la red',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ordenesCompartidas.length,
                      itemBuilder: (context, i) {
                        final o = _ordenesCompartidas[i];
                        final id = o['id'] as String? ?? '';
                        final estado = o['estado'] as String? ?? 'pendiente';
                        return Card(
                          child: ListTile(
                            title: Text(
                              'Orden ${id.length >= 8 ? id.substring(0, 8) : id}...',
                            ),
                            subtitle: Text(estado),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/comercializacion/orden/$id',
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
