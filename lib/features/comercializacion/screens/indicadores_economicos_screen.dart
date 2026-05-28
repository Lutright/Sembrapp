import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../audio/comercializacion_audio_phrases.dart';
import '../mixins/comercializacion_screen_audio_mixin.dart';
import '../models/indicador_economico.dart';
import '../repositories/indicadores_repository.dart';

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

/// Precios de referencia para campesinos (fuente externa).
class IndicadoresEconomicosScreen extends StatefulWidget {
  const IndicadoresEconomicosScreen({super.key});

  @override
  State<IndicadoresEconomicosScreen> createState() =>
      _IndicadoresEconomicosScreenState();
}

class _IndicadoresEconomicosScreenState
    extends State<IndicadoresEconomicosScreen>
    with ComercializacionScreenAudio {
  final _repo = IndicadoresRepository(Supabase.instance.client);

  List<IndicadorEconomico> _indicadores = [];
  DateTime? _ultimaActualizacion;
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  String _searchQuery = '';
  int _paginaActual = 0;
  static const int _porPagina = 20;

  String _safePrecio(IndicadorEconomico ind) {
    try {
      return ind.precioFormateado;
    } catch (_) {
      return '-';
    }
  }

  String _safeRango(IndicadorEconomico ind) {
    try {
      return ind.rangoFormateado;
    } catch (_) {
      return '-';
    }
  }

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
    initComercializacionScreenAudio(ComercializacionAudioPhrases.indicadoresWelcome);
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
    await audioSpeakAction(ComercializacionAudioPhrases.indicadoresActualizar);
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
    const azulHorizonte = Color(0xFF1A4463);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: azulHorizonte),
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Precios de referencia',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fuente: SIPSA · DANE',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontFamily: 'Montserrat',
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

    final query = _searchQuery.toLowerCase().trim();
    final filtrados = query.isEmpty
        ? _indicadores
        : _indicadores
            .where(
              (ind) => (ind.productoTipo).toLowerCase().contains(query),
            )
            .toList();
    final totalPaginas = (filtrados.length / _porPagina).ceil();
    final inicio = _paginaActual * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, filtrados.length);
    final paginados = filtrados.sublist(inicio, fin);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 124, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildComercializacionAudioCoachBarFor(
                  ComercializacionAudioPhrases.indicadoresWelcome,
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _paginaActual = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1A4463)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF1A4463).withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF1A4463).withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1A4463),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Última actualización: ${_formatFecha(_ultimaActualizacion)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.9),
                            fontFamily: 'Montserrat',
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: (_loading || _syncing) ? null : _sincronizarDesdeFuente,
                      icon: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1A4463),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (_indicadores.isEmpty && !_loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Toca Actualizar para cargar precios.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else if (filtrados.isEmpty && query.isNotEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No encontramos "$_searchQuery" en los precios SIPSA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final ind = paginados[i];
                  final nombreProducto = (ind.productoTipo).isNotEmpty
                      ? ind.productoTipo
                      : 'Sin nombre';
                  final precio = _safePrecio(ind);
                  final rango = _safeRango(ind);
                  final unidad = (ind.unidad).isNotEmpty ? ind.unidad : 'kg';
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A4463).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.bar_chart,
                                  color: Color(0xFF1A4463),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreProducto,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Montserrat',
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Precio promedio',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: precio,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Montserrat',
                                              color: Color(0xFF1A4463),
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' / $unidad',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Montserrat',
                                              color: Color(0x991A4463),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A4463).withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Rango: $rango',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1A4463),
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: paginados.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _paginaActual == 0
                          ? null
                          : () => setState(() => _paginaActual--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_paginaActual + 1} / $totalPaginas',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A4463),
                      ),
                    ),
                    IconButton(
                      onPressed: _paginaActual >= totalPaginas - 1
                          ? null
                          : () => setState(() => _paginaActual++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }
}
