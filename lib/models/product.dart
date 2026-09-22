/// Modelo inmutable: valida la frontera JSON antes de entregar datos a la UI.
class Product {
  final int id;
  final String title, description, category, image;
  final double price;
  final Rating? rating;
  const Product(
      {required this.id,
      required this.title,
      required this.description,
      required this.category,
      required this.image,
      required this.price,
      this.rating});

  factory Product.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Producto inválido');
    }
    String text(String key) {
      final value = raw[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Falta $key');
      }
      return value.trim();
    }

    final id = raw['id'];
    final price = raw['price'];
    if (id is! int ||
        id <= 0 ||
        price is! num ||
        !price.isFinite ||
        price < 0) {
      throw const FormatException('ID o precio inválido');
    }
    // Una imagen ausente no impide consultar un producto; la UI usa un sustituto.
    final image = raw['image'];
    return Product(
        id: id,
        title: text('title'),
        description: text('description'),
        category: text('category'),
        price: price.toDouble(),
        image: image is String && ProductRules.image(image) == null
            ? image.trim()
            : '',
        rating: Rating.tryParse(raw['rating']));
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'image': image
      };
}

class Rating {
  final double rate;
  final int count;
  const Rating(this.rate, this.count);
  static Rating? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final rate = raw['rate'];
    final count = raw['count'];
    if (rate is! num ||
        !rate.isFinite ||
        rate < 0 ||
        rate > 5 ||
        count is! int ||
        count < 0) {
      return null;
    }
    return Rating(rate.toDouble(), count);
  }
}

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
