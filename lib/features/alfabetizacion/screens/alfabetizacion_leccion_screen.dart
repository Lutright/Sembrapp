import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';

class AlfabetizacionLeccionScreen extends StatefulWidget {
  const AlfabetizacionLeccionScreen({
    super.key,
    required this.leccionId,
  });

  final String leccionId;

  @override
  State<AlfabetizacionLeccionScreen> createState() =>
      _AlfabetizacionLeccionScreenState();
}

class _AlfabetizacionLeccionScreenState extends State<AlfabetizacionLeccionScreen> {
  final _repo = AlfabetizacionRepository(Supabase.instance.client);
  LeccionData? _leccion;
  TextEditingController? _escrituraController;
  bool? _correcto;
  bool _completado = false;
  bool _comprobandoAcceso = true;
  bool _accesoPermitido = false;
  String? _textoBloqueo;

  @override
  void initState() {
    super.initState();
    _leccion = leccionPorId(widget.leccionId);
    if (_leccion?.esEscritura == true) {
      _escrituraController = TextEditingController();
    }
    _verificarAcceso();
  }

  @override
  void dispose() {
    _escrituraController?.dispose();
    super.dispose();
  }

  Future<void> _verificarAcceso() async {
    final leccion = _leccion;
    if (leccion == null) {
      setState(() => _comprobandoAcceso = false);
      return;
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _comprobandoAcceso = false;
        _accesoPermitido = false;
        _textoBloqueo = 'Inicia sesión para continuar.';
      });
      return;
    }
    try {
      final ids = await _repo.getLeccionesCompletadasIds(uid, leccion.modulo);
      if (!mounted) return;
      if (!nivelDesbloqueado(leccion.modulo, leccion.nivel, ids)) {
        setState(() {
          _comprobandoAcceso = false;
          _accesoPermitido = false;
          _textoBloqueo = leccion.nivel <= 1
              ? 'Este contenido no está disponible.'
              : 'Primero termina todas las lecciones del nivel ${leccion.nivel - 1}.';
        });
        return;
      }
      if (!leccionDesbloqueada(leccion, ids)) {
        final anterior = tituloLeccionAnteriorMismoNivel(leccion);
        setState(() {
          _comprobandoAcceso = false;
          _accesoPermitido = false;
          _textoBloqueo = anterior != null
              ? 'Antes debes aprobar la lección: «$anterior».'
              : 'Esta lección no está disponible aún.';
        });
        return;
      }
      setState(() {
        _comprobandoAcceso = false;
        _accesoPermitido = true;
        _textoBloqueo = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _comprobandoAcceso = false;
          _accesoPermitido = false;
          _textoBloqueo = 'No se pudo comprobar tu progreso.';
        });
      }
    }
  }

  void _responderLectura(String opcion) {
    if (_completado || _leccion == null) return;
    final correcto = opcion == _leccion!.respuestaCorrecta;
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    if (correcto) _guardarProgreso();
  }

  void _responderEscritura(String texto) {
    if (_completado || _leccion == null) return;
    final esperada = (_leccion!.respuestaCorrecta ?? '').trim().toUpperCase();
    final correcto = texto.trim().toUpperCase() == esperada;
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    if (correcto) _guardarProgreso();
  }

  void _reintentar() {
    setState(() {
      _completado = false;
      _correcto = null;
      _escrituraController?.clear();
    });
  }

  Future<void> _guardarProgreso() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _leccion == null) return;
    await _repo.registrarCompletado(
      userId: user.id,
      modulo: _leccion!.modulo,
      nivel: _leccion!.nivel,
      leccionId: _leccion!.id,
      puntos: _leccion!.puntos,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_comprobandoAcceso) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lección'),
          leading: MinimalBackButton(onPressed: () => context.pop()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final leccion = _leccion;
    if (leccion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lección'),
          leading: MinimalBackButton(onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Lección no encontrada')),
      );
    }

    if (!_accesoPermitido) {
      return Scaffold(
        appBar: AppBar(
          title: Text(leccion.titulo),
          leading: MinimalBackButton(onPressed: () => context.pop()),
        ),
        body: Center(
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
                  _textoBloqueo ?? 'Esta lección no está disponible aún.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(leccion.titulo),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          style: IconButton.styleFrom(
            minimumSize: const Size(kMinimalTouchTarget, kMinimalTouchTarget),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Toca la respuesta correcta o escribe lo que te piden.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (!_completado) ...[
              _buildContenido(context, leccion),
              const SizedBox(height: 32),
              if (leccion.esLectura) _buildOpcionesLectura(context, leccion),
              if (leccion.esEscritura) _buildEntradaEscritura(context, leccion),
            ] else if (_correcto == true) ...[
              _buildResumenExito(context, leccion),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ] else ...[
              _buildResumenError(context),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _reintentar,
                child: const Text('Reintentar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Salir de la lección'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(BuildContext context, LeccionData leccion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              leccion.contenido,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ),
            if (leccion.audioAsset != null)
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionesLectura(BuildContext context, LeccionData leccion) {
    final opciones = leccion.opciones ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: opciones
          .map((op) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _responderLectura(op),
                  child: Text(op),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEntradaEscritura(BuildContext context, LeccionData leccion) {
    final c = _escrituraController;
    if (c == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Escribe aquí',
            hintText: 'Tu respuesta',
          ),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: _responderEscritura,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _responderEscritura(c.text),
          child: const Text('Comprobar'),
        ),
      ],
    );
  }

  Widget _buildResumenExito(BuildContext context, LeccionData leccion) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Correcto!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '+${leccion.puntos} puntos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenError(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cancel_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Incorrecto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes intentar otra vez cuando quieras.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
