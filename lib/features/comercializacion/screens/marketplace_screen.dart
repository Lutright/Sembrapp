import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import '../repositories/beneficios_repository.dart';
import '../repositories/productos_repository.dart';

/// Vista tipo Rappi para compradores: búsqueda, grid de productos, carrito.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ProductosRepository _repo =
      ProductosRepository(Supabase.instance.client);
  final BeneficiosRepository _beneficiosRepo =
      BeneficiosRepository(Supabase.instance.client);
  List<Producto> _productos = [];
  List<Producto> _filtered = [];
  Set<String> _campesinosDestacados = {};
  bool _loading = true;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listarProductos();
      final destacados = await _beneficiosRepo.getCampesinosConBeneficioVigente();
      list.sort((a, b) {
        final aDestacado = destacados.contains(a.campesinoId);
        final bDestacado = destacados.contains(b.campesinoId);
        if (aDestacado && !bDestacado) return -1;
        if (!aDestacado && bDestacado) return 1;
        return 0;
      });
      if (mounted) {
        setState(() {
          _productos = list;
          _campesinosDestacados = destacados;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_query.trim().isEmpty) {
      _filtered = List.from(_productos);
      return;
    }
    final q = _query.trim().toLowerCase();
    _filtered =
        _productos.where((p) => p.nombre.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Productos'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/comercializacion/ordenes'),
            tooltip: 'Mis órdenes',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Mi perfil',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar productos...',
              leading: const Icon(Icons.search),
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _applyFilter();
                });
              },
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No hay productos'
                              : 'Sin resultados para "$_query"',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          final destacado = _campesinosDestacados.contains(p.campesinoId);
                          return _ProductCard(
                            producto: p,
                            destacado: destacado,
                            onTap: () => context.push(
                              '/comercializacion/producto/${p.id}',
                              extra: p,
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.producto,
    required this.onTap,
    this.destacado = false,
  });

  final Producto producto;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.shopping_basket,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (destacado)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Destacado',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      producto.nombre,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${producto.precio.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Ver'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
