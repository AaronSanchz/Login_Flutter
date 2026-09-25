import 'package:flutter/material.dart';
import '../models/session_data.dart';
import 'catalog_screen.dart';

/// Panel de consulta del auditor.
/// El auditor consulta el mismo catálogo sin controles administrativos.
class AuditorScreen extends StatelessWidget {
  final SessionData session;
  const AuditorScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) => CatalogScreen(session: session);
}
