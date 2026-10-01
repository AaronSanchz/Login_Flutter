// GUÍA DEL ARCHIVO: US07: precarga título, precio, descripción, imagen y categoría. Verifica rol al abrir y en repositorio al guardar; bloquea formulario y retroceso durante PUT. Devuelve el Product actualizado a la pantalla de detalle.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_repository.dart';
import '../services/session_service.dart';
import '../models/session_data.dart';

/// Formulario de edición, validaciones y confirmación simulada.
class ProductEditScreen extends StatefulWidget {
  final Product product;
  final ProductRepository repository;
  const ProductEditScreen({
    super.key,
    required this.product,
    required this.repository,
  });
  @override
  /// Crea el objeto State asociado al widget para conservar campos, carga y errores entre reconstrucciones.
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

/// Controla carga, guardado y mensajes del formulario.
class _ProductEditScreenState extends State<ProductEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.product.title);
  late final _description = TextEditingController(
    text: widget.product.description,
  );
  late final _price = TextEditingController(
    text: widget.product.price.toStringAsFixed(2),
  );
  late final _image = TextEditingController(text: widget.product.image);
  late String _category = widget.product.category;
  List<String> _categories = [];
  bool _loading = true, _saving = false;
  String? _error;
  @override
  /// Inicializa el estado una vez al insertar la pantalla; inicia la carga correspondiente y llama al ciclo de vida heredado.
  void initState() {
    super.initState();

    /// Lee la sesión segura antes de permitir la edición; si no hay Administrador deniega la ruta.
    _checkAccess();
  }

  /// US07: comprueba el rol al abrir la ruta, además del control en repositorio.
  /// Lee la sesión segura antes de permitir la edición; si no hay Administrador deniega la ruta.
  Future<void> _checkAccess() async {
    try {
      if ((await SessionService.loadSession())?.role ==
          UserRole.administrador) {
        /// Activa carga, solicita categorías al repositorio y conserva el error para reintentar; finally termina el indicador.
        await _loadCategories();
        return;
      }
    } catch (_) {
      // Una sesión ilegible también niega el acceso al formulario.
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  /// Libera recursos de esta instancia e invalida sus notificaciones; no debe usarse para iniciar peticiones.
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _image.dispose();
    super.dispose();
  }

  /// Activa carga, solicita categorías al repositorio y conserva el error para reintentar; finally termina el indicador.
  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.repository.categories();
      if (mounted) setState(() => _categories = values);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// El botón Guardar llama aquí. Valida campos, marca solicitud en curso, ejecuta create/update y procesa éxito o error; finally desbloquea el formulario.
  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final p = Product(
        id: widget.product.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: ProductRules.parsePrice(_price.text)!,
        category: _category,
        image: _image.text.trim(),
      );
      final saved = await widget.repository.update(p, _categories);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado (Simulación)')),
      );
      Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Demostración: la API devuelve los cambios, pero no los conserva.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _title,
                        enabled: !_saving,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (v) => ProductRules.requiredText(v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator: ProductRules.price,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        enabled: !_saving,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        validator: (v) =>
                            ProductRules.requiredText(v, max: 5000),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _image,
                        enabled: !_saving,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Imagen (URL HTTPS)',
                        ),
                        validator: ProductRules.image,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _categories.contains(_category)
                            ? _category
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) {
                                if (v != null) {
                                  setState(() => _category = v);
                                }
                              },
                        validator: (v) => v == null || !_categories.contains(v)
                            ? 'Selecciona una categoría.'
                            : null,
                      ),
                      if (_categories.isEmpty)
                        // Recupera categorías si la primera carga falló.
                        TextButton(
                          onPressed: _saving ? null : _loadCategories,
                          child: const Text('Reintentar categorías'),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Guardar se bloquea durante la petición o sin categorías válidas.
                      FilledButton(
                        onPressed: _saving || _categories.isEmpty
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
