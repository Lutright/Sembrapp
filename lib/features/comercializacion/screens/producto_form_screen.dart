import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/minimal_ui.dart';
import '../models/producto.dart';
import '../repositories/productos_repository.dart';

class ProductoFormScreen extends StatelessWidget {
  const ProductoFormScreen({
    super.key,
    this.producto,
  });

  final Producto? producto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(producto == null ? 'Nuevo producto' : 'Editar producto'),
        leading: MinimalBackButton(onPressed: () => context.pop()),
      ),
      body: _ProductoFormBody(
        producto: producto,
        onSaved: () => context.pop(),
      ),
    );
  }
}

class _ProductoFormBody extends StatefulWidget {
  const _ProductoFormBody({
    this.producto,
    required this.onSaved,
  });

  final Producto? producto;
  final VoidCallback onSaved;

  @override
  State<_ProductoFormBody> createState() => _ProductoFormBodyState();
}

class _ProductoFormBodyState extends State<_ProductoFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  String _unidad = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _nombreController.text = p.nombre;
      _descripcionController.text = p.descripcion ?? '';
      _precioController.text = p.precio.toString();
      _cantidadController.text = p.cantidadDisponible.toString();
      _unidad = p.unidad;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final repo = ProductosRepository(Supabase.instance.client);
      final pos = await LocationService.instance.getLastKnownOrFetch();
      final lat = pos?.latitude;
      final lng = pos?.longitude;
      if (lat == null || lng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activa ubicación para publicar este producto'),
            ),
          );
        }
        return;
      }
      final precio = double.tryParse(_precioController.text) ?? 0;
      final cantidad = double.tryParse(_cantidadController.text) ?? 0;
      if (widget.producto != null) {
        await repo.actualizarProducto(
          widget.producto!.id,
          {
            'nombre': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            'precio': precio,
            'cantidad_disponible': cantidad,
            'unidad': _unidad,
            'lat': lat,
            'lng': lng,
          },
        );
      } else {
        await repo.crearProducto(
          Producto(
            id: '',
            campesinoId: user.id,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: precio,
            cantidadDisponible: cantidad,
            unidad: _unidad,
            lat: lat,
            lng: lng,
          ),
        );
      }
      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar producto')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppPagePadding.screen,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Completa los datos de tu producto.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.shopping_basket),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción corta',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad disponible',
                prefixIcon: Icon(Icons.scale),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _unidad,
              decoration: const InputDecoration(
                labelText: 'Unidad',
              ),
              items: const [
                DropdownMenuItem(value: 'kg', child: Text('kg')),
                DropdownMenuItem(value: 'lb', child: Text('lb')),
                DropdownMenuItem(value: 'unidad', child: Text('unidad')),
              ],
              onChanged: (v) => setState(() => _unidad = v ?? 'kg'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
