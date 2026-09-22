import 'package:flutter/material.dart';
import 'catalog_screen.dart';

import '../models/session_data.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();

  bool _loading = false;
  String _message = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _destination(SessionData session) {
    return CatalogScreen(session: session);
  }

  Future<void> _login() async {
    if (_loading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.trim().isEmpty) {
      setState(() => _message = 'Completa el usuario y la contraseña.');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final session = await _api.authenticate(username, password);
      await SessionService.saveSession(session);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => _destination(session)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Ocurrió un error al iniciar sesión.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.storefront, size: 72),
                      const SizedBox(height: 12),
                      Text(
                        'Fake Store API',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explora el catálogo con tu cuenta',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onSubmitted: (_) {
                          if (!_loading) _login();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                      if (_message.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Usuarios de prueba',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(r'Administrador (ID 2): mor_2314 / 83r5^_'),
                      const Text(r'Auditor (ID 3): kevinryan / kev02937@'),
                      const Text(r'Cliente (ID 4): donero / ewedon'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
