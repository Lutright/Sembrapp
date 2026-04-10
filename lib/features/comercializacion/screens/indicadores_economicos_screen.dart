import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../models/indicador_economico.dart';
import '../repositories/indicadores_repository.dart';

/// Precios de referencia para campesinos (fuente externa).
class IndicadoresEconomicosScreen extends StatefulWidget {
  const IndicadoresEconomicosScreen({super.key});

  @override
  State<IndicadoresEconomicosScreen> createState() =>
      _IndicadoresEconomicosScreenState();
}

class _IndicadoresEconomicosScreenState
    extends State<IndicadoresEconomicosScreen> {
  final _repo = IndicadoresRepository(Supabase.instance.client);

  List<IndicadorEconomico> _indicadores = [];
  DateTime? _ultimaActualizacion;
  bool _loading = true;
  bool _syncing = false;
  String? _error;

  static DateTime _toColombia(DateTime d) {
    // Colombia permanece en UTC-5 todo el año.
    return d.toUtc().subtract(const Duration(hours: 5));
  }

  static String _formatFecha(DateTime? d) {
    if (d == null) return '—';
    final c = _toColombia(d);
    final day = c.day.toString().padLeft(2, '0');
    final month = c.month.toString().padLeft(2, '0');
    final year = c.year;
    final h = c.hour.toString().padLeft(2, '0');
    final m = c.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $h:$m';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.listar();
      final last = await _repo.ultimaActualizacion();
      if (mounted) {
        setState(() {
          _indicadores = list;
          _ultimaActualizacion = last;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _sincronizarDesdeFuente() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      final result = await _repo.sincronizarDesdeFuente();
      if (!mounted) return;
      if (result.ok) {
        if (result.started) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sincronización en progreso. Actualizando en unos segundos...'),
            ),
          );
          await Future.delayed(const Duration(seconds: 15));
          await _load();
        } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Actualizados ${result.actualizados} indicadores desde ${result.fuente}.',
              ),
            ),
          );
          await _load();
        }
      } else {
        setState(() => _error = result.error);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores económicos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton.icon(
              onPressed: _loading ? null : _sincronizarDesdeFuente,
              icon: const Icon(Icons.sync, size: 20),
              label: const Text('Actualizar desde SIPSA'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _indicadores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _indicadores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () { setState(() => _error = null); _load(); },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sirven de guía para poner el precio a tus productos.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.update, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _ultimaActualizacion != null
                          ? 'Última actualización: ${_formatFecha(_ultimaActualizacion)}'
                          : 'Sin datos aún. Pulse "Actualizar desde fuente".',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_indicadores.isEmpty && !_loading)
          const SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: AppPagePadding.screen,
                child: Text(
                  'Toca Actualizar arriba para cargar precios.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final ind = _indicadores[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.analytics, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    title: Text(
                      ind.productoTipo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text('Precio promedio: ${ind.precioFormateado} / ${ind.unidad}'),
                        if (ind.rangoMin != null || ind.rangoMax != null)
                          Text('Rango: ${ind.rangoFormateado}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        if (ind.fuente != null && ind.fuente!.isNotEmpty)
                          Text('Fuente: ${ind.fuente}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
              childCount: _indicadores.length,
            ),
          ),
      ],
    );
  }
}
