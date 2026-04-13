import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../repositories/orden_ayuda_repository.dart';
import '../repositories/ordenes_repository.dart';

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
  void _backFromOrden(BuildContext context) {
    context.go('/comercializacion/ordenes');
  }

  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _items = [];
  /// Última solicitud de ayuda para este pedido (si existe).
  Map<String, dynamic>? _solicitudAyudaReciente;
  List<Map<String, dynamic>> _mensajes = [];
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _ordenChannel;
  RealtimeChannel? _ayudaChannel;
  Timer? _pollTimer;
  final _ordenesRepo = OrdenesRepository(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadOrden();
    _suscribirMensajesRealtime();
    _suscribirCambiosOrden();
    _suscribirCambiosAyuda();
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
    if (_ordenChannel != null) {
      Supabase.instance.client.removeChannel(_ordenChannel!);
    }
    if (_ayudaChannel != null) {
      Supabase.instance.client.removeChannel(_ayudaChannel!);
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

  void _suscribirCambiosOrden() {
    _ordenChannel = Supabase.instance.client
        .channel('orden_estado_${widget.ordenId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ordenes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.ordenId,
          ),
          callback: (_) {
            if (mounted) _loadOrden();
          },
        )
        .subscribe();
  }

  void _suscribirCambiosAyuda() {
    _ayudaChannel = Supabase.instance.client
        .channel('orden_ayuda_${widget.ordenId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orden_ayuda_solicitud',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'orden_id',
            value: widget.ordenId,
          ),
          callback: (_) {
            if (mounted) _loadSolicitudAyudaReciente();
          },
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
      if (mounted) {
        setState(() {
          _orden = res as Map<String, dynamic>?;
          _loading = false;
        });
      }
      if (res != null) {
        await _loadItems();
        if (mounted) await _loadSolicitudAyudaReciente();
        _loadMensajes();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadItems() async {
    try {
      final res = await Supabase.instance.client
          .from('orden_items')
          .select('id, cantidad, precio_unitario, productos(nombre, unidad)')
          .eq('orden_id', widget.ordenId);
      if (!mounted) return;
      setState(() => _items = List<Map<String, dynamic>>.from(res as List));
    } catch (_) {
      if (mounted) setState(() => _items = []);
    }
  }

  Future<void> _loadSolicitudAyudaReciente() async {
    try {
      final res = await Supabase.instance.client
          .from('orden_ayuda_solicitud')
          .select()
          .eq('orden_id', widget.ordenId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted) setState(() => _solicitudAyudaReciente = res as Map<String, dynamic>?);
    } catch (_) {
      if (mounted) setState(() => _solicitudAyudaReciente = null);
    }
  }

  Future<void> _publicarSolicitudAyuda(List<String> itemIds, String? nota) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = OrdenAyudaRepository(Supabase.instance.client);
    final ubic = await repo.ubicacionParaPublicar(uid);
    if (ubic == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa la ubicación o publica productos con coordenadas para situarte en el mapa de la red.',
            ),
          ),
        );
      }
      return;
    }
    try {
      await repo.crearSolicitud(
        ordenId: widget.ordenId,
        solicitanteId: uid,
        itemIds: itemIds,
        lat: ubic.lat,
        lng: ubic.lng,
        nota: nota,
      );
      if (mounted) {
        await _loadSolicitudAyudaReciente();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu pedido de ayuda ya es visible para productores cercanos.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo publicar: $e')),
        );
      }
    }
  }

  Future<void> _cancelarSolicitudAyuda() async {
    final s = _solicitudAyudaReciente;
    if (s == null || (s['estado'] as String?) != 'abierta') return;
    final id = s['id'] as String?;
    if (id == null) return;
    try {
      await OrdenAyudaRepository(Supabase.instance.client).cancelarSolicitud(id);
      if (mounted) {
        await _loadSolicitudAyudaReciente();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud retirada de la red')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoPedirAyuda() async {
    if (!_items.any((e) => e['id'] != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay líneas de pedido con identificador')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PedirAyudaDialog(
        items: _items,
        onPublicar: (ids, nota) async {
          Navigator.pop(ctx);
          await _publicarSolicitudAyuda(ids, nota);
        },
      ),
    );
  }

  Future<void> _confirmarCancelarPedido() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          'Este pedido quedará cancelado para ambas partes. '
          'Úsalo solo si no puedes cumplir la orden y no recibiste ayuda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar pedido'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    try {
      final cancelada = await _ordenesRepo.cancelarOrdenComoCampesino(
        ordenId: widget.ordenId,
        campesinoId: uid,
      );
      if (!mounted) return;
      if (!cancelada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cancelar (puede que ya esté cerrada).'),
          ),
        );
        return;
      }

      if (_solicitudAyudaReciente?['estado'] == 'abierta') {
        final solicitudId = _solicitudAyudaReciente?['id'] as String?;
        if (solicitudId != null) {
          await OrdenAyudaRepository(Supabase.instance.client)
              .cancelarSolicitud(solicitudId);
        }
      }
      await _loadOrden();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cancelar: $e')),
      );
    }
  }

  static String _nombreProducto(Map<String, dynamic> row) {
    final p = row['productos'];
    if (p is Map && p['nombre'] != null) return p['nombre'] as String;
    if (p is List && p.isNotEmpty && p.first is Map) {
      return (p.first as Map)['nombre'] as String? ?? 'Producto';
    }
    return 'Producto';
  }

  static String _unidadProducto(Map<String, dynamic> row) {
    final p = row['productos'];
    if (p is Map && p['unidad'] != null) return p['unidad'] as String;
    if (p is List && p.isNotEmpty && p.first is Map) {
      return (p.first as Map)['unidad'] as String? ?? '';
    }
    return '';
  }

  static double _totalItems(List<Map<String, dynamic>> items) {
    var s = 0.0;
    for (final row in items) {
      final c = (row['cantidad'] as num?)?.toDouble() ?? 0;
      final pu = (row['precio_unitario'] as num?)?.toDouble() ?? 0;
      s += c * pu;
    }
    return s;
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
    final estado = (_orden?['estado'] as String? ?? '').toLowerCase();
    if (texto.isEmpty || _orden == null || estado == 'cancelada') return;
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
        appBar: AppBar(
          title: const Text('Orden'),
          leading: MinimalBackButton(onPressed: () => _backFromOrden(context)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_orden == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Orden'),
          leading: MinimalBackButton(onPressed: () => _backFromOrden(context)),
        ),
        body: const Center(child: Text('Orden no encontrada')),
      );
    }
    final estado = _orden!['estado'] as String? ?? 'pendiente';
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isCampesinoDeLaOrden = uid == _orden!['campesino_id'];
    final sol = _solicitudAyudaReciente;
    final estadoSol = sol?['estado'] as String?;
    final sid = sol?['solicitante_id'] as String?;
    final aid = sol?['ayudante_id'] as String?;
    final ayudaAbiertaPropia =
        uid != null && estadoSol == 'abierta' && sid == uid;
    final ayudaChatDisponible = uid != null &&
        estadoSol == 'cerrada' &&
        aid != null &&
        (sid == uid || aid == uid);
    final puedeNuevaAyuda = uid != null &&
        isCampesinoDeLaOrden &&
        !ayudaAbiertaPropia &&
        !(estadoSol == 'cerrada' && aid != null);
    final chatPedidoHabilitado = estado.toLowerCase() != 'cancelada';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido'),
        leading: MinimalBackButton(onPressed: () => _backFromOrden(context)),
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
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Productos del pedido',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._items.map((row) {
                        final cant =
                            (row['cantidad'] as num?)?.toDouble() ?? 0;
                        final pu =
                            (row['precio_unitario'] as num?)?.toDouble() ?? 0;
                        final sub = cant * pu;
                        final u = _unidadProducto(row);
                        final unidad = u.isEmpty ? '' : ' $u';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${_nombreProducto(row)} · '
                                  '${cant.toStringAsFixed(cant == cant.roundToDouble() ? 0 : 1)}$unidad',
                                ),
                              ),
                              Text('${sub.toStringAsFixed(0)} \$'),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${_totalItems(_items).toStringAsFixed(0)} \$',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                    if (ayudaChatDisponible) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      FilledButton.icon(
                        onPressed: () {
                          final id = sol?['id'] as String?;
                          if (id != null) {
                            context.push('/comercializacion/ayuda-chat/$id');
                          }
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Chat entre productores (ayuda)'),
                      ),
                    ],
                    if (isCampesinoDeLaOrden) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Text(
                        'Ayuda en la comunidad',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Marca los productos que no puedes cubrir. Otros productores cercanos verán tu pedido y podrán ayudarte por chat.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (ayudaAbiertaPropia)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Tu solicitud está visible en Red comunitaria → Ayuda.',
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _cancelarSolicitudAyuda,
                              child: const Text('Retirar de la red'),
                            ),
                          ],
                        )
                      else if (puedeNuevaAyuda)
                        FilledButton.tonalIcon(
                          onPressed: _items.any((e) => e['id'] != null)
                              ? _mostrarDialogoPedirAyuda
                              : null,
                          icon: const Icon(Icons.volunteer_activism_rounded),
                          label: const Text('Pedir ayuda con productos'),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: estado.toLowerCase() == 'cancelada'
                            ? null
                            : _confirmarCancelarPedido,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar pedido'),
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
                    isCampesinoDeLaOrden
                        ? (chatPedidoHabilitado
                            ? 'Chat con el comprador — Acuerden el punto de encuentro para la entrega'
                            : 'Pedido cancelado — Chat inhabilitado')
                        : (chatPedidoHabilitado
                            ? 'Chat con el productor — Acuerden el punto de encuentro para la entrega'
                            : 'Pedido cancelado — Chat inhabilitado'),
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
                    enabled: chatPedidoHabilitado,
                    decoration: InputDecoration(
                      hintText: chatPedidoHabilitado
                          ? 'Ej: Punto de encuentro: plaza central a las 3pm'
                          : 'Chat inhabilitado',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: chatPedidoHabilitado ? _enviarMensaje : null,
                      ),
                    ),
                    onSubmitted: (_) =>
                        chatPedidoHabilitado ? _enviarMensaje() : null,
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

