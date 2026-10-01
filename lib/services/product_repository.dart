// GUÍA DEL ARCHIVO: Contrato ProductRepository e implementación HTTP. GET consulta; POST crea; PUT edita; DELETE elimina. Cada escritura vuelve a leer el rol persistido y valida antes de abrir la conexión. Fake Store simula escrituras.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

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
  /// Obtiene lista general o categoría recibida; valida y convierte cada JSON en Product. Una categoría vacía o respuesta incoherente es error.
  Future<List<Product>> products([String? category]);

  /// Solicita /products/categories y devuelve nombres no vacíos y sin duplicados; no depende de la lista de productos.
  Future<List<String>> categories();

  /// Consulta /products/{id}; rechaza ID no positivo y confirma que la respuesta corresponde al artículo solicitado.
  Future<Product> detail(int id);

  /// Revalida Administrador y campos; envía POST /products sin ID. Devuelve el producto con ID del servidor; Fake Store no lo persiste.
  Future<Product> create(Product product, List<String> categories);

  /// Revalida Administrador, campos y categoría; envía PUT /products/{id} y devuelve la confirmación del mismo ID.
  Future<Product> update(Product product, List<String> categories);

  /// Revalida Administrador e ID; envía DELETE /products/{id} y exige un ID coincidente. La confirmación visual pertenece a la pantalla llamadora.
  Future<void> delete(int id);

  /// Libera el cliente HTTP del repositorio cuando la pantalla propietaria se destruye.
  void close();
}

/// Consulta y modifica productos mediante el contrato del repositorio.
class HttpProductRepository implements ProductRepository {
  final http.Client _client;
  final Future<SessionData?> Function() _session;
  HttpProductRepository({
    http.Client? client,
    Future<SessionData?> Function()? session,
  }) : _client = client ?? http.Client(),
       _session = session ?? SessionService.loadSession;

  /// Construye URL HTTPS y JSON opcional; acepta HTTP 2xx, aplica timeout y convierte fallos de transporte o JSON a StoreException.
  Future<Object?> _request(
    String method,
    List<String> path, [
    Object? body,
  ]) async {
    try {
      final request = http.Request(
        method,
        Uri(scheme: 'https', host: 'fakestoreapi.com', pathSegments: path),
      );
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
        'Sin conexión. Revisa tu Internet y reintenta.',
      );
    } on http.ClientException {
      throw const StoreException('No se pudo conectar. Reintenta.');
    } on FormatException {
      throw const StoreException('La API devolvió datos inválidos.');
    }
  }

  T _parse<T>(T Function() action) {
    try {
      /// Crea botón accesible y conecta su pulsación con el callback onClick recibido; no decide permiso ni HTTP.
      return action();
    } on FormatException {
      throw const StoreException(
        'La API devolvió datos incompletos o inválidos.',
      );
    }
  }

  @override
  /// Obtiene lista general o categoría recibida; valida y convierte cada JSON en Product. Una categoría vacía o respuesta incoherente es error.
  Future<List<Product>> products([String? category]) async {
    if (category != null && category.trim().isEmpty) {
      throw const StoreException('Selecciona una categoría válida.');
    }
    final data = await _request(
      'GET',
      category == null ? ['products'] : ['products', 'category', category],
    );

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
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
  /// Solicita /products/categories y devuelve nombres no vacíos y sin duplicados; no depende de la lista de productos.
  Future<List<String>> categories() async {
    final data = await _request('GET', ['products', 'categories']);

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    return _parse(() {
      if (data is! List || data.any((x) => x is! String || x.trim().isEmpty)) {
        throw const FormatException();
      }
      return List.unmodifiable(
        data.cast<String>().map((x) => x.trim()).toSet(),
      );
    });
  }

  @override
  /// Consulta /products/{id}; rechaza ID no positivo y confirma que la respuesta corresponde al artículo solicitado.
  Future<Product> detail(int id) async {
    if (id <= 0) throw const StoreException('Producto no disponible');
    final data = await _request('GET', ['products', '$id']);

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    return _parse(() {
      final p = Product.fromJson(data);
      if (p.id != id) throw const FormatException();
      return p;
    });
  }

  /// Lee nuevamente la sesión actual; si no es Administrador lanza error antes de cualquier escritura HTTP.
  Future<void> _requireAdmin() async {
    if ((await _session())?.role != UserRole.administrador) {
      throw const StoreException('No tienes permiso para esta acción.');
    }
  }

  /// US06: valida localmente y comprueba el ID devuelto por POST.
  @override
  /// Revalida Administrador y campos; envía POST /products sin ID. Devuelve el producto con ID del servidor; Fake Store no lo persiste.
  Future<Product> create(Product p, List<String> categories) async {
    /// Lee nuevamente la sesión actual; si no es Administrador lanza error antes de cualquier escritura HTTP.
    await _requireAdmin();

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    _parse(() => ProductRules.validateNew(p, categories));
    final body = Map<String, dynamic>.from(p.toJson())..remove('id');
    final raw = await _request('POST', ['products'], body);

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    return _parse(() => Product.fromJson(raw));
  }

  @override
  /// Revalida Administrador, campos y categoría; envía PUT /products/{id} y devuelve la confirmación del mismo ID.
  Future<Product> update(Product p, List<String> categories) async {
    /// Lee nuevamente la sesión actual; si no es Administrador lanza error antes de cualquier escritura HTTP.
    await _requireAdmin();

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    _parse(() => ProductRules.validate(p, categories));
    final raw = await _request('PUT', ['products', '${p.id}'], p.toJson());

    /// Ejecuta el parser recibido y traduce el fallo de formato a un error comprensible para la pantalla.
    return _parse(() {
      final saved = Product.fromJson(raw);
      if (saved.id != p.id) throw const FormatException();
      return saved;
    });
  }

  @override
  /// Revalida Administrador e ID; envía DELETE /products/{id} y exige un ID coincidente. La confirmación visual pertenece a la pantalla llamadora.
  Future<void> delete(int id) async {
    /// Lee nuevamente la sesión actual; si no es Administrador lanza error antes de cualquier escritura HTTP.
    await _requireAdmin();
    if (id <= 0) throw const StoreException('Producto no disponible');
    final data = await _request('DELETE', ['products', '$id']);
    if (data is! Map || data['id'] != id) {
      throw const StoreException('La eliminación no fue confirmada.');
    }
  }

  @override
  /// Libera el cliente HTTP del repositorio cuando la pantalla propietaria se destruye.
  void close() => _client.close();
}
