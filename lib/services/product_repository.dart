import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/session_data.dart';
import 'session_service.dart';
import 'http_error_mapper.dart';

/// Contrato de productos e implementación HTTP con control de permisos.
class StoreException implements Exception {
  final String message;
  const StoreException(this.message);
  @override
  String toString() => message;
}

/// Contrato sustituible por un doble de prueba sin acceder a Internet.
abstract class ProductRepository {
  Future<List<Product>> products([String? category]);
  Future<List<String>> categories();
  Future<Product> detail(int id);
  Future<Product> update(Product product, List<String> categories);
  Future<void> delete(int id);
  void close();
}

/// Consulta y modifica productos mediante el contrato del repositorio.
class HttpProductRepository implements ProductRepository {
  final http.Client _client;
  final Future<SessionData?> Function() _session;
  HttpProductRepository(
      {http.Client? client, Future<SessionData?> Function()? session})
      : _client = client ?? http.Client(),
        _session = session ?? SessionService.loadSession;

  Future<Object?> _request(String method, List<String> path,
      [Object? body]) async {
    try {
      final request = http.Request(method,
          Uri(scheme: 'https', host: 'fakestoreapi.com', pathSegments: path));
      request.headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StoreException(HttpErrorMapper.message(response.statusCode));
      }
      if (response.body.trim().isEmpty) {
        throw const StoreException('La API devolvió una respuesta vacía.');
      }
      return jsonDecode(response.body);
    } on StoreException {
      rethrow;
    } on TimeoutException {
      throw const StoreException('La conexión tardó demasiado. Reintenta.');
    } on SocketException {
      throw const StoreException(
          'Sin conexión. Revisa tu Internet y reintenta.');
    } on http.ClientException {
      throw const StoreException('No se pudo conectar. Reintenta.');
    } on FormatException {
      throw const StoreException('La API devolvió datos inválidos.');
    }
  }

  T _parse<T>(T Function() action) {
    try {
      return action();
    } on FormatException {
      throw const StoreException(
          'La API devolvió datos incompletos o inválidos.');
    }
  }

  @override
  Future<List<Product>> products([String? category]) async {
    if (category != null && category.trim().isEmpty) {
      throw const StoreException('Selecciona una categoría válida.');
    }
    final data = await _request('GET',
        category == null ? ['products'] : ['products', 'category', category]);
    return _parse(() {
      if (data is! List) throw const FormatException();
      final products = data.map(Product.fromJson).toList();
      if (category != null && products.any((p) => p.category != category)) {
        throw const FormatException();
      }
      return List.unmodifiable(products);
    });
  }

  @override
  Future<List<String>> categories() async {
    final data = await _request('GET', ['products', 'categories']);
    return _parse(() {
      if (data is! List || data.any((x) => x is! String || x.trim().isEmpty)) {
        throw const FormatException();
      }
      return List.unmodifiable(
          data.cast<String>().map((x) => x.trim()).toSet());
    });
  }

  @override
  Future<Product> detail(int id) async {
    if (id <= 0) throw const StoreException('Producto no disponible');
    final data = await _request('GET', ['products', '$id']);
    return _parse(() {
      final p = Product.fromJson(data);
      if (p.id != id) throw const FormatException();
      return p;
    });
  }

  Future<void> _requireAdmin() async {
    if ((await _session())?.role != UserRole.administrador) {
      throw const StoreException('No tienes permiso para esta acción.');
    }
  }

  @override
  Future<Product> update(Product p, List<String> categories) async {
    await _requireAdmin();
    _parse(() => ProductRules.validate(p, categories));
    final raw = await _request('PUT', ['products', '${p.id}'], p.toJson());
    return _parse(() {
      final saved = Product.fromJson(raw);
      if (saved.id != p.id) throw const FormatException();
      return saved;
    });
  }

  @override
  Future<void> delete(int id) async {
    await _requireAdmin();
    if (id <= 0) throw const StoreException('Producto no disponible');
    final data = await _request('DELETE', ['products', '$id']);
    if (data is! Map || data['id'] != id) {
      throw const StoreException('La eliminación no fue confirmada.');
    }
  }

  @override
  void close() => _client.close();
}
