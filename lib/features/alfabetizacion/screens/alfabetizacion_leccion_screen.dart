import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../data/lecciones_data.dart';
import '../repositories/alfabetizacion_repository.dart';
import '../services/alfabetizacion_tts_coach.dart';
import '../widgets/abecedario_leccion_flow.dart';
import '../widgets/escritura_vocales_leccion_flow.dart';
import '../widgets/lectura_guiada_leccion_flow.dart';
import '../widgets/vocales_leccion_flow.dart';

const Color _azulHorizonte = Color(0xFF1A4463);

final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.06,
        0,
        size.height * 0.78,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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

  void _responderLectura(String opcion) {
    if (_completado || _leccion == null) return;
    final pregunta = _preguntaActual;
    if (pregunta == null) return;
    final correcto = opcion == pregunta.respuestaCorrecta;
    if (correcto) {
      unawaited(_ttsCoach.interrupt());
      unawaited(_ttsCoach.speak('¡Muy bien!'));
      _avanzarSiCorresponde();
      return;
    }
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    unawaited(_ttsCoach.interrupt());
    unawaited(_ttsCoach.speak('Incorrecto. Intenta otra vez.'));
  }

  void _responderEscritura(String texto) {
    if (_completado || _leccion == null) return;
    final pregunta = _preguntaActual;
    if (pregunta == null) return;
    final esperada = (pregunta.respuestaCorrecta ?? '').trim().toUpperCase();
    final correcto = texto.trim().toUpperCase() == esperada;
    if (correcto) {
      unawaited(_ttsCoach.interrupt());
      unawaited(_ttsCoach.speak('¡Muy bien!'));
      _avanzarSiCorresponde();
      return;
    }
    setState(() {
      _correcto = correcto;
      _completado = true;
    });
    unawaited(_ttsCoach.interrupt());
    unawaited(_ttsCoach.speak('No es correcto. Revisa e intenta otra vez.'));
  }

  void _reintentar() {
    setState(() {
      _completado = false;
      _correcto = null;
      _escrituraController?.clear();
    });
    unawaited(_ttsCoach.interrupt());
    unawaited(_narrarPreguntaActual(forzar: true));
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
        _preguntaIndex++;
        _escrituraController?.clear();
      });
      unawaited(_narrarPreguntaActual());
      return;
    }
    setState(() {
      _correcto = true;
      _completado = true;
    });
    await _guardarProgreso();
    unawaited(_ttsCoach.interrupt());
    unawaited(_ttsCoach.speakSequence(const [
      'Completaste la lección. Muy bien.',
      'Pulsa volver para regresar al menú.',
    ]));
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Responde todas las preguntas para completar esta lección.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildProgresoPregunta(context, leccion),
                    const SizedBox(height: 12),
                    _buildAudioCoachBar(context, leccion),
                    const SizedBox(height: 16),
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
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: _azulHorizonte),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize:
                              const Size(kMinimalTouchTarget, kMinimalTouchTarget),
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          leccion.titulo,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${leccion.esLectura ? 'Lectura' : 'Escritura'} · Nivel ${leccion.nivel}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        color: _azulHorizonte.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.headphones_rounded, color: cs.primary, size: 20),
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
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: disabled ? null : () => unawaited(_narrarPreguntaActual(forzar: true)),
            icon: const Icon(Icons.volume_up_rounded),
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
    await _ttsCoach.speakSequence([
      'Lección: ${leccion.titulo}.',
      'Escucha la pregunta y luego responde.',
      leccion.esLectura
          ? 'Toca una opción para elegir la respuesta.'
          : 'Escribe tu respuesta y luego pulsa comprobar.',
    ]);
    await _narrarPreguntaActual();
  }

  Future<void> _narrarPreguntaActual({bool forzar = false}) async {
    final leccion = _leccion;
    final pregunta = _preguntaActual;
    if (leccion == null || pregunta == null || !_ttsListo) return;
    if (!forzar && _audioAutoPreguntaIndex == _preguntaIndex) return;
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
      await _ttsCoach.speakSequence(partes);
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
        color: _azulHorizonte.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Letra modelo',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
                color: _azulHorizonte.withOpacity(0.6),
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
        Row(
          children: [
            const Icon(Icons.edit, color: _azulHorizonte, size: 16),
            const SizedBox(width: 6),
            Text(
              'Ahora escríbela tú',
              style: const TextStyle(
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

  Widget _buildProgresoPregunta(BuildContext context, LeccionData leccion) {
    final total = leccion.preguntas.length;
    final actual = (_preguntaIndex + 1).clamp(1, total);
    return Text(
      'Pregunta $actual de $total',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
      textAlign: TextAlign.center,
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
