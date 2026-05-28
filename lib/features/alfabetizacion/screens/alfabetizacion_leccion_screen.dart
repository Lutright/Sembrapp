import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../alfabetizacion_ui_colors.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';
import '../../../core/services/alfabetizacion_tts_coach.dart';
import '../widgets/alfabetizacion_lesson_feedback.dart';
import '../widgets/alfabetizacion_lesson_shell.dart';
import '../widgets/abecedario_leccion_flow.dart';
import '../widgets/escritura_teclado_vocales_leccion_flow.dart';
import '../widgets/escritura_vocales_leccion_flow.dart';
import '../widgets/escritura_trazos_abecedario_leccion_flow.dart';
import '../widgets/escritura_teclado_abecedario_leccion_flow.dart';
import '../widgets/escritura_trazos_guiado_leccion_flow.dart';
import '../widgets/escritura_teclado_guiado_leccion_flow.dart';
import '../data/escritura_guiada_config.dart';
import '../widgets/lectura_guiada_leccion_flow.dart';
import '../widgets/vocales_leccion_flow.dart';

const Color _azulHorizonte = Color(0xFF1A4463);

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
  final _ttsCoach = AlfabetizacionTtsCoach();
  LeccionData? _leccion;
  TextEditingController? _escrituraController;
  bool? _correcto;
  bool _completado = false;
  int _preguntaIndex = 0;
  bool _comprobandoAcceso = true;
  bool _accesoPermitido = false;
  String? _textoBloqueo;
  bool _ttsListo = false;
  bool _audioAutoYa = false;
  int _audioAutoPreguntaIndex = -1;
  bool _narrando = false;
  int _narracionGen = 0;
  bool _mostrarAciertoIntermedio = false;
  int _aciertoAnimacion = 0;

  @override
  void initState() {
    super.initState();
    _leccion = leccionPorId(widget.leccionId);
    if (_leccion?.esEscritura == true) {
      _escrituraController = TextEditingController();
    }
    _verificarAcceso();
    _inicializarTts();
  }

  @override
  void dispose() {
    unawaited(_ttsCoach.dispose());
    _escrituraController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarTts() async {
    try {
      await _ttsCoach.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ttsListo = _ttsCoach.isReady);
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

  Future<void> _responderLectura(String opcion) async {
    if (_completado || _leccion == null) return;
    final pregunta = _preguntaActual;
    if (pregunta == null) return;
    _narracionGen++;
    final correcto = opcion == pregunta.respuestaCorrecta;
    if (correcto) {
      await _ttsCoach.interrupt();
      await _ttsCoach.speak(
        '¡Muy bien!',
        shouldContinue: () =>
            mounted && alfabetizacionTtsRouteActive(context),
      );
      if (!mounted) return;
      await _avanzarSiCorresponde();
      return;
    }
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    await _ttsCoach.interrupt();
    await _ttsCoach.speak(
      'Incorrecto. Intenta otra vez.',
      shouldContinue: () =>
          mounted && alfabetizacionTtsRouteActive(context),
    );
  }

  Future<void> _responderEscritura(String texto) async {
    if (_completado || _leccion == null) return;
    final pregunta = _preguntaActual;
    if (pregunta == null) return;
    _narracionGen++;
    final esperada = (pregunta.respuestaCorrecta ?? '').trim().toUpperCase();
    final correcto = texto.trim().toUpperCase() == esperada;
    if (correcto) {
      await _ttsCoach.interrupt();
      await _ttsCoach.speak(
        '¡Muy bien!',
        shouldContinue: () =>
            mounted && alfabetizacionTtsRouteActive(context),
      );
      if (!mounted) return;
      await _avanzarSiCorresponde();
      return;
    }
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    await _ttsCoach.interrupt();
    await _ttsCoach.speak(
      'No es correcto. Revisa e intenta otra vez.',
      shouldContinue: () =>
          mounted && alfabetizacionTtsRouteActive(context),
    );
  }

  Future<void> _reintentar() async {
    _narracionGen++;
    setState(() {
      _completado = false;
      _correcto = null;
      _escrituraController?.clear();
    });
    await _ttsCoach.interrupt();
    await _narrarPreguntaActual(forzar: true);
  }

  PreguntaData? get _preguntaActual {
    final leccion = _leccion;
    if (leccion == null) return null;
    final preguntas = leccion.preguntas;
    if (_preguntaIndex < 0 || _preguntaIndex >= preguntas.length) return null;
    return preguntas[_preguntaIndex];
  }

  ({int subleccionIndex, int preguntaEnSubleccion})? get _indicesPreguntaActual {
    final sub = _leccion?.sublecciones;
    if (sub == null || sub.isEmpty) return null;
    var acumulado = 0;
    for (var i = 0; i < sub.length; i++) {
      final len = sub[i].preguntas.length;
      if (_preguntaIndex < acumulado + len) {
        return (subleccionIndex: i, preguntaEnSubleccion: _preguntaIndex - acumulado);
      }
      acumulado += len;
    }
    return null;
  }

  Future<void> _avanzarSiCorresponde() async {
    final leccion = _leccion;
    if (leccion == null) return;
    final total = leccion.preguntas.length;
    final haySiguiente = _preguntaIndex + 1 < total;
    if (haySiguiente) {
      setState(() {
        _aciertoAnimacion++;
        _mostrarAciertoIntermedio = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 720));
      if (!mounted) return;
      setState(() {
        _preguntaIndex++;
        _escrituraController?.clear();
        _mostrarAciertoIntermedio = false;
      });
      await _narrarPreguntaActual();
      return;
    }
    _narracionGen++;
    setState(() {
      _correcto = true;
      _completado = true;
    });
    await _guardarProgreso();
    await _ttsCoach.interrupt();
    await _ttsCoach.speakSequence(
      const [
        'Completaste la lección. Muy bien.',
        'Pulsa volver para regresar al menú.',
      ],
      shouldContinue: () =>
          mounted && alfabetizacionTtsRouteActive(context),
    );
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
    if (leccion.flujoId == kFlujoEscrituraTrazosAbecedarioGuiadoId) {
      return EscrituraTrazosAbecedarioLeccionFlow(
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
    final trazosGuiadoConfig = escrituraTrazosConfigForLeccion(leccion.flujoId);
    if (trazosGuiadoConfig != null) {
      return EscrituraTrazosGuiadoLeccionFlow(
        leccion: leccion,
        config: trazosGuiadoConfig,
        onCompletar: _guardarProgreso,
      );
    }
    final tecladoGuiadoConfig = escrituraTecladoConfigForLeccion(leccion.flujoId);
    if (tecladoGuiadoConfig != null) {
      return EscrituraTecladoGuiadoLeccionFlow(
        leccion: leccion,
        config: tecladoGuiadoConfig,
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
              ),
              const SizedBox(height: 18),
              _buildAudioCoachBar(context, leccion),
              const SizedBox(height: 18),
              if (!_completado) ...[
                _buildContenido(context, leccion),
                const SizedBox(height: 24),
                if (leccion.esLectura) _buildOpcionesLectura(context, leccion),
                if (leccion.esEscritura) _buildEntradaEscritura(context, leccion),
              ] else if (_correcto == true) ...[
                _buildResumenExito(context, leccion),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AlfabetizacionUiColors.verdeContinuar,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Volver al módulo'),
                ),
              ] else ...[
                _buildResumenError(context),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _reintentar(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AlfabetizacionUiColors.verdeContinuar,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Salir de la lección'),
                ),
              ],
            ],
          ),
          if (_mostrarAciertoIntermedio)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AlfabetizacionLessonCorrectBanner(
                animationTick: _aciertoAnimacion,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioCoachBar(BuildContext context, LeccionData leccion) {
    final cs = Theme.of(context).colorScheme;
    final disabled = !_ttsListo || _narrando;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: AlfabetizacionLessonTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.headphones_rounded,
              color: AlfabetizacionLessonTokens.accentBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _ttsListo
                  ? 'Guía por voz: pulsa para repetir'
                  : 'Preparando audio…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: disabled ? null : () => unawaited(_narrarPreguntaActual(forzar: true)),
            icon: const Icon(Icons.volume_up_rounded, size: 20),
            label: const Text('Repetir'),
          ),
        ],
      ),
    );
  }

  Future<void> _narrarEntradaLeccion() async {
    final leccion = _leccion;
    if (leccion == null || !_ttsListo) return;
    await _ttsCoach.interrupt();
    await _ttsCoach.speakSequence(
      [
        'Lección: ${leccion.titulo}.',
        'Escucha la pregunta y luego responde.',
        leccion.esLectura
            ? 'Toca una opción para elegir la respuesta.'
            : 'Escribe tu respuesta y luego pulsa comprobar.',
      ],
      shouldContinue: () =>
          mounted && alfabetizacionTtsRouteActive(context),
    );
    await _narrarPreguntaActual();
  }

  Future<void> _narrarPreguntaActual({bool forzar = false}) async {
    final leccion = _leccion;
    final pregunta = _preguntaActual;
    if (leccion == null || pregunta == null || !_ttsListo) return;
    if (!forzar && _audioAutoPreguntaIndex == _preguntaIndex) return;
    _narracionGen++;
    final gen = _narracionGen;
    _audioAutoPreguntaIndex = _preguntaIndex;
    if (!mounted) return;

    setState(() => _narrando = true);
    try {
      await _ttsCoach.interrupt();
      final total = leccion.preguntas.length;
      final actual = (_preguntaIndex + 1).clamp(1, total);
      final partes = <String>[
        'Pregunta $actual de $total.',
        pregunta.contenido,
      ];
      final opciones = pregunta.opciones;
      if (leccion.esLectura && opciones != null && opciones.isNotEmpty) {
        partes.add('Opciones.');
        // Lee las opciones una por una para mejor claridad.
        for (final op in opciones) {
          partes.add(op);
        }
        partes.add('Elige la respuesta correcta.');
      } else if (leccion.esEscritura) {
        partes.add('Escribe tu respuesta y pulsa comprobar.');
      }
      await _ttsCoach.speakSequence(
        partes,
        shouldContinue: () =>
            mounted &&
            gen == _narracionGen &&
            alfabetizacionTtsRouteActive(context),
      );
    } finally {
      if (mounted) setState(() => _narrando = false);
    }
  }

  Widget _buildContenido(BuildContext context, LeccionData leccion) {
    final pregunta = _preguntaActual;
    if (pregunta == null) return const SizedBox.shrink();
    final idx = _indicesPreguntaActual;
    final String textoModelo = pregunta.contenido.trim().toUpperCase();
    const ejemplos = <String, String>{
      'A': 'A de árbol',
      'E': 'E de escoba',
      'I': 'I de iguana',
      'O': 'O de oveja',
      'U': 'U de uva',
    };
    final contexto = ejemplos[textoModelo];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: AlfabetizacionLessonTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Letra modelo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _azulHorizonte,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pregunta.contenido,
            style: const TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: _azulHorizonte,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
          if (contexto != null) ...[
            const SizedBox(height: 4),
            Text(
              contexto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _azulHorizonte.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (idx != null) ...[
            const SizedBox(height: 12),
            Text(
              leccion.sublecciones![idx.subleccionIndex].titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpcionesLectura(BuildContext context, LeccionData leccion) {
    final opciones = _preguntaActual?.opciones ?? [];
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
        const Row(
          children: [
            Icon(Icons.edit, color: _azulHorizonte, size: 16),
            SizedBox(width: 6),
            Text(
              'Ahora escríbela tú',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _azulHorizonte,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Escribe aquí',
            hintText: '...',
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _azulHorizonte,
          ),
          textAlign: TextAlign.center,
          minLines: 1,
          maxLines: 1,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: _responderEscritura,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => _responderEscritura(c.text),
          child: const Text('Comprobar'),
        ),
      ],
    );
  }

  Widget _buildResumenExito(BuildContext context, LeccionData leccion) {
    return AlfabetizacionLessonCompletionPanel(
      headline: '¡Lo lograste!',
      detail: 'Has completado: ${leccion.titulo}',
      pointsLabel: '+${leccion.puntos} puntos',
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
