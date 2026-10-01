// GUÍA DEL ARCHIVO: Adaptador de compatibilidad de la ruta antigua del Auditor. Construye el catálogo compartido; no crea un segundo sistema de permisos ni una copia de productos.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/session_data.dart';
import 'catalog_screen.dart';

/// Panel de consulta del auditor.
/// El auditor consulta el mismo catálogo sin controles administrativos.
class AuditorScreen extends StatelessWidget {
  final SessionData session;
  const AuditorScreen({super.key, required this.session});
  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) => CatalogScreen(session: session);
}
