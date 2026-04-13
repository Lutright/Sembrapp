import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';

// ─── Paleta Sembrapp ─────────────────────────────────────────────────────────
const Color _azulHorizonte = Color(0xFF1A4463);
const Color _rojoManta = Color(0xFFD34836);
const Color _ocre = Color(0xFF6D5E00);
const Color _crema = Color(0xFFFBF9F1);

// ─── OrganicHeaderClipper (idéntico al de las demás pantallas) ────────────────
final class _OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.1,
        0,
        size.height * 0.7,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// ProfileScreen — Reconstrucción integral
// ═════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepo = ProfileRepository(Supabase.instance.client);

  Profile? _profile;
  bool _loading = true;
  bool _saving = false;

  // Controlador de texto – se inicializa en initState, se destruye en dispose.
  late final TextEditingController _nameController;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final p = await _profileRepo.getProfile(user.id);
      if (mounted) {
        setState(() {
          _profile = p;
          _nameController.text = p?.fullName ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSave() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _profileRepo.updateProfile(user.id, fullName: newName);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cambios guardados'),
            backgroundColor: _azulHorizonte,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar'),
            backgroundColor: _rojoManta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onSignOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        _profile?.fullName?.isNotEmpty == true ? _profile!.fullName! : 'Usuario';
    final displayEmail = user?.email ?? '';
    final isCampesino = _profile?.isCampesino ?? false;
    final rolLabel = isCampesino ? 'Productor' : 'Comprador';
    final rolIcon =
        isCampesino ? Icons.agriculture_rounded : Icons.shopping_bag_rounded;

    return Scaffold(
      backgroundColor: _crema,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _azulHorizonte),
            )
          : Column(
              children: [
                // ── Contenido scrolleable ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Header + Avatar (Stack de capas) ─────────────
                        _buildHeaderStack(
                          context,
                          displayName: displayName,
                          displayEmail: displayEmail,
                          rolLabel: rolLabel,
                          rolIcon: rolIcon,
                          isCampesino: isCampesino,
                        ),

                        const SizedBox(height: 24),

                        // ── Tarjeta única de edición ─────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildEditCard(context),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // ── Pie fijo: Cerrar sesión ──────────────────────────────
                _buildLogoutButton(),
              ],
            ),
    );
  }

  // ─── Header Stack ──────────────────────────────────────────────────────────

  Widget _buildHeaderStack(
    BuildContext context, {
    required String displayName,
    required String displayEmail,
    required String rolLabel,
    required IconData rolIcon,
    required bool isCampesino,
  }) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 1. Ola azul orgánica – altura fija 200
        ClipPath(
          clipper: _OrganicHeaderClipper(),
          child: Container(
            height: 200,
            width: double.infinity,
            color: _azulHorizonte,
          ),
        ),

        // 2. Título sobre la ola (debajo del botón atrás en el hit-test)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Text(
                'Mi perfil',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ),

        // 3. Botón atrás — último en el Stack para quedar encima y recibir toques
        Positioned(
          left: 8,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 28),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final role = Supabase.instance.client.auth.currentUser
                            ?.userMetadata?['role']
                        as String?;
                    context.go(
                      role == 'comprador' ? '/comercializacion' : '/home',
                    );
                  }
                },
              ),
            ),
          ),
        ),

        // 4. Avatar Ocre con escudo blanco – posicionado en top ~140
        Positioned(
          top: 140,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // escudo visual blanco
            ),
            padding: const EdgeInsets.all(5),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE8D48B), // Ocre suave
              child: Icon(
                rolIcon,
                size: 46,
                color: _ocre,
              ),
            ),
          ),
        ),

        // 5. Información de usuario debajo del avatar
        Padding(
          padding: const EdgeInsets.only(top: 250),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: const Color(0xFF2D2D2D),
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayEmail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 12),
              // Chip de rol
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isCampesino
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(rolIcon,
                        size: 18,
                        color: isCampesino
                            ? Colors.green.shade700
                            : _azulHorizonte),
                    const SizedBox(width: 8),
                    Text(
                      rolLabel,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCampesino
                            ? Colors.green.shade800
                            : _azulHorizonte,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tarjeta de Edición ────────────────────────────────────────────────────

  Widget _buildEditCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Nombre de usuario',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // TextField con UnderlineInputBorder
          TextField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2D2D),
            ),
            decoration: InputDecoration(
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!, width: 0.8),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _azulHorizonte, width: 2),
              ),
              hintText: 'Escribe tu nombre',
              hintStyle: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 4),

          // Botón cápsula Rojo Manta – ancho completo
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _saving ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rojoManta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _rojoManta.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white70,
                elevation: 2,
                shadowColor: _rojoManta.withValues(alpha: 0.3),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botón Cerrar Sesión ───────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 16),
        child: Center(
          child: TextButton.icon(
          onPressed: _onSignOut,
          icon: Icon(Icons.logout_rounded, size: 20, color: Colors.red[600]),
          label: Text(
            'Cerrar sesión',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
