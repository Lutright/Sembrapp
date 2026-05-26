import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            content: Text(
              '${b.nombre} activado. Tus productos y tu tienda aparecerán primero en comercialización.',
            ),
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
    const azulHorizonte = Color(0xFF1A4463);
    final activosVigentes = _activos.where((a) => a.estaVigente).toList();

    return Scaffold(
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 124, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [azulHorizonte, azulHorizonte.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tus puntos disponibles',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                      fontFamily: 'Montserrat',
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_puntosDisponibles pts',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Montserrat',
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.star_rounded, size: 40, color: Colors.amber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: azulHorizonte.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: azulHorizonte),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ganas puntos al completar lecciones de Aprender. '
                            'Aquí los cambias para que más gente vea tus productos.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: azulHorizonte.withValues(alpha: 0.85),
                                  height: 1.35,
                                  fontFamily: 'Montserrat',
                                ),
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 22),
                  Text(
                    'Beneficios activos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: azulHorizonte,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                  ),
                  Divider(color: azulHorizonte.withValues(alpha: 0.15)),
                  if (activosVigentes.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            size: 36,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aún no tienes beneficios activos. Canjea puntos abajo.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontFamily: 'Montserrat',
                                ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activosVigentes.map(
                      (a) => Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: azulHorizonte.withValues(alpha: 0.12)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.visibility),
                          title: Text(
                            a.beneficioNombre ?? a.beneficioId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Vigente hasta ${a.expiraAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')}',
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Canjear puntos por visibilidad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: azulHorizonte,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                  ),
                  Divider(color: azulHorizonte.withValues(alpha: 0.15)),
                  ..._beneficios.map((b) {
                    final puede = _puntosDisponibles >= b.puntosRequeridos;
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: azulHorizonte.withValues(alpha: 0.12)),
                      ),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Montserrat',
                                        ),
                                  ),
                                ),
                                Text(
                                  '${b.puntosRequeridos} pts',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: azulHorizonte,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                      ),
                                ),
                              ],
                            ),
                            if (b.descripcion != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                b.descripcion!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'Montserrat',
                                    ),
                              ),
                            ],
                            const SizedBox(height: 10),
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
                          'Beneficios',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Canjea puntos por visibilidad',
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
}

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
