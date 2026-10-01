// GUÍA DEL ARCHIVO: Panel heredado de usuarios: obtiene GET /users solamente tras verificar Administrador en almacenamiento local. FutureBuilder dibuja carga, error o lista; _reload reintenta y _logout borra sesión y carrito.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/session_data.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../state/cart_state.dart';
import 'login_screen.dart';

/// Panel de administración y sus controles.
class AdminScreen extends StatefulWidget {
  final SessionData session;

  const AdminScreen({super.key, required this.session});

  @override
  /// Crea el objeto State asociado al widget para conservar campos, carga y errores entre reconstrucciones.
  State<AdminScreen> createState() => _AdminScreenState();
}

/// Mantiene el estado visual del panel de administración.
class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _usersFuture;
  bool _authorized = false;

  @override
  /// Inicializa el estado una vez al insertar la pantalla; inicia la carga correspondiente y llama al ciclo de vida heredado.
  void initState() {
    super.initState();
    _usersFuture = _loadAuthorizedUsers();
  }

  /// Lee el permiso persistido antes de descargar usuarios; falla con acceso denegado.
  /// Comprueba el rol persistido antes de GET /users; sin Administrador lanza error y no descarga usuarios.
  Future<List<Map<String, dynamic>>> _loadAuthorizedUsers() async {
    final session = await SessionService.loadSession();
    if (session?.role != UserRole.administrador) {
      throw ApiException('Acceso denegado: se requiere Administrador.');
    }
    if (mounted) setState(() => _authorized = true);
    return _api.getUsers();
  }

  /// Crea una nueva consulta de usuarios autorizada y reconstruye el estado de carga del panel.
  void _reload() {
    setState(() => _usersFuture = _loadAuthorizedUsers());
  }

  /// Borra token, ID, nombre y rol del almacenamiento, reinicia carrito y elimina historial al abrir Login. Un fallo de borrado impide anunciar éxito.
  Future<void> _logout() async {
    await SessionService.clearSession();
    CartState.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administrador'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_authorized) Text('Sesión: ${widget.session.username}'),
            if (_authorized) Text('ID: ${widget.session.userId}'),
            if (_authorized)
              const Text(
                'Rol: Administrador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            Text('Usuarios', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(snapshot.error.toString()),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No hay usuarios para mostrar.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final name = user['name'] is Map
                          ? Map<String, dynamic>.from(user['name'])
                          : <String, dynamic>{};
                      final fullName =
                          '${name['firstname'] ?? ''} ${name['lastname'] ?? ''}'
                              .trim();
                      final rawId = user['id'];
                      final id = rawId is int
                          ? rawId
                          : int.tryParse(rawId?.toString() ?? '') ?? 0;
                      final role = _api.roleFromId(id).label;

                      return ListTile(
                        leading: CircleAvatar(child: Text('$id')),
                        title: Text(fullName.isEmpty ? 'Usuario' : fullName),
                        subtitle: Text(
                          'Usuario: ${user['username'] ?? '-'}\n'
                          'Correo: ${user['email'] ?? '-'}\n'
                          'Rol local: $role',
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
