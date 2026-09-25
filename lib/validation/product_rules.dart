import '../models/product.dart';

/// Reglas compartidas por formulario y repositorio; no dependen de widgets.
abstract final class ProductRules {
  static String? requiredText(String? value, {int max = 200}) =>
      value == null || value.trim().isEmpty
          ? 'Este campo es obligatorio.'
          : value.trim().length > max
              ? 'Máximo $max caracteres.'
              : null;
  static double? parsePrice(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
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

  static void validate(Product p, List<String> categories) {
    if (p.id <= 0 ||
        requiredText(p.title) != null ||
        requiredText(p.description, max: 5000) != null ||
        !p.price.isFinite ||
        p.price <= 0 ||
        p.price > 1000000 ||
        image(p.image) != null ||
        !categories.contains(p.category)) {
      throw const FormatException('Revisa los campos del producto.');
    }
  }
}
