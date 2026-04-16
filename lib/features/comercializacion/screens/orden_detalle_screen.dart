import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          _orden = res;
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
      if (mounted) setState(() => _solicitudAyudaReciente = res);
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

      final ayudaRepo = OrdenAyudaRepository(Supabase.instance.client);
      await ayudaRepo.eliminarSolicitudesAyudaTrasCancelarPedido(widget.ordenId);
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

  Future<void> _marcarComoEntregado() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final orden = _orden;
    if (uid == null || orden == null) return;
    if (uid != orden['campesino_id']) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmar entrega?'),
        content: const Text(
          'Esto marcará el pedido como completado. El comprador será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, entregar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('ordenes')
          .update({'estado': 'COMPLETADO'})
          .eq('id', widget.ordenId)
          .eq('campesino_id', uid);

      if (!mounted) return;
      setState(() {
        _orden = {
          ..._orden!,
          'estado': 'COMPLETADO',
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido marcado como entregado ✓')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo marcar como entregado: $e')),
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
    const azul = Color(0xFF1A4463);
    const rojo = Color(0xFFD34836);

    if (_loading) {
      return Scaffold(
        body: Column(
          children: [
            _headerCompacto(context, 'Pedido', 'Pedido #...'),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
    if (_orden == null) {
      return Scaffold(
        body: Column(
          children: [
            _headerCompacto(context, 'Pedido', 'Pedido no encontrado'),
            const Expanded(child: Center(child: Text('Orden no encontrada'))),
          ],
        ),
      );
    }
    final estado = _orden!['estado'] as String? ?? 'pendiente';
    final compradorNombre =
        (_orden!['comprador_nombre'] as String?)?.trim().isNotEmpty == true
            ? (_orden!['comprador_nombre'] as String?)!.trim()
            : (_orden!['buyer_name'] as String?)?.trim().isNotEmpty == true
                ? (_orden!['buyer_name'] as String?)!.trim()
                : 'Comprador';
    final productorNombre =
        (_orden!['campesino_nombre'] as String?)?.trim().isNotEmpty == true
            ? (_orden!['campesino_nombre'] as String?)!.trim()
            : (_orden!['seller_name'] as String?)?.trim().isNotEmpty == true
                ? (_orden!['seller_name'] as String?)!.trim()
                : (_orden!['productor_nombre'] as String?)?.trim().isNotEmpty == true
                    ? (_orden!['productor_nombre'] as String?)!.trim()
                    : 'Productor';
    final pedidoId = _orden!['id'] as String? ?? widget.ordenId;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isCompradorDeLaOrden = uid == _orden!['comprador_id'];
    final isCampesinoDeLaOrden = uid == _orden!['campesino_id'];
    final otroParticipanteNombre =
        isCompradorDeLaOrden ? productorNombre : compradorNombre;
    final sol = _solicitudAyudaReciente;
    final estadoSol = sol?['estado'] as String?;
    final sid = sol?['solicitante_id'] as String?;
    final aid = sol?['ayudante_id'] as String?;
    final ayudaAbiertaPropia =
        uid != null && estadoSol == 'abierta' && sid == uid;
    final tieneAyudante =
        aid != null && aid.toString().trim().isNotEmpty;
    final ayudaChatDisponible = uid != null &&
        estadoSol == 'cerrada' &&
        tieneAyudante &&
        (sid == uid || aid == uid);
    /// No pedir de nuevo si hay solicitud abierta o ya hubo una aceptada (hay ayudante).
    final ayudaEnCursoOAtendida = sol != null &&
        (estadoSol == 'abierta' || (estadoSol == 'cerrada' && tieneAyudante));
    final puedeNuevaAyuda = uid != null &&
        isCampesinoDeLaOrden &&
        estado.toLowerCase() != 'cancelada' &&
        !ayudaEnCursoOAtendida;
    final chatPedidoHabilitado = estado.toLowerCase() != 'cancelada';
    final estadoUpper = estado.toUpperCase();
    final estadoLower = estado.toLowerCase();
    final puedeMarcarEntregado = isCampesinoDeLaOrden &&
        (estadoLower == 'pendiente' ||
            estadoLower == 'confirmado' ||
            estadoLower == 'confirmada');

    Color estadoBg;
    Color estadoFg;
    if (estadoLower == 'pendiente' || estadoLower == 'creada') {
      estadoBg = const Color(0xFFFFF3CD);
      estadoFg = const Color(0xFF856404);
    } else if (estadoLower == 'confirmado' ||
        estadoLower == 'confirmada' ||
        estadoLower == 'aceptado' ||
        estadoLower == 'aceptada' ||
        estadoLower == 'ac') {
      estadoBg = const Color(0xFFD4EDDA);
      estadoFg = const Color(0xFF155724);
    } else if (estadoLower == 'cancelada' || estadoLower == 'cancelado') {
      estadoBg = rojo.withValues(alpha: 0.10);
      estadoFg = rojo;
    } else if (estadoLower == 'completado' ||
        estadoLower == 'completada' ||
        estadoLower == 'entregado') {
      estadoBg = Colors.green.withValues(alpha: 0.10);
      estadoFg = Colors.green.shade700;
    } else {
      estadoBg = azul.withValues(alpha: 0.10);
      estadoFg = azul;
    }

    return Scaffold(
      body: Column(
        children: [
          _headerCompacto(
            context,
            compradorNombre,
            'Pedido #${pedidoId.length > 8 ? pedidoId.substring(0, 8) : pedidoId}',
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del pedido',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: azul,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'Montserrat',
                                    ),
                          ),
                          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: estadoBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              estadoUpper,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: estadoFg,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Montserrat',
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._items.map((row) {
                            final cant = (row['cantidad'] as num?)?.toDouble() ?? 0;
                            final pu = (row['precio_unitario'] as num?)?.toDouble() ?? 0;
                            final sub = cant * pu;
                            final u = _unidadProducto(row);
                            final unidad = u.isEmpty ? '' : ' $u';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_nombreProducto(row)} · '
                                      '${cant.toStringAsFixed(cant == cant.roundToDouble() ? 0 : 1)}$unidad',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 14,
                                            fontFamily: 'Montserrat',
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${sub.toStringAsFixed(0)} \$',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          fontFamily: 'Montserrat',
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Divider(color: Colors.grey.withValues(alpha: 0.2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Montserrat',
                                    ),
                              ),
                              Text(
                                '${_totalItems(_items).toStringAsFixed(0)} \$',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontSize: 15,
                                      color: azul,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Montserrat',
                                    ),
                              ),
                            ],
                          ),
                          if (isCampesinoDeLaOrden && estadoLower == 'pendiente') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _confirmarCancelarPedido,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: rojo,
                                  side: const BorderSide(color: rojo),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('Cancelar pedido'),
                              ),
                            ),
                          ],
                          if (puedeMarcarEntregado) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _marcarComoEntregado,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text('Marcar como entregado'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (ayudaChatDisponible) ...[
                      const SizedBox(height: 12),
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
                    if (isCampesinoDeLaOrden &&
                        (ayudaAbiertaPropia || puedeNuevaAyuda)) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: azul.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  color: azul,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ayuda en la comunidad',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: azul,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Marca los productos que no puedes cubrir. Otros productores cercanos verán tu pedido y podrán ayudarte por chat.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontFamily: 'Montserrat',
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
                                      const Icon(Icons.visibility_rounded, color: azul),
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
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _items.any((e) => e['id'] != null)
                                      ? _mostrarDialogoPedirAyuda
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: rojo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Pedir ayuda con productos'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: azul,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Chat con el comprador',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: azul,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                              ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey.withValues(alpha: 0.2), height: 16),
                    if (!chatPedidoHabilitado)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Pedido cancelado — Chat inhabilitado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ..._mensajes.asMap().entries.map((entry) {
                            final i = entry.key;
                            final m = entry.value;
                            final miId = Supabase.instance.client.auth.currentUser?.id;
                            final isMio = m['sender_id'] == miId;
                            final nombre = isMio ? 'Tú' : otroParticipanteNombre;
                            final prev = i > 0 ? _mensajes[i - 1] : null;
                            final prevMio = prev != null && prev['sender_id'] == miId;
                            final mostrarNombre = i == 0 || prevMio != isMio;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: isMio
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (mostrarNombre)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        nombre,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.withValues(alpha: 0.9),
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment: isMio
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width * 0.76,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMio ? azul : Colors.white,
                                          border: isMio
                                              ? null
                                              : Border.all(
                                                  color: Colors.grey.withValues(alpha: 0.5),
                                                  width: 0.5,
                                                ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(isMio ? 12 : 2),
                                            topRight: Radius.circular(isMio ? 12 : 12),
                                            bottomLeft: Radius.circular(isMio ? 12 : 12),
                                            bottomRight: Radius.circular(isMio ? 2 : 12),
                                          ),
                                        ),
                                        child: Text(
                                          m['mensaje'] as String? ?? '',
                                          style:
                                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: isMio
                                                        ? Colors.white
                                                        : const Color(0xFF1A1A1A),
                                                    fontFamily: 'Montserrat',
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    enabled: chatPedidoHabilitado,
                    decoration: InputDecoration(
                      hintText: chatPedidoHabilitado
                          ? 'Escribe un mensaje...'
                          : 'Chat inhabilitado',
                      hintStyle: const TextStyle(fontFamily: 'Montserrat'),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: azul.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: azul,
                          width: 1.2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: azul.withValues(alpha: 0.25),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) =>
                        chatPedidoHabilitado ? _enviarMensaje() : null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: azul,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: chatPedidoHabilitado ? _enviarMensaje : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCompacto(BuildContext context, String titulo, String subtitulo) {
    return Container(
      color: const Color(0xFF1A4463),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            children: [
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => _backFromOrden(context),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                          ),
                    ),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontFamily: 'Montserrat',
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
