import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/session_data.dart';
import 'http_error_mapper.dart';

/// Autenticación, consulta de usuarios y errores de acceso.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Autentica credenciales, consulta usuarios y asigna roles.
class ApiService {
  static const String baseUrl = 'https://fakestoreapi.com';

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('fakestoreapi.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  UserRole roleFromId(int id) {
    if (id == 1 || id == 2) {
      return UserRole.administrador;
    }
    if (id == 3) {
      return UserRole.auditor;
    }
    return UserRole.cliente;
  }

  Future<SessionData> authenticate(String username, String password) async {
    if (username.trim().isEmpty ||
        password.trim().isEmpty ||
        username.length > 100 ||
        password.length > 256) {
      throw ApiException('Revisa el usuario y la contraseña.');
    }
    if (!await hasInternetConnection()) {
      throw ApiException('No hay conexión a Internet.');
    }

    final token = await _login(username, password);
    final users = await getUsers();

    Map<String, dynamic>? currentUser;
    for (final user in users) {
      if (user['username']?.toString().toLowerCase() ==
          username.toLowerCase()) {
        currentUser = user;
        break;
      }
    }

    if (currentUser == null) {
      throw ApiException('No se pudo obtener la información del usuario.');
    }

    final id = currentUser['id'];
    final userId = id is int ? id : int.tryParse(id.toString());
    if (userId == null || userId <= 0) {
      throw ApiException('El usuario no tiene un ID válido.');
    }

    return SessionData(
      token: token,
      userId: userId,
      username: currentUser['username']?.toString() ?? username,
      role: roleFromId(userId),
    );
  }

  Future<String> _login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final rawToken = data['token'];
          final token = rawToken is String ? rawToken.trim() : '';
          if (token.isNotEmpty) {
            return token;
          }
        }
        throw ApiException(
            'La API respondió, pero no devolvió un token válido.');
      }

      throw ApiException(HttpErrorMapper.message(response.statusCode, login: true));
    } on SocketException {
      throw ApiException('No hay conexión a Internet.');
    } on FormatException {
      throw ApiException('La respuesta de la API no tiene un formato válido.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('No se pudo conectar con Fake Store API.');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('No se pudieron cargar los usuarios.');
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        throw ApiException('La lista de usuarios no tiene un formato válido.');
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on SocketException {
      throw ApiException('No hay conexión a Internet.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Error al consultar los usuarios.');
    }
  }
}
