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
  String? _respuestaUsuario;
  bool? _correcto;
  bool _completado = false;

  @override
  void initState() {
    super.initState();
    _leccion = leccionPorId(widget.leccionId);
  }

  void _responderLectura(String opcion) {
    if (_completado || _leccion == null) return;
    final correcto = opcion == _leccion!.respuestaCorrecta;
    setState(() {
      _respuestaUsuario = opcion;
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
      _respuestaUsuario = texto;
      _correcto = correcto;
      _completado = true;
    });
    if (correcto) _guardarProgreso();
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
              'Toca la respuesta correcta. Puedes intentar de nuevo sin castigo.',
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
            ] else ...[
              _buildResumen(context, leccion),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
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
                onPressed: () {
                  // RF-A-12: reproducción de audio (opcional con asset)
                },
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _responderLectura(op),
                  child: Text(op),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEntradaEscritura(BuildContext context, LeccionData leccion) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Escribe aquí',
            hintText: 'Tu respuesta',
          ),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: _responderEscritura,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _responderEscritura(controller.text),
          child: const Text('Comprobar'),
        ),
      ],
    );
  }

  Widget _buildResumen(BuildContext context, LeccionData leccion) {
    return Card(
      color: _correcto == true
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              _correcto == true ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: _correcto == true
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _correcto == true ? '¡Correcto!' : 'Incorrecto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_correcto == true)
              Text(
                '+${leccion.puntos} puntos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            if (_correcto == false && leccion.respuestaCorrecta != null)
              Text(
                'La forma correcta es: ${leccion.respuestaCorrecta}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
