import 'package:flutter/material.dart';

import 'models/session_data.dart';
import 'screens/admin_screen.dart';
import 'screens/auditor_screen.dart';
import 'screens/client_screen.dart';
import 'screens/login_screen.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FakeStoreApp());
}

class FakeStoreApp extends StatelessWidget {
  const FakeStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fake Store Roles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  Widget _screenFor(SessionData session) {
    switch (session.role) {
      case UserRole.administrador:
        return AdminScreen(session: session);
      case UserRole.auditor:
        return AuditorScreen(session: session);
      case UserRole.cliente:
        return ClientScreen(session: session);
    }
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
