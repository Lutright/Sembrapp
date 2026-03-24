import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';

class OrdenDetalleScreen extends StatefulWidget {
  const OrdenDetalleScreen({
    super.key,
    required this.ordenId,
  });

  final String ordenId;

  @override
  State<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _mensajes = [];
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  RealtimeChannel? _realtimeChannel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrden();
    _suscribirMensajesRealtime();
    _iniciarPollingMensajes();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mensajeController.dispose();
    _scrollController.dispose();
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  void _iniciarPollingMensajes() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _orden != null) _loadMensajes();
    });
  }

  void _suscribirMensajesRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('orden_chat_${widget.ordenId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orden_mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'orden_id',
            value: widget.ordenId,
          ),
          callback: _onNuevoMensajeRealtime,
        )
        .subscribe();
  }

  void _onNuevoMensajeRealtime(PostgresChangePayload payload) {
    final senderId = payload.newRecord['sender_id'] as String?;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (senderId != null && senderId != uid && mounted) {
      _loadMensajes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nuevo mensaje en el chat'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      _loadMensajes();
    }
  }

  Future<void> _loadOrden() async {
    try {
      final res = await Supabase.instance.client
          .from('ordenes')
          .select()
          .eq('id', widget.ordenId)
          .maybeSingle();
      if (mounted) setState(() {
        _orden = res as Map<String, dynamic>?;
        _loading = false;
      });
      if (res != null) _loadMensajes();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMensajes() async {
    final res = await Supabase.instance.client
        .from('orden_mensajes')
        .select('*, profiles(full_name)')
        .eq('orden_id', widget.ordenId)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() => _mensajes = List<Map<String, dynamic>>.from(res as List));
      _irAlFinalDelChat();
    }
  }

  void _irAlFinalDelChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _orden == null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await Supabase.instance.client.from('orden_mensajes').insert({
      'orden_id': widget.ordenId,
      'sender_id': uid,
      'mensaje': texto,
    });
    _mensajeController.clear();
    _loadMensajes();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orden')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_orden == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orden')),
        body: const Center(child: Text('Orden no encontrada')),
      );
    }
    final estado = _orden!['estado'] as String? ?? 'pendiente';
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isCampesinoDeLaOrden = uid == _orden!['campesino_id'];
    final compartidaEnRed = _orden!['compartida_en_red'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aquí acuerdan punto de encuentro y detalles.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estado: $estado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isCampesinoDeLaOrden) ...[
                      const SizedBox(height: 12),
                      compartidaEnRed
                          ? Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text('Compartida en la red comunitaria'),
                              ],
                            )
                          : FilledButton.tonalIcon(
                              onPressed: () async {
                                await Supabase.instance.client
                                    .from('ordenes')
                                    .update({
                                  'compartida_en_red': true,
                                  'compartida_at':
                                      DateTime.now().toIso8601String(),
                                }).eq('id', widget.ordenId);
                                _loadOrden();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Orden compartida en la red')),
                                );
                              }
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Compartir en red comunitaria'),
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat con el productor — Acuerden aquí el punto de encuentro para la entrega',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
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
                  alignment: isMio ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isMio
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary,
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Punto de encuentro: plaza central a las 3pm',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _enviarMensaje,
                      ),
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
