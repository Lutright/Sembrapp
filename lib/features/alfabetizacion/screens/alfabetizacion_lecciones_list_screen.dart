import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';

class AlfabetizacionLeccionesListScreen extends StatefulWidget {
  const AlfabetizacionLeccionesListScreen({
    super.key,
    required this.modulo,
    required this.nivel,
  });

  final String modulo;
  final int nivel;

  @override
  State<AlfabetizacionLeccionesListScreen> createState() =>
      _AlfabetizacionLeccionesListScreenState();
}

class _AlfabetizacionLeccionesListScreenState
    extends State<AlfabetizacionLeccionesListScreen> {
  final _repo = AlfabetizacionRepository(Supabase.instance.client);
  Set<String> _completadas = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final ids = await _repo.getLeccionesCompletadasIds(uid, widget.modulo);
      if (mounted) {
        setState(() {
          _completadas = ids;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecciones = leccionesPorModuloNivel(widget.modulo, widget.nivel);
    final desbloqueado = nivelDesbloqueado(
      widget.modulo,
      widget.nivel,
      _completadas,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Nivel ${widget.nivel}'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !desbloqueado
              ? Center(
                  child: Padding(
                    padding: AppPagePadding.screen,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Este nivel aún está cerrado.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completa todas las lecciones del nivel ${widget.nivel - 1} para abrirlo.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.pop(),
                          child: const Text('Volver'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarProgreso,
                  child: ListView(
                    padding: AppPagePadding.screen,
                    children: [
                      const MinimalScreenHint(
                        'Las lecciones se abren una tras otra cuando aciertas la anterior.',
                      ),
                      ...lecciones.asMap().entries.map(
                        (e) {
                          final i = e.key;
                          final l = e.value;
                          final leccionAbierta = leccionDesbloqueada(
                            l,
                            _completadas,
                          );
                          final String subtitulo;
                          if (leccionAbierta) {
                            subtitulo = '+${l.puntos} puntos si aciertas';
                          } else {
                            subtitulo = i > 0
                                ? 'Completa antes: «${lecciones[i - 1].titulo}»'
                                : 'Bloqueada';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppPagePadding.tileGap,
                            ),
                            child: BigNavTile(
                              icon: leccionAbierta
                                  ? (l.esLectura
                                      ? Icons.menu_book_rounded
                                      : Icons.edit_rounded)
                                  : Icons.lock_rounded,
                              title: l.titulo,
                              subtitle: subtitulo,
                              onTap: () async {
                                if (!leccionAbierta) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        i > 0
                                            ? 'Primero aprueba la lección «${lecciones[i - 1].titulo}».'
                                            : 'Esta lección no está disponible aún.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await context.push(
                                  '/alfabetizacion/leccion/${l.id}',
                                );
                                if (mounted) _cargarProgreso();
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
