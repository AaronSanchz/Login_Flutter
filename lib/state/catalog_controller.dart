// GUÍA DEL ARCHIVO: Estado observable del catálogo. load limpia filas, solicita productos y acepta solo la generación más reciente. loadCategories tiene carga y error independientes. dispose invalida respuestas pendientes.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_repository.dart';

/// Estado, filtros y concurrencia del catálogo.
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

  /// Notifica al catálogo solo si el controlador no fue destruido, para evitar reconstrucciones después de dispose.
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// Consulta categorías con indicador y error independientes; evita solicitudes simultáneas duplicadas.
  Future<void> loadCategories() async {
    if (_categoriesLoading) return;
    _categoriesLoading = true;
    _categoryError = null;

    /// Notifica al catálogo solo si el controlador no fue destruido, para evitar reconstrucciones después de dispose.
    _emit();
    try {
      _categories = await repository.categories();
    } catch (e) {
      _categoryError = e.toString();
    } finally {
      _categoriesLoading = false;

      /// Notifica al catálogo solo si el controlador no fue destruido, para evitar reconstrucciones después de dispose.
      _emit();
    }
  }

  /// Recibe categoría opcional; limpia lista, marca carga y acepta solo la respuesta de la generación actual.
  Future<void> load([String? category]) async {
    if (category != null && !_categories.contains(category)) return;
    final generation = ++_generation;
    _selected = category;
    _products = const [];
    _error = null;
    _loading = true;

    /// Notifica al catálogo solo si el controlador no fue destruido, para evitar reconstrucciones después de dispose.
    _emit();
    try {
      final result = await repository.products(category);
      if (!_disposed && generation == _generation) _products = result;
    } catch (e) {
      if (!_disposed && generation == _generation) _error = e.toString();
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;

        /// Notifica al catálogo solo si el controlador no fue destruido, para evitar reconstrucciones después de dispose.
        _emit();
      }
    }
  }

  @override
  /// Libera recursos de esta instancia e invalida sus notificaciones; no debe usarse para iniciar peticiones.
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
