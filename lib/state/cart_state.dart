// GUÍA DEL ARCHIVO: Carrito global temporal: conserva solamente IDs de productos y admite repetidos. count cuenta elementos; add ignora IDs no positivos; clear borra toda la lista. No persiste ni envía compras al servidor.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

/// Estado temporal del carrito.
class CartState {
  CartState._();

  static final List<int> _productIds = [];

  static int get count => _productIds.length;

  /// Añade un ID positivo al carrito temporal; los repetidos cuentan como elementos separados.
  static void add(int productId) {
    if (productId > 0) _productIds.add(productId);
  }

  /// Vacía todos los elementos del carrito global; se llama al finalizar una sesión.
  static void clear() {
    _productIds.clear();
  }
}
