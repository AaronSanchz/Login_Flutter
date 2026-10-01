// GUÍA DEL ARCHIVO: Coordina validación, autenticación y guardado seguro. ChangeNotifier informa loading y message a LoginScreen; dependencias inyectables permiten probar sin Internet. Una pantalla destruida no debe iniciar un guardado tardío.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/foundation.dart';

import '../models/session_data.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

/// Controlador de acceso: valida, bloquea envíos repetidos, autentica y guarda sesión.
class LoginController extends ChangeNotifier {
  LoginController({
    Future<SessionData> Function(String, String)? authenticate,
    Future<void> Function(SessionData)? saveSession,
  }) : _authenticate = authenticate ?? ApiService().authenticate,
       _saveSession = saveSession ?? SessionService.saveSession;

  final Future<SessionData> Function(String, String) _authenticate;
  final Future<void> Function(SessionData) _saveSession;
  bool loading = false;
  String message = '';
  bool _disposed = false;

  /// Devuelve la sesión solo si las credenciales son válidas y quedó guardada.
  /// Valida textos y evita segundo envío; autentica, guarda sesión y retorna resultado o null con mensaje. loading se restablece en finally.
  Future<SessionData?> submit(String username, String password) async {
    if (loading) return null;
    final user = username.trim();
    if (user.isEmpty || password.trim().isEmpty) {
      message = 'Completa el usuario y la contraseña.';
      notifyListeners();
      return null;
    }
    if (user.length > 100 || password.length > 256) {
      message = 'Revisa el usuario y la contraseña.';
      notifyListeners();
      return null;
    }
    loading = true;
    message = '';
    notifyListeners();
    try {
      final session = await _authenticate(user, password);
      // Si se cerró la pantalla durante la petición, no persistir un acceso tardío.
      if (_disposed) return null;
      await _saveSession(session);
      if (_disposed) return null;
      return session;
    } on ApiException catch (e) {
      message = e.message;
      return null;
    } catch (_) {
      message = 'Ocurrió un error al iniciar sesión.';
      return null;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  /// Libera recursos de esta instancia e invalida sus notificaciones; no debe usarse para iniciar peticiones.
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
