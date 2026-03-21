import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import '../repositories/productos_repository.dart';
import 'producto_form_screen.dart';

class ComercializacionMisProductosScreen extends StatefulWidget {
  const ComercializacionMisProductosScreen({super.key});

  @override
  State<ComercializacionMisProductosScreen> createState() =>
      _ComercializacionMisProductosScreenState();
}

class _ComercializacionMisProductosScreenState
    extends State<ComercializacionMisProductosScreen> {
  final _repo = ProductosRepository(Supabase.instance.client);
  List<Producto> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final list = await _repo.misProductos(user.id);
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
        title: const Text('Mis productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/comercializacion/producto/nuevo');
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aún no tienes productos publicados'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          await context.push('/comercializacion/producto/nuevo');
                          _load();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Publicar producto'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _productos.length,
                  itemBuilder: (context, i) {
                    final p = _productos[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.nombre),
                        subtitle: Text(
                          '${p.precio.toStringAsFixed(0)} \$/${p.unidad} · '
                          '${p.cantidadDisponible} ${p.unidad}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'editar') {
                              await context.push(
                                '/comercializacion/producto/editar/${p.id}',
                                extra: p,
                              );
                              _load();
                            } else if (v == 'eliminar') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar producto'),
                                  content: Text(
                                    '¿Eliminar "${p.nombre}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await _repo.eliminarProducto(p.id);
                                _load();
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
