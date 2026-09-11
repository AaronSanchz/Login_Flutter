import 'package:flutter/material.dart';

import '../models/session_data.dart';
import '../services/session_service.dart';
import '../state/cart_state.dart';
import 'login_screen.dart';

class AuditorScreen extends StatelessWidget {
  final SessionData session;

  const AuditorScreen({super.key, required this.session});

  Future<void> _logout(BuildContext context) async {
    await SessionService.clearSession();
    CartState.clear();

    if (!context.mounted) return;

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
        title: const Text('Panel de auditor'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión de auditor',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('Usuario: ${session.username}'),
                Text('ID: ${session.userId}'),
                const Text(
                  'Rol: Auditor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta pantalla es independiente para cumplir con el perfil Auditor definido en la historia de usuario.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