class _PedirAyudaDialog extends StatefulWidget {
  const _PedirAyudaDialog({
    required this.items,
    required this.onPublicar,
  });

  final List<Map<String, dynamic>> items;
  final Future<void> Function(List<String> ids, String? nota) onPublicar;

  @override
  State<_PedirAyudaDialog> createState() => _PedirAyudaDialogState();
}

class _PedirAyudaDialogState extends State<_PedirAyudaDialog> {
  final _nota = TextEditingController();
  final Set<String> _marcados = {};

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  static String _nombre(Map<String, dynamic> row) {
    final p = row['productos'];
    if (p is Map && p['nombre'] != null) return p['nombre'] as String;
    if (p is List && p.isNotEmpty && p.first is Map) {
      return (p.first as Map)['nombre'] as String? ?? 'Producto';
    }
    return 'Producto';
  }

  @override
  Widget build(BuildContext context) {
    final conId = widget.items.where((e) => e['id'] != null).toList();
    return AlertDialog(
      title: const Text('Pedir ayuda en la comunidad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona los productos que no puedes entregar.',
            ),
            const SizedBox(height: 12),
            ...conId.map((row) {
              final id = row['id'] as String;
              final cant = (row['cantidad'] as num?)?.toDouble() ?? 0;
              return CheckboxListTile(
                value: _marcados.contains(id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _marcados.add(id);
                    } else {
                      _marcados.remove(id);
                    }
                  });
                },
                title: Text(_nombre(row)),
                subtitle: Text('Cantidad: $cant'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _nota,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: Necesito apoyo con la entrega el viernes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _marcados.isEmpty
              ? null
              : () => widget.onPublicar(
                    _marcados.toList(),
                    _nota.text.trim().isEmpty ? null : _nota.text.trim(),
                  ),
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}
