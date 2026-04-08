import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../repositories/productos_repository.dart';
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
        leading: MinimalBackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: 'Agregar',
            icon: const Icon(Icons.add_rounded),
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
                  child: Padding(
                    padding: AppPagePadding.screen,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Aún no publicas nada.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () async {
                            await context.push('/comercializacion/producto/nuevo');
                            _load();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Publicar producto'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: AppPagePadding.screen,
                  itemCount: _productos.length,
                  itemBuilder: (context, i) {
                    final p = _productos[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.nombre),
                        subtitle: Text(
                          '${p.precio.toStringAsFixed(0)} \$/${p.unidad} · '
                          '${p.tieneStockDeclarado ? 'Ref. ${p.cantidadDisponible} ${p.unidad}' : 'Sin stock fijo en catálogo'}',
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
