import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../models/producto.dart';
import '../repositories/productos_repository.dart';

const Color _azulHorizonte = Color(0xFF1A4463);
const Color _crema = Color(0xFFFBF9F1);

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

class ProductoFormScreen extends StatelessWidget {
  const ProductoFormScreen({
    super.key,
    this.producto,
  });

  final Producto? producto;

  @override
  Widget build(BuildContext context) {
    final isEdit = producto != null;
    final titulo = isEdit ? 'Editar producto' : 'Añadir producto';
    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: _ProductoFormBody(
                producto: producto,
                onSaved: () => context.pop(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: ClipPath(
              clipper: _OrganicHeaderClipper(),
              child: Container(color: _azulHorizonte),
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
                          titulo,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tu catálogo · Mercado',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
  final ImagePicker _picker = ImagePicker();
  String _unidad = 'kg';
  bool _saving = false;
  XFile? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _nombreController.text = p.nombre;
      _descripcionController.text = p.descripcion ?? '';
      _precioController.text = p.precio.toString();
      _unidad = p.unidad;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
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
      String? imagenUrl = widget.producto?.imagenUrl;
      if (widget.producto != null) {
        if (_imagenSeleccionada != null) {
          imagenUrl = await _subirImagenProducto(
            userId: user.id,
            productoId: widget.producto!.id,
            imagen: _imagenSeleccionada!,
          );
        }
        await repo.actualizarProducto(
          widget.producto!.id,
          {
            'nombre': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            'precio': precio,
            'unidad': _unidad,
            'lat': lat,
            'lng': lng,
            'imagen_url': imagenUrl,
          },
        );
      } else {
        final productoId = await repo.crearProducto(
          Producto(
            id: '',
            campesinoId: user.id,
            nombre: _nombreController.text.trim(),
            imagenUrl: null,
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: precio,
            cantidadDisponible: null,
            unidad: _unidad,
            lat: lat,
            lng: lng,
          ),
        );
        if (_imagenSeleccionada != null) {
          final nuevaUrl = await _subirImagenProducto(
            userId: user.id,
            productoId: productoId,
            imagen: _imagenSeleccionada!,
          );
          await repo.actualizarProducto(productoId, {'imagen_url': nuevaUrl});
        }
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

  Future<void> _seleccionarImagen() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      if (mounted) {
        setState(() => _imagenSeleccionada = img);
      }
    } catch (_) {}
  }

  Future<String> _subirImagenProducto({
    required String userId,
    required String productoId,
    required XFile imagen,
  }) async {
    final bytes = await imagen.readAsBytes();
    final path = '$userId/$productoId.jpg';
    final storage = Supabase.instance.client.storage.from('productos');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );
    return storage.getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final imagenActual = widget.producto?.imagenUrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4463).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF1A4463),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La cantidad disponible varía día a día y '
                      'se coordina directamente con el comprador.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A4463),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Foto del producto',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4463).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A4463).withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagenPreview(imagenActual),
              ),
            ),
            const SizedBox(height: 16),
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
            DropdownButtonFormField<String>(
              initialValue: _unidad,
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

  Widget _buildImagenPreview(String? imagenActual) {
    if (_imagenSeleccionada != null) {
      if (kIsWeb) {
        return Image.network(
          _imagenSeleccionada!.path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagenPlaceholder(),
        );
      }
      return Image.file(
        File(_imagenSeleccionada!.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagenPlaceholder(),
      );
    }
    if (imagenActual != null && imagenActual.isNotEmpty) {
      return Image.network(
        imagenActual,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagenPlaceholder(),
      );
    }
    return _buildImagenPlaceholder();
  }

  Widget _buildImagenPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            color: _azulHorizonte,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para agregar foto',
            style: TextStyle(
              fontSize: 13,
              color: _azulHorizonte.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
