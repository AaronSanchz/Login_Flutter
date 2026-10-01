// GUÍA DEL ARCHIVO: Tipos de sesión. UserRole contiene los tres perfiles; UserRoleText proporciona etiquetas y valores persistidos. SessionData agrupa token, ID, nombre y rol; no almacena la contraseña.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

/// Modelo inmutable de sesión y roles de acceso.
enum UserRole { administrador, auditor, cliente }

extension UserRoleText on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.auditor:
        return 'Auditor';
      case UserRole.cliente:
        return 'Cliente';
    }
  }

  String get storageValue => name;
}

/// Agrupa token, usuario y rol de la sesión autenticada.
class SessionData {
  final String token;
  final int userId;
  final String username;
  final UserRole role;

  const SessionData({
    required this.token,
    required this.userId,
    required this.username,
    required this.role,
  });
}
