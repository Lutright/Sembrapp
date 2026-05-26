import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';
<<<<<<< Updated upstream
=======
import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../widgets/alfabetizacion_lesson_feedback.dart';
import '../widgets/alfabetizacion_lesson_shell.dart';
import '../widgets/abecedario_leccion_flow.dart';
import '../widgets/escritura_teclado_abecedario_leccion_flow.dart';
import '../widgets/escritura_teclado_vocales_leccion_flow.dart';
import '../widgets/escritura_vocales_leccion_flow.dart';
import '../widgets/lectura_guiada_leccion_flow.dart';
import '../widgets/vocales_leccion_flow.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
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
=======
      );
    }

    if (leccion.flujoId == kFlujoVocalesGuiadoId) {
      return VocalesLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    if (leccion.flujoId == kFlujoAbecedarioGuiadoId) {
      return AbecedarioLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    if (leccion.flujoId == kFlujoEscrituraVocalesGuiadoId) {
      return EscrituraVocalesLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    if (leccion.flujoId == kFlujoEscrituraTecladoVocalesGuiadoId) {
      return EscrituraTecladoVocalesLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    if (leccion.flujoId == kFlujoEscrituraTecladoAbecedarioGuiadoId) {
      return EscrituraTecladoAbecedarioLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    if (leccion.flujoId == kFlujoEscrituraTecladoVocalesGuiadoId) {
      return EscrituraTecladoVocalesLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
      );
    }
    final lecturaGuiadaConfig = LecturaGuiadaLeccionFlow.configForLeccion(leccion);
    if (lecturaGuiadaConfig != null) {
      return LecturaGuiadaLeccionFlow(
        leccion: leccion,
        onCompletar: _guardarProgreso,
        config: lecturaGuiadaConfig,
      );
    }

    // Auto-guía por voz (para el resto del módulo).
    if (_ttsListo && !_audioAutoYa) {
      _audioAutoYa = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_narrarEntradaLeccion());
      });
    }

    final totalP = leccion.preguntas.length;
    final progresoLineal = totalP > 0
        ? ((_completado && _correcto == true)
            ? 1.0
            : ((_preguntaIndex + 1) / totalP).clamp(0.0, 1.0))
        : 0.0;
    final etiquetaPaso = _completado && _correcto == true
        ? '¡Lección completada!'
        : _completado && _correcto == false
            ? 'Revisa tu respuesta'
            : 'Avance: ${_preguntaIndex + 1} / $totalP';

    return AlfabetizacionLessonShell(
      title: leccion.titulo,
      subtitle:
          '${leccion.esLectura ? 'Lectura' : 'Escritura'} · Nivel ${leccion.nivel}',
      progress: progresoLineal,
      stepLabel: etiquetaPaso,
      useCloseButton: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Responde todas las preguntas para completar esta lección.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
>>>>>>> Stashed changes
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
