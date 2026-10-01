// GUÍA DEL ARCHIVO: Entrada de Flutter. main inicializa los servicios y ejecuta FakeStoreApp; SessionGate lee la sesión segura y elige LoginScreen o CatalogScreen. No realiza autenticación por sí mismo.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import 'screens/catalog_screen.dart';

import 'models/session_data.dart';

import 'screens/login_screen.dart';
import 'services/session_service.dart';

/// Punto de entrada, tema y pantalla inicial.
/// Inicializa los servicios del framework y monta la aplicación raíz; el sistema invoca esta entrada.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FakeStoreApp());
}

/// Configura el tema y la puerta de entrada de la aplicación.
class FakeStoreApp extends StatelessWidget {
  const FakeStoreApp({super.key});

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fake Store Roles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff12685e)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SessionGate(),
    );
  }
}

/// Decide la pantalla inicial a partir de la sesión guardada.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  /// Devuelve el catálogo correspondiente a una sesión ya recuperada; no realiza llamadas HTTP.
  Widget _screenFor(SessionData session) {
    return CatalogScreen(session: session);
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
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

        /// Devuelve el catálogo correspondiente a una sesión ya recuperada; no realiza llamadas HTTP.
        return _screenFor(session);
      },
    );
  }
}
