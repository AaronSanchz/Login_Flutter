import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';

import 'models/session_data.dart';

import 'screens/login_screen.dart';
import 'services/session_service.dart';

/// Punto de entrada, tema y pantalla inicial.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FakeStoreApp());
}

/// Configura el tema y la puerta de entrada de la aplicación.
class FakeStoreApp extends StatelessWidget {
  const FakeStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fake Store Roles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff12685e)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const SessionGate(),
    );
  }
}

/// Decide la pantalla inicial a partir de la sesión guardada.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  Widget _screenFor(SessionData session) {
    return CatalogScreen(session: session);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionData?>(
      future: SessionService.loadSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;
        if (session == null) {
          return const LoginScreen();
        }

        return _screenFor(session);
      },
    );
  }
}
