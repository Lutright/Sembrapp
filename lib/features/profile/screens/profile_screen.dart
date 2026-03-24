import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/widgets/minimal_ui.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final p = await _profileRepo.getProfile(user.id);
      if (mounted) setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppPagePadding.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: cs.primaryContainer.withOpacity(0.6),
                          child: Icon(
                            _profile?.isCampesino == true
                                ? Icons.agriculture_rounded
                                : Icons.shopping_bag_rounded,
                            size: 52,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profile?.fullName?.isNotEmpty == true
                              ? _profile!.fullName!
                              : 'Usuario',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          avatar: Icon(
                            _profile?.isCampesino == true
                                ? Icons.agriculture_rounded
                                : Icons.shopping_bag_rounded,
                            size: 20,
                            color: cs.primary,
                          ),
                          label: Text(
                            _profile?.role == 'campesino' ? 'Productor' : 'Comprador',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cambiar nombre',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _EditProfileForm(
                    initialName: _profile?.fullName ?? '',
                    saving: _saving,
                    onSave: _onSave,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _onSave(String fullName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await _profileRepo.updateProfile(user.id, fullName: fullName);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({
    required this.initialName,
    required this.saving,
    required this.onSave,
  });

  final String initialName;
  final bool saving;
  final void Function(String fullName) onSave;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Escribe tu nombre' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.saving
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave(_nameController.text.trim());
                    }
                  },
            child: widget.saving
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
