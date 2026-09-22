import 'package:flutter/material.dart';

import '../models/session_data.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../state/cart_state.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final SessionData session;

  const AdminScreen({super.key, required this.session});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _api.getUsers();
  }

  void _reload() {
    setState(() => _usersFuture = _api.getUsers());
  }

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
            Text('Sesión: ${widget.session.username}'),
            Text('ID: ${widget.session.userId}'),
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
                        child: Text('No hay usuarios para mostrar.'));
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
