import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';

class AlfabetizacionNivelesScreen extends StatefulWidget {
  const AlfabetizacionNivelesScreen({
    super.key,
    required this.modulo,
  });

  final String modulo;

  @override
  State<AlfabetizacionNivelesScreen> createState() =>
      _AlfabetizacionNivelesScreenState();
}

class _AlfabetizacionNivelesScreenState
    extends State<AlfabetizacionNivelesScreen> {
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
    final niveles = nivelesDisponibles(widget.modulo);
    final tituloModulo =
        widget.modulo == 'lectura' ? 'Lectura' : 'Escritura';

    return Scaffold(
      appBar: AppBar(
        title: Text('$tituloModulo · niveles'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarProgreso,
              child: ListView(
                padding: AppPagePadding.screen,
                children: [
                  const MinimalScreenHint(
                    'Dentro de cada nivel, las lecciones se abren de una en una. '
                    'El siguiente nivel se abre cuando terminas bien todas las del anterior.',
                  ),
                  ...niveles.map((nivel) {
                    final lecciones =
                        leccionesPorModuloNivel(widget.modulo, nivel);
                    final total = lecciones.length;
                    final desbloqueado = nivelDesbloqueado(
                      widget.modulo,
                      nivel,
                      _completadas,
                    );
                    final IconData nivelIcon = switch (nivel) {
                      1 => Icons.looks_one_rounded,
                      2 => Icons.looks_two_rounded,
                      3 => Icons.looks_3_rounded,
                      _ => Icons.layers_rounded,
                    };
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppPagePadding.tileGap),
                      child: BigNavTile(
                        icon:
                            desbloqueado ? nivelIcon : Icons.lock_rounded,
                        title: 'Nivel $nivel',
                        subtitle: desbloqueado
                            ? '$total lección${total != 1 ? 'es' : ''}'
                            : 'Termina el nivel ${nivel - 1} para abrir este',
                        onTap: () async {
                          if (!desbloqueado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Primero completa todas las lecciones del nivel ${nivel - 1}.',
                                ),
                              ),
                            );
                            return;
                          }
                          await context.push(
                            '/alfabetizacion/${widget.modulo}/nivel/$nivel',
                          );
                          if (mounted) _cargarProgreso();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
