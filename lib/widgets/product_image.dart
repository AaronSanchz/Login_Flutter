// GUÍA DEL ARCHIVO: Widget reutilizable de imagen. Image.network descarga sin bloquear la lista; loadingBuilder muestra progreso y errorBuilder un icono sustituto. label se utiliza en accesibilidad y height determina el tamaño.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

/// Imagen de producto con sustituto si la URL falla.
/// Descarga asíncrona con estados de espera y URL rota, sin bloquear la lista.
class ProductImage extends StatelessWidget {
  final String url, label;
  final double height;
  const ProductImage({
    super.key,
    required this.url,
    required this.label,
    this.height = 120,
  });
  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 42,
        semanticLabel: 'Imagen no disponible',
      ),
    );
    return SizedBox(
      height: height,
      width: height,
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.contain,
              semanticLabel: label,
              cacheWidth: 800,
              errorBuilder: (_, error, stack) => fallback,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
    );
  }
}
