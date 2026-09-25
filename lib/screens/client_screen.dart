import 'package:flutter/material.dart';
import '../models/session_data.dart';
import 'catalog_screen.dart';

/// Panel principal del cliente.
/// Adaptador conservado para las rutas del proyecto anterior.
class ClientScreen extends StatelessWidget {
  final SessionData session;
  const ClientScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) => CatalogScreen(session: session);
}
