// GUÍA DEL ARCHIVO: Adaptador de compatibilidad de la ruta antigua del Cliente. Construye CatalogScreen con la sesión recibida; las restricciones y el cierre de sesión viven en el catálogo compartido.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/session_data.dart';
import 'catalog_screen.dart';

/// Panel principal del cliente.
/// Adaptador conservado para las rutas del proyecto anterior.
class ClientScreen extends StatelessWidget {
  final SessionData session;
  const ClientScreen({super.key, required this.session});
  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) => CatalogScreen(session: session);
}
