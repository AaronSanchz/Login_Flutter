enum UserRole {
  administrador,
  auditor,
  cliente,
}

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
