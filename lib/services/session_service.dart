import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/session_data.dart';

/// Persistencia segura de la sesión local.
class SessionService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'session_token';
  static const String _userIdKey = 'session_user_id';
  static const String _usernameKey = 'session_username';
  static const String _roleKey = 'session_role';

  static Future<void> saveSession(SessionData session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.userId.toString());
    await _storage.write(key: _usernameKey, value: session.username);
    await _storage.write(key: _roleKey, value: session.role.storageValue);
  }

  static Future<SessionData?> loadSession() async {
    final token = await _storage.read(key: _tokenKey);
    final idText = await _storage.read(key: _userIdKey);
    final username = await _storage.read(key: _usernameKey);
    final roleText = await _storage.read(key: _roleKey);

    if (token == null ||
        token.trim().isEmpty ||
        idText == null ||
        username == null ||
        username.trim().isEmpty ||
        roleText == null) {
      return null;
    }

    final userId = int.tryParse(idText);
    UserRole? role;

    for (final value in UserRole.values) {
      if (value.storageValue == roleText) {
        role = value;
        break;
      }
    }

    if (userId == null || userId <= 0 || role == null) {
      await clearSession();
      return null;
    }

    return SessionData(
      token: token,
      userId: userId,
      username: username,
      role: role,
    );
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _roleKey);
  }
}
