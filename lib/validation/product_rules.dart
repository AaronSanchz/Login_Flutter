// GUÍA DEL ARCHIVO: Validación local compartida por formularios y repositorio. Comprueba texto obligatorio, precio positivo con máximo dos decimales, URL HTTPS y categoría disponible. No abre conexiones.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import '../models/product.dart';

/// Reglas compartidas por formulario y repositorio; no dependen de widgets.
abstract final class ProductRules {
  /// Devuelve null si el texto es válido; devuelve mensaje si falta o supera el máximo recibido.
  static String? requiredText(String? value, {int max = 200}) =>
      value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : value.trim().length > max
      ? 'Máximo $max caracteres.'
      : null;

  /// Normaliza coma a punto e intenta convertir a número; no reemplaza la validación completa de price.
  static double? parsePrice(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  /// Valida formato numérico local, positividad, límite de un millón y hasta dos decimales; devuelve mensaje o null.
  static String? price(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text)) {
      return 'Usa un precio positivo con hasta 2 decimales.';
    }
    final number = parsePrice(text);
    return number == null || !number.isFinite || number <= 0 || number > 1000000
        ? 'El precio debe ser mayor que 0 y hasta 1000000.'
        : null;
  }

  /// Exige URL HTTPS con host y sin credenciales incrustadas; valida formato, no descarga la imagen.
  static String? image(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri == null ||
            uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty ||
            (value?.contains(RegExp(r'\s')) ?? true)
        ? 'Introduce una URL HTTPS válida.'
        : null;
  }

  /// Valida producto para edición con ID positivo, texto, precio, imagen y categoría; falla antes de HTTP.
  static void validate(Product p, List<String> categories) {
    if (p.id <= 0 ||
        /// Devuelve null si el texto es válido; devuelve mensaje si falta o supera el máximo recibido.
        requiredText(p.title) != null ||
        /// Devuelve null si el texto es válido; devuelve mensaje si falta o supera el máximo recibido.
        requiredText(p.description, max: 5000) != null ||
        !p.price.isFinite ||
        p.price <= 0 ||
        p.price > 1000000 ||
        /// Valida formato numérico local, positividad, límite de un millón y hasta dos decimales; devuelve mensaje o null.
        price(p.price.toString()) != null ||
        /// Exige URL HTTPS con host y sin credenciales incrustadas; valida formato, no descarga la imagen.
        image(p.image) != null ||
        !categories.contains(p.category)) {
      throw const FormatException('Revisa los campos del producto.');
    }
  }

  /// US06 usa las mismas reglas de edición, excepto que aún no existe un ID.
  /// Reutiliza reglas de edición con ID auxiliar solo para validar; el servidor asigna el ID de creación.
  static void validateNew(Product p, List<String> categories) {
    /// Valida producto para edición con ID positivo, texto, precio, imagen y categoría; falla antes de HTTP.
    validate(
      Product(
        id: 1,
        title: p.title,
        description: p.description,
        category: p.category,
        image: p.image,
        price: p.price,
      ),
      categories,
    );
  }
}
