import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_repository.dart';

/// Una solicitud antigua no puede sobrescribir la última selección del usuario.
class CatalogController extends ChangeNotifier {
  final ProductRepository repository;
  CatalogController(this.repository);
  List<Product> _products = const [];
  List<String> _categories = const [];
  String? _selected, _error, _categoryError;
  bool _loading = false, _categoriesLoading = false, _disposed = false;
  int _generation = 0;
  List<Product> get products => List.unmodifiable(_products);
  List<String> get categories => List.unmodifiable(_categories);
  String? get selected => _selected;
  String? get error => _error;
  String? get categoryError => _categoryError;
  bool get loading => _loading;
  bool get categoriesLoading => _categoriesLoading;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadCategories() async {
    if (_categoriesLoading) return;
    _categoriesLoading = true;
    _categoryError = null;
    _emit();
    try {
      _categories = await repository.categories();
    } catch (e) {
      _categoryError = e.toString();
    } finally {
      _categoriesLoading = false;
      _emit();
    }
  }

  Future<void> load([String? category]) async {
    if (category != null && !_categories.contains(category)) return;
    final generation = ++_generation;
    _selected = category;
    _products = const [];
    _error = null;
    _loading = true;
    _emit();
    try {
      final result = await repository.products(category);
      if (!_disposed && generation == _generation) _products = result;
    } catch (e) {
      if (!_disposed && generation == _generation) _error = e.toString();
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        _emit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
