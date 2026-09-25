import 'package:flutter/material.dart';

/// Imagen de producto con sustituto si la URL falla.
/// Descarga asíncrona con estados de espera y URL rota, sin bloquear la lista.
class ProductImage extends StatelessWidget {
  final String url, label;
  final double height;
  const ProductImage(
      {super.key, required this.url, required this.label, this.height = 120});
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 42, semanticLabel: 'Imagen no disponible'));
    return SizedBox(
        height: height,
        width: height,
        child: url.isEmpty
            ? fallback
            : Image.network(url,
                fit: BoxFit.contain,
                semanticLabel: label,
                cacheWidth: 800,
                errorBuilder: (_, error, stack) => fallback,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))));
  }
}
