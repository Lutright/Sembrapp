import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../audio/comercializacion_audio_phrases.dart';
import '../mixins/comercializacion_screen_audio_mixin.dart';
import '../repositories/orden_ayuda_repository.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
const Color _crema = Color(0xFFFBF9F1);

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

/// Chat entre el campesino que pidió ayuda y quien aceptó cubrir productos.
class AyudaChatScreen extends StatefulWidget {
  const AyudaChatScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  State<AyudaChatScreen> createState() => _AyudaChatScreenState();
}

class _AyudaChatScreenState extends State<AyudaChatScreen>
    with ComercializacionScreenAudio {
  void _backFromAyuda(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/comercializacion/red-comunitaria');
    }
  }

  final _repo = OrdenAyudaRepository(Supabase.instance.client);
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _solicitud;
  String? _otroNombre;
  List<Map<String, dynamic>> _mensajes = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;
  RealtimeChannel? _solicitudChannel;
  RealtimeChannel? _ordenChannel;
  Timer? _pollTimer;
  bool _chatHabilitado = true;
  String? _ordenId;

  @override
  void initState() {
    super.initState();
    _cargar();
    _suscribirRealtime();
    initComercializacionScreenAudio(ComercializacionAudioPhrases.ayudaChatWelcome);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _solicitud != null) _cargarMensajes();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mensajeController.dispose();
    _scrollController.dispose();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    if (_solicitudChannel != null) {
      Supabase.instance.client.removeChannel(_solicitudChannel!);
    }
    if (_ordenChannel != null) {
      Supabase.instance.client.removeChannel(_ordenChannel!);
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Inicia sesión';
      });
      return;
    }
    final sol = await _repo.obtenerSolicitud(widget.solicitudId);
    if (!mounted) return;
    if (sol == null) {
      setState(() {
        _loading = false;
        _error = 'Conversación no encontrada';
      });
      return;
    }
    final solicitante = sol['solicitante_id'] as String?;
    final ayudante = sol['ayudante_id'] as String?;
    final estado = sol['estado'] as String? ?? '';
    if (estado != 'cerrada' || ayudante == null) {
      setState(() {
        _loading = false;
        _error = 'Esta ayuda aún no fue aceptada o fue cancelada';
      });
      return;
    }
    if (uid != solicitante && uid != ayudante) {
      setState(() {
        _loading = false;
        _error = 'No participas en esta conversación';
      });
      return;
    }
    final otroId = uid == solicitante ? ayudante : solicitante!;
    _ordenId = sol['orden_id'] as String?;
    final ordenActiva = await _ordenSigueActiva(_ordenId);
    final nombres = await _repo.nombresCampesinos([otroId]);
    if (!mounted) return;
    setState(() {
      _solicitud = sol;
      _otroNombre = nombres[otroId] ?? 'Productor';
      _chatHabilitado = ordenActiva;
      _loading = false;
    });
    _suscribirCambiosSolicitudYOrden();
    await _cargarMensajes();
  }

  void _suscribirRealtime() {
    _channel = Supabase.instance.client
        .channel('ayuda_chat_${widget.solicitudId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ayuda_mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'solicitud_id',
            value: widget.solicitudId,
          ),
          callback: (_) {
            if (mounted) _cargarMensajes();
          },
        )
        .subscribe();
  }

  void _suscribirCambiosSolicitudYOrden() {
    _solicitudChannel ??= Supabase.instance.client
        .channel('ayuda_solicitud_${widget.solicitudId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orden_ayuda_solicitud',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.solicitudId,
          ),
          callback: (_) {
            if (mounted) _cargar();
          },
        )
        .subscribe();

    if (_ordenId != null && _ordenChannel == null) {
      _ordenChannel = Supabase.instance.client
          .channel('ayuda_orden_${_ordenId!}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'ordenes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: _ordenId!,
            ),
            callback: (_) {
              if (mounted) _cargar();
            },
          )
          .subscribe();
    }
  }

  Future<bool> _ordenSigueActiva(String? ordenId) async {
    if (ordenId == null || ordenId.isEmpty) return true;
    try {
      final res = await Supabase.instance.client
          .from('ordenes')
          .select('estado')
          .eq('id', ordenId)
          .maybeSingle();
      final estado = res?['estado'] as String?;
      return (estado ?? '').toLowerCase() != 'cancelada';
    } catch (_) {
      return true;
    }
  }

  Future<void> _cargarMensajes() async {
    try {
      final list = await _repo.listarMensajesSolicitud(widget.solicitudId);
      if (!mounted) return;
      setState(() => _mensajes = list);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {}
  }

  static String _nombreRemitente(Map<String, dynamic> m, String? miId) {
    if (m['sender_id'] == miId) return 'Tú';
    final p = m['profiles'];
    if (p is Map && p['full_name'] != null) return p['full_name'] as String;
    if (p is List && p.isNotEmpty && p.first is Map) {
      return (p.first as Map)['full_name'] as String? ?? 'Usuario';
    }
    return 'Usuario';
  }

  Future<void> _enviar() async {
    final t = _mensajeController.text.trim();
    if (t.isEmpty || !_chatHabilitado) return;
    try {
      await audioSpeakAction('Enviando mensaje.');
      await _repo.enviarMensajeSolicitud(widget.solicitudId, t);
      _mensajeController.clear();
      _cargarMensajes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildBaseScaffold(
        context: context,
        title: 'Ayuda entre productores',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _buildBaseScaffold(
        context: context,
        title: 'Ayuda entre productores',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return _buildBaseScaffold(
      context: context,
      title: _otroNombre ?? 'Chat',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: buildComercializacionAudioCoachBarFor(
              ComercializacionAudioPhrases.ayudaChatWelcome,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _mensajes.length,
              itemBuilder: (context, i) {
                final m = _mensajes[i];
                final uid = Supabase.instance.client.auth.currentUser?.id;
                final isMio = m['sender_id'] == uid;
                final nombre = _nombreRemitente(m, uid);
                return Align(
                  alignment:
                      isMio ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: isMio
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMio ? _azulHorizonte : Colors.white,
                              border: isMio
                                  ? null
                                  : Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.3),
                                    ),
                              borderRadius: isMio
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(2),
                                    )
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(2),
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                            ),
                            child: Text(
                              m['mensaje'] as String? ?? '',
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isMio
                                            ? Colors.white
                                            : const Color(0xFF1A1A1A),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: TextField(
              controller: _mensajeController,
              enabled: _chatHabilitado,
              decoration: InputDecoration(
                hintText:
                    _chatHabilitado ? 'Escribe un mensaje...' : 'Chat inhabilitado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _azulHorizonte.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _azulHorizonte.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide(color: _azulHorizonte, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                isDense: true,
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: _azulHorizonte),
                    onPressed: _chatHabilitado ? _enviar : null,
                  ),
                ),
              ),
              onSubmitted: (_) => _chatHabilitado ? _enviar() : null,
              textInputAction: TextInputAction.send,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseScaffold({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: child,
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
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _backFromAyuda(context),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chat entre productores',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
}
