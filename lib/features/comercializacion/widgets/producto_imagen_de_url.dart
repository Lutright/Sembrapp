import 'package:flutter/material.dart';

/// Miniatura o portada desde URL de Storage (pública).
class ProductoImagenDeUrl extends StatelessWidget {
  const ProductoImagenDeUrl({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFFE8F5E9),
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color placeholderColor;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(8);
    final u = url?.trim();
    if (u == null || u.isEmpty) {
      return _placeholder(br);
    }
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          u,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(br),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: placeholderColor,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder(BorderRadius br) {
    return ClipRRect(
      borderRadius: br,
      child: Container(
        width: width,
        height: height,
        color: placeholderColor,
        alignment: Alignment.center,
        child: Icon(
          placeholderIcon,
          color: Colors.green.shade300,
          size: width > 60 ? 36 : 28,
        ),
      ),
    );
  }
}
