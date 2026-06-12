import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../audio/comercializacion_audio_phrases.dart';
import '../mixins/comercializacion_screen_audio_mixin.dart';
import '../models/producto.dart';
import '../../../core/theme/tonalist_colors.dart';
import '../../../core/widgets/tonalist_gradient_button.dart';
import '../../../core/widgets/tonalist_screen_header.dart';
import '../repositories/productos_repository.dart';

class ComercializacionMisProductosScreen extends StatefulWidget {
  const ComercializacionMisProductosScreen({super.key});

  @override
  State<ComercializacionMisProductosScreen> createState() =>
      _ComercializacionMisProductosScreenState();
}

class _ComercializacionMisProductosScreenState
    extends State<ComercializacionMisProductosScreen>
    with ComercializacionScreenAudio {
  final _repo = ProductosRepository(Supabase.instance.client);
  List<Producto> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    initComercializacionScreenAudio(ComercializacionAudioPhrases.misProductosWelcome);
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _repo.misProductos(user.id);
      if (mounted) {
        setState(() {
          _productos = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onAddProducto() async {
    await audioSpeakAction(ComercializacionAudioPhrases.addProducto);
    if (!mounted) return;
    await context.push('/comercializacion/producto/nuevo');
    _load();
  }

  Future<void> _onEditarProducto(Producto p) async {
    await audioSpeakAction(ComercializacionAudioPhrases.editProducto);
    if (!mounted) return;
    await context.push(
      '/comercializacion/producto/editar/${p.id}',
      extra: p,
    );
    _load();
  }

  Future<void> _onEliminarProducto(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.nombre}"?'),
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
      await audioSpeakAction(ComercializacionAudioPhrases.deleteProducto);
      await _repo.eliminarProducto(p.id);
      _load();
      if (mounted) {
        await audioSpeakAction(ComercializacionAudioPhrases.deletedOk);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TonalistColors.crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      TonalistHeaderMetrics.contentTopPadding,
                      16,
                      24,
                    ),
                    children: [
                      buildComercializacionAudioCoachBarFor(
                        ComercializacionAudioPhrases.misProductosWelcome,
                      ),
                      const SizedBox(height: 14),
                      if (_productos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Aún no publicas nada.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      else
                        ..._productos.expand((p) => [
                              _ProductoCard(
                                producto: p,
                                onEditar: () => _onEditarProducto(p),
                                onEliminar: () => _onEliminarProducto(p),
                              ),
                              const SizedBox(height: 12),
                            ]),
                      const SizedBox(height: 16),
                      TonalistGradientButton(
                        label: 'Añadir producto',
                        icon: Icons.add,
                        onPressed: _onAddProducto,
                      ),
                    ],
                  ),
          ),
          const TonalistHeaderBackground(
            height: TonalistHeaderMetrics.standardHeight,
          ),
          TonalistHeaderChrome(
            height: TonalistHeaderMetrics.standardHeight,
            title: 'Mis productos',
            subtitle: 'Gestiona tu catálogo',
            onBack: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({
    required this.producto,
    required this.onEditar,
    required this.onEliminar,
  });

  final Producto producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final precio = producto.precio.toStringAsFixed(0);
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TonalistColors.azulHorizonte.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty)
                  ? Image.network(
                      producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_outlined,
                        color: TonalistColors.azulHorizonte.withValues(alpha: 0.4),
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: TonalistColors.azulHorizonte.withValues(alpha: 0.4),
                      size: 32,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$precio \$/'
                    '${producto.unidad}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: TonalistColors.azulHorizonte,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (producto.descripcion?.trim().isNotEmpty == true)
                        ? producto.descripcion!.trim()
                        : 'Sin descripción',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: TonalistColors.azulHorizonte, width: 1),
                    foregroundColor: TonalistColors.azulHorizonte,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: TonalistColors.rojoManta, width: 1),
                    foregroundColor: TonalistColors.rojoManta,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
