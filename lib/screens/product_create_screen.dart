// GUÍA DEL ARCHIVO: US06: verifica sesión local al abrir, obtiene categorías y construye formulario. _save valida antes del POST; limpia campos y muestra alerta con ID. Cliente y Auditor se redirigen al catálogo; sin sesión se abre Login.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import 'catalog_screen.dart';
import 'login_screen.dart';

import '../models/product.dart';
import '../models/session_data.dart';
import '../services/product_repository.dart';
import '../services/session_service.dart';

/// US06: formulario de alta. El repositorio vuelve a comprobar el rol y los datos.
class ProductCreateScreen extends StatefulWidget {
  final ProductRepository repository;
  const ProductCreateScreen({super.key, required this.repository});

  @override
  /// Crea el objeto State asociado al widget para conservar campos, carga y errores entre reconstrucciones.
  State<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends State<ProductCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  List<String> _categories = [];
  String? _category, _error;
  bool _checking = true, _saving = false, _authorized = false;

  @override
  /// Inicializa el estado una vez al insertar la pantalla; inicia la carga correspondiente y llama al ciclo de vida heredado.
  void initState() {
    super.initState();

    /// Verifica Administrador en sesión segura antes de obtener categorías; una ruta sin permiso se reemplaza por catálogo o Login.
    _initialize();
  }

  /// Impide que un enlace o navegación forzada abra el formulario sin permiso.
  /// Verifica Administrador en sesión segura antes de obtener categorías; una ruta sin permiso se reemplaza por catálogo o Login.
  Future<void> _initialize() async {
    try {
      final session = await SessionService.loadSession();
      if (session?.role != UserRole.administrador) {
        if (mounted) {
          // Reemplaza la pila: una ruta forzada puede no tener catálogo debajo.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => session == null
                  ? const LoginScreen()
                  : CatalogScreen(session: session),
            ),
            (_) => false,
          );
        }
        return;
      }
      if (mounted) setState(() => _authorized = true);
      final categories = await widget.repository.categories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Valida antes de enviar POST; deshabilita el botón durante la solicitud.
  /// El botón Guardar llama aquí. Valida campos, marca solicitud en curso, ejecuta create/update y procesa éxito o error; finally desbloquea el formulario.
  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final product = Product(
        id: 0,
        title: _title.text.trim(),
        price: ProductRules.parsePrice(_price.text)!,
        description: _description.text.trim(),
        category: _category!,
        image: _image.text.trim(),
      );
      final created = await widget.repository.create(product, _categories);
      if (!mounted) return;
      _title.clear();
      _price.clear();
      _description.clear();
      _image.clear();
      _form.currentState?.reset();
      setState(() => _category = null);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Producto creado (Simulación)'),
          content: Text(
            'Nuevo ID: ${created.id}. La API no conserva el producto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  /// Libera recursos de esta instancia e invalida sus notificaciones; no debe usarse para iniciar peticiones.
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : !_authorized
          ? const Center(child: Text('Acceso denegado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'La API confirma el alta, pero no conserva el producto.',
                    ),
                    TextFormField(
                      controller: _title,
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: ProductRules.requiredText,
                    ),
                    TextFormField(
                      controller: _price,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Precio'),
                      validator: ProductRules.price,
                    ),
                    TextFormField(
                      controller: _description,
                      enabled: !_saving,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      validator: (v) => ProductRules.requiredText(v, max: 5000),
                    ),
                    TextFormField(
                      controller: _image,
                      enabled: !_saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Imagen (URL HTTPS)',
                      ),
                      validator: ProductRules.image,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _category = v),
                      validator: (v) => v == null || !_categories.contains(v)
                          ? 'Selecciona una categoría.'
                          : null,
                    ),
                    if (_categories.isEmpty)
                      TextButton(
                        onPressed: _saving ? null : _initialize,
                        child: const Text('Reintentar categorías'),
                      ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving || _categories.isEmpty ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
