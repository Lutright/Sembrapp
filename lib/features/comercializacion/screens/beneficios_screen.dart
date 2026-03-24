import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/minimal_ui.dart';
import '../models/beneficio.dart';
import '../repositories/beneficios_repository.dart';

/// Apartado de beneficios: puntos acumulados en alfabetización
/// y canje por visibilidad temporal en comercialización (solo campesinos).
class BeneficiosScreen extends StatefulWidget {
  const BeneficiosScreen({super.key});

  @override
  State<BeneficiosScreen> createState() => _BeneficiosScreenState();
}

class _BeneficiosScreenState extends State<BeneficiosScreen> {
  final _repo = BeneficiosRepository(Supabase.instance.client);

  int _puntosDisponibles = 0;
  List<Beneficio> _beneficios = [];
  List<BeneficioActivo> _activos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final puntos = await _repo.getPuntosDisponibles(uid);
      final beneficios = await _repo.listarBeneficios();
      final activos = await _repo.getBeneficiosActivosDelCampesino(uid);
      if (mounted) {
        setState(() {
          _puntosDisponibles = puntos;
          _beneficios = beneficios;
          _activos = activos;
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

  Future<void> _activar(Beneficio b) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    if (_puntosDisponibles < b.puntosRequeridos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Necesitas ${b.puntosRequeridos} puntos. Tienes $_puntosDisponibles.',
          ),
        ),
      );
      return;
    }
    setState(() => _error = null);
    try {
      await _repo.activarBeneficio(campesinoId: uid, beneficio: b);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${b.nombre} activado. Tus productos tendrán más visibilidad.'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficios'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppPagePadding.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ganas puntos al completar lecciones de Aprender. '
                    'Aquí los cambias para que más gente vea tus productos.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tus puntos disponibles',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '$_puntosDisponibles',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.stars,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Beneficios activos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_activos.where((a) => a.estaVigente).isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aún no tienes beneficios activos. Canjea puntos abajo.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    ..._activos
                        .where((a) => a.estaVigente)
                        .map((a) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.visibility),
                                title: Text(a.beneficioNombre ?? a.beneficioId),
                                subtitle: Text(
                                  'Vigente hasta ${a.expiraAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')}',
                                ),
                              ),
                            )),
                  const SizedBox(height: 24),
                  Text(
                    'Canjear puntos por visibilidad',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._beneficios.map((b) {
                    final puede = _puntosDisponibles >= b.puntosRequeridos;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    b.nombre,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                Text(
                                  '${b.puntosRequeridos} pts',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            if (b.descripcion != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                b.descripcion!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: puede ? () => _activar(b) : null,
                              icon: const Icon(Icons.card_giftcard),
                              label: Text(puede ? 'Activar (${b.duracionTexto})' : 'Puntos insuficientes'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
