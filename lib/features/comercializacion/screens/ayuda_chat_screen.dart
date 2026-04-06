import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../repositories/orden_ayuda_repository.dart';

/// Chat entre el campesino que pidió ayuda y quien aceptó cubrir productos.
class AyudaChatScreen extends StatefulWidget {
  const AyudaChatScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  State<AyudaChatScreen> createState() => _AyudaChatScreenState();
}

class _AyudaChatScreenState extends State<AyudaChatScreen> {
  final _repo = OrdenAyudaRepository(Supabase.instance.client);
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _solicitud;
  String? _otroNombre;
  List<Map<String, dynamic>> _mensajes = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _cargar();
    _suscribirRealtime();
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
    final nombres = await _repo.nombresCampesinos([otroId]);
    if (!mounted) return;
    setState(() {
      _solicitud = sol;
      _otroNombre = nombres[otroId] ?? 'Productor';
      _loading = false;
    });
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
    if (t.isEmpty) return;
    try {
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
      return Scaffold(
        appBar: AppBar(title: const Text('Ayuda entre productores')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ayuda entre productores'),
          leading: MinimalBackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Padding(
          padding: AppPagePadding.screen,
          child: Text(_error!, textAlign: TextAlign.center),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_otroNombre ?? 'Chat'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'Coordina entrega o entrega de productos con tu colega productor.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Divider(height: 1),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMio
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isMio
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(m['mensaje'] as String? ?? ''),
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
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _enviar,
                ),
              ),
              onSubmitted: (_) => _enviar(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ],
      ),
    );
  }
}
