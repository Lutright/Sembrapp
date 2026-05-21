import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/tutorial/models/tutorial_step.dart';
import '../../../core/tutorial/tutorial_runner.dart';
import '../../../core/tutorial/tutorial_service.dart';
import '../../../core/tutorial/widgets/tutorial_help_button.dart';
import '../models/producto.dart';
import '../repositories/productos_repository.dart';
import '../tutorial/producto_publicacion_tutorial.dart';
import '../tutorial/comercializacion_tutorial_keys.dart';

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

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    this.producto,
  });

  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _scrollController = ScrollController();
  final _tutorialInfo = GlobalKey();
  final _tutorialFoto = GlobalKey();
  final _tutorialNombre = GlobalKey();
  final _tutorialDescripcion = GlobalKey();
  final _tutorialPrecio = GlobalKey();
  final _tutorialUnidad = GlobalKey();
  final _tutorialGuardar = GlobalKey();
  final _tutorialAyuda = GlobalKey();
  List<TutorialStep>? _tutorialSteps;

  @override
  void initState() {
    super.initState();
    if (widget.producto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartTutorial());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<TutorialStep> _buildProductoTutorialSteps() {
    return buildProductoPublicacionTutorialSteps(
      infoKey: _tutorialInfo,
      fotoKey: _tutorialFoto,
      nombreKey: _tutorialNombre,
      descripcionKey: _tutorialDescripcion,
      precioKey: _tutorialPrecio,
      unidadKey: _tutorialUnidad,
      guardarKey: _tutorialGuardar,
      ayudaKey: _tutorialAyuda,
    );
  }

  void _tryStartTutorial() {
    if (!mounted || widget.producto != null) return;
    final pending = TutorialRunner.filterPendingSteps(
      flowId: kTutorialProductoFormFlowId,
      steps: _buildProductoTutorialSteps(),
    );
    if (pending.isEmpty) return;
    setState(() => _tutorialSteps = pending);
  }

  Future<void> _replayTutorial() async {
    if (widget.producto != null) return;
    await TutorialService.instance.resetFlow(
      stepIdPrefix: kTutorialProductoFormFlowId,
    );
    if (!mounted) return;
    setState(() => _tutorialSteps = _buildProductoTutorialSteps());
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.producto != null;
    final titulo = isEdit ? 'Editar producto' : 'Añadir producto';
    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 124),
              child: _ProductoFormBody(
                producto: widget.producto,
                onSaved: () => context.pop(),
                scrollController: _scrollController,
                tutorialInfoKey: _tutorialInfo,
                tutorialFotoKey: _tutorialFoto,
                tutorialNombreKey: _tutorialNombre,
                tutorialDescripcionKey: _tutorialDescripcion,
                tutorialPrecioKey: _tutorialPrecio,
                tutorialUnidadKey: _tutorialUnidad,
                tutorialGuardarKey: _tutorialGuardar,
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
                  if (!isEdit)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: KeyedSubtree(
                        key: _tutorialAyuda,
                        child: IconTheme(
                          data: const IconThemeData(color: Colors.white),
                          child: TutorialHelpButton(
                            phrases: productoFormHelpPhrases,
                            tooltip: 'Ayuda',
                            onReplayWalkthrough: () =>
                                unawaited(_replayTutorial()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_tutorialSteps != null)
            TutorialWalkthroughLayer(
              anchorContext: context,
              flowId: kTutorialProductoFormFlowId,
              steps: _tutorialSteps!,
              scrollController: _scrollController,
              onClose: () {
                if (mounted) setState(() => _tutorialSteps = null);
              },
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
    required this.scrollController,
    required this.tutorialInfoKey,
    required this.tutorialFotoKey,
    required this.tutorialNombreKey,
    required this.tutorialDescripcionKey,
    required this.tutorialPrecioKey,
    required this.tutorialUnidadKey,
    required this.tutorialGuardarKey,
  });

  final Producto? producto;
  final VoidCallback onSaved;
  final ScrollController scrollController;
  final GlobalKey tutorialInfoKey;
  final GlobalKey tutorialFotoKey;
  final GlobalKey tutorialNombreKey;
  final GlobalKey tutorialDescripcionKey;
  final GlobalKey tutorialPrecioKey;
  final GlobalKey tutorialUnidadKey;
  final GlobalKey tutorialGuardarKey;

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
  static const _bucketProductos = 'productos';

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
    if (_saving) return;
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
          try {
            imagenUrl = await _subirImagenProducto(
              userId: user.id,
              productoId: widget.producto!.id,
              imagen: _imagenSeleccionada!,
              imagenAnteriorUrl: widget.producto?.imagenUrl,
            );
          } catch (e) {
            throw Exception('Fallo al subir imagen en edición: $e');
          }
        }
        try {
          await _actualizarProductoConCompatImagen(
            repo: repo,
            productoId: widget.producto!.id,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: precio,
            unidad: _unidad,
            lat: lat,
            lng: lng,
            imagenUrl: imagenUrl,
          );
        } catch (e) {
          throw Exception('Fallo al actualizar producto editado: $e');
        }
      } else {
        String productoId = '';
        try {
          productoId = await repo.crearProducto(
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
        } catch (e) {
          throw Exception('Fallo al crear producto: $e');
        }
        if (_imagenSeleccionada != null) {
          try {
            final nuevaUrl = await _subirImagenProducto(
              userId: user.id,
              productoId: productoId,
              imagen: _imagenSeleccionada!,
              imagenAnteriorUrl: null,
            );
            try {
              await _actualizarProductoConCompatImagen(
                repo: repo,
                productoId: productoId,
                nombre: _nombreController.text.trim(),
                descripcion: _descripcionController.text.trim().isEmpty
                    ? null
                    : _descripcionController.text.trim(),
                precio: precio,
                unidad: _unidad,
                lat: lat,
                lng: lng,
                imagenUrl: nuevaUrl,
              );
            } catch (e) {
              throw Exception('Fallo al guardar URL de imagen en producto nuevo: $e');
            }
          } catch (_) {
            // Evita dejar productos "huérfanos" cuando falla solo el upload.
            try {
              await repo.eliminarProducto(productoId);
            } catch (_) {}
            rethrow;
          }
        }
      }
      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado')),
        );
      }
    } catch (e, st) {
      debugPrint('Error guardando producto: $e');
      debugPrintStack(stackTrace: st);
      final msg = _mensajeErrorAmigable(e);
      if (mounted) {
        final detalleDebug = kDebugMode ? ' ($e)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$msg$detalleDebug')),
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

  Future<void> _actualizarProductoConCompatImagen({
    required ProductosRepository repo,
    required String productoId,
    required String nombre,
    required String? descripcion,
    required double precio,
    required String unidad,
    required double lat,
    required double lng,
    required String? imagenUrl,
  }) async {
    final base = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'unidad': unidad,
      'lat': lat,
      'lng': lng,
    };
    try {
      await repo.actualizarProducto(
        productoId,
        {
          ...base,
          'imagen_url': imagenUrl,
        },
      );
    } catch (e) {
      final raw = e.toString().toLowerCase();
      if (!raw.contains("could not find the 'imagen_url'")) rethrow;
      await repo.actualizarProducto(
        productoId,
        {
          ...base,
          'imagen': imagenUrl,
        },
      );
    }
  }

  Future<String> _subirImagenProducto({
    required String userId,
    required String productoId,
    required XFile imagen,
    String? imagenAnteriorUrl,
  }) async {
    final bytes = await imagen.readAsBytes();
    final ext = _extensionSegura(imagen.name);
    final path =
        '$userId/${productoId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = Supabase.instance.client.storage.from(_bucketProductos);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: false,
        contentType: _contentTypePorExtension(ext),
      ),
    );
    if (imagenAnteriorUrl != null && imagenAnteriorUrl.isNotEmpty) {
      final oldPath = _storagePathDesdePublicUrl(imagenAnteriorUrl);
      if (oldPath != null && oldPath != path) {
        try {
          await storage.remove([oldPath]);
        } catch (_) {
          // Si falla el borrado no bloquea el guardado del producto.
        }
      }
    }
    return storage.getPublicUrl(path);
  }

  String _extensionSegura(String fileName) {
    final name = fileName.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1);
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return ext == 'jpeg' ? 'jpg' : ext;
      default:
        return 'jpg';
    }
  }

  String _contentTypePorExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String? _storagePathDesdePublicUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final idx = uri.pathSegments.indexOf(_bucketProductos);
    if (idx < 0 || idx == uri.pathSegments.length - 1) return null;
    return uri.pathSegments.sublist(idx + 1).join('/');
  }

  String _mensajeErrorAmigable(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('storage') ||
        raw.contains('bucket') ||
        raw.contains('object') ||
        raw.contains('objects') ||
        raw.contains('permission') ||
        raw.contains('unauthorized') ||
        raw.contains('forbidden') ||
        raw.contains('row-level') ||
        raw.contains('rls') ||
        raw.contains('403') ||
        raw.contains('401')) {
      return 'No se pudo subir la imagen del producto. Intenta de nuevo en unos segundos.';
    }
    return 'No se pudo guardar el producto. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final imagenActual = widget.producto?.imagenUrl;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: widget.tutorialInfoKey,
              child: Container(
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
            ),
            const SizedBox(height: 24),
            KeyedSubtree(
              key: widget.tutorialFotoKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: widget.tutorialNombreKey,
              child: TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.shopping_basket),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: widget.tutorialDescripcionKey,
              child: TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción corta',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: widget.tutorialPrecioKey,
              child: TextFormField(
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
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: widget.tutorialUnidadKey,
              child: DropdownButtonFormField<String>(
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
            ),
            const SizedBox(height: 32),
            KeyedSubtree(
              key: widget.tutorialGuardarKey,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
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
