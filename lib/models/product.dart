import '../validation/product_rules.dart';
export '../validation/product_rules.dart';

/// Modelo de producto y calificación; valida el JSON recibido.
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

/// Representa la puntuación opcional de un producto.
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
