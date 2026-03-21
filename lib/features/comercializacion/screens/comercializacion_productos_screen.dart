import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import '../repositories/productos_repository.dart';
import 'producto_detalle_screen.dart';

class ComercializacionProductosScreen extends StatefulWidget {
  const ComercializacionProductosScreen({super.key});

  @override
  State<ComercializacionProductosScreen> createState() =>
      _ComercializacionProductosScreenState();
}

class _ComercializacionProductosScreenState
    extends State<ComercializacionProductosScreen> {
  late final ProductosRepository _repo;
  List<Producto> _productos = [];
  bool _loading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _repo = ProductosRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listarProductos(
        busqueda: _busqueda.isEmpty ? null : _busqueda,
      );
      if (mounted) setState(() {
        _productos = list;
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
        title: const Text('Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'RF-CC-01: Búsqueda por nombre',
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                setState(() => _busqueda = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _productos.length,
                        itemBuilder: (context, i) {
                          final p = _productos[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.nombre),
                              subtitle: Text(
                                '${p.precio.toStringAsFixed(0)} \$/${p.unidad} · ${p.campesinoNombre ?? "Productor"}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                '/comercializacion/producto/${p.id}',
                                extra: p,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
