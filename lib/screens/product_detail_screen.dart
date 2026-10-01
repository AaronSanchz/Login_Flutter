// GUÍA DEL ARCHIVO: US05, US07 y US08: obtiene GET /products/{id}, construye Editar y Eliminar solo para Administrador. _edit recibe cambios locales del editor; _delete pide confirmación antes de DELETE. Fallo de consulta vuelve al catálogo.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/session_data.dart';
import '../services/product_repository.dart';
import '../services/session_service.dart';
import '../widgets/product_image.dart';
import 'product_edit_screen.dart';

/// Detalle y acciones permitidas para cada rol.
class ProductDetailScreen extends StatefulWidget {
  final int id;
  final ProductRepository repository;
  const ProductDetailScreen({
    super.key,
    required this.id,
    required this.repository,
  });
  @override
  /// Crea el objeto State asociado al widget para conservar campos, carga y errores entre reconstrucciones.
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

/// Gestiona la carga del detalle y las acciones visuales.
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _admin = false, _busy = false;
  @override
  /// Inicializa el estado una vez al insertar la pantalla; inicia la carga correspondiente y llama al ciclo de vida heredado.
  void initState() {
    super.initState();

    /// Recupera sesión y detalle del ID recibido; muestra datos válidos o avisa y devuelve al catálogo si falla.
    _load();
  }

  /// Recupera sesión y detalle del ID recibido; muestra datos válidos o avisa y devuelve al catálogo si falla.
  Future<void> _load() async {
    try {
      final session = await SessionService.loadSession();
      if (session == null) throw const StoreException('Sesión no disponible');
      final product = await widget.repository.detail(widget.id);
      if (mounted) {
        setState(() {
          _product = product;
          _admin = session.role == UserRole.administrador;
        });
      }
    } catch (_) {
      if (!mounted) return;
      // Alerta visible sin exigir interacción; se restablece el catálogo general.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto no disponible')));
      Navigator.pop(context, true);
    }
  }

  /// Abre el formulario con el producto actual y recibe el objeto resultante para actualizar el detalle local.
  Future<void> _edit() async {
    if (!_admin || _busy || _product == null) return;
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditScreen(
          product: _product!,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted && result != null) setState(() => _product = result);
  }

  /// Pregunta confirmación; Cancelar retorna sin HTTP. Confirmar bloquea acciones, llama delete y regresa al catálogo solo si tiene éxito.
  Future<void> _delete() async {
    if (!_admin || _busy || _product == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de eliminar este producto? La API simula esta operación y no modifica su base de datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Eliminación simulada confirmada. La API conserva el producto.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) {
    final p = _product;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: SafeArea(
        child: p == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ProductImage(
                        url: p.image,
                        label: p.title,
                        height: 240,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      p.category,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${p.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (p.rating != null)
                      Text(
                        '${p.rating!.rate} / 5 · ${p.rating!.count} valoraciones',
                      ),
                    const SizedBox(height: 24),
                    Text(
                      p.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    // Los widgets de gestión se construyen solamente para la sesión administradora.
                    if (_admin) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Edición y eliminación de demostración; la API no guarda los cambios.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : _edit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _delete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                      if (_busy) const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
