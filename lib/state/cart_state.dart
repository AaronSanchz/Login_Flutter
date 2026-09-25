/// Estado temporal del carrito.
class CartState {
  CartState._();

  static final List<int> _productIds = [];

  static int get count => _productIds.length;

  static void add(int productId) {
    if (productId > 0) _productIds.add(productId);
  }

  static void clear() {
    _productIds.clear();
  }
}
