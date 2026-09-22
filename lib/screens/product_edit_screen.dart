import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_repository.dart';

class ProductEditScreen extends StatefulWidget {
  final Product product;
  final ProductRepository repository;
  const ProductEditScreen(
      {super.key, required this.product, required this.repository});
  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.product.title);
  late final _description =
      TextEditingController(text: widget.product.description);
  late final _price =
      TextEditingController(text: widget.product.price.toStringAsFixed(2));
  late final _image = TextEditingController(text: widget.product.image);
  late String _category = widget.product.category;
  List<String> _categories = [];
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _image.dispose();
    super.dispose();
  }

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
          image: _image.text.trim());
      final saved = await widget.repository.update(p, _categories);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Edición simulada confirmada. Los cambios no se guardan en la API.')));
      Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
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
                                    'Demostración: la API devuelve los cambios, pero no los conserva.'),
                                const SizedBox(height: 20),
                                TextFormField(
                                    controller: _title,
                                    enabled: !_saving,
                                    decoration: const InputDecoration(
                                        labelText: 'Título'),
                                    validator: (v) =>
                                        ProductRules.requiredText(v)),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _price,
                                    enabled: !_saving,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'Precio'),
                                    validator: ProductRules.price),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _description,
                                    enabled: !_saving,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                        labelText: 'Descripción'),
                                    validator: (v) => ProductRules.requiredText(
                                        v,
                                        max: 5000)),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _image,
                                    enabled: !_saving,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                        labelText: 'Imagen (URL HTTPS)'),
                                    validator: ProductRules.image),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                    initialValue:
                                        _categories.contains(_category)
                                            ? _category
                                            : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Categoría'),
                                    items: _categories
                                        .map((c) => DropdownMenuItem(
                                            value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() => _category = v);
                                            }
                                          },
                                    validator: (v) =>
                                        v == null || !_categories.contains(v)
                                            ? 'Selecciona una categoría.'
                                            : null),
                                if (_categories.isEmpty)
                                  TextButton(
                                      onPressed:
                                          _saving ? null : _loadCategories,
                                      child:
                                          const Text('Reintentar categorías')),
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Text(_error!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error))),
                                const SizedBox(height: 24),
                                FilledButton(
                                    onPressed: _saving || _categories.isEmpty
                                        ? null
                                        : _save,
                                    child: Text(_saving
                                        ? 'Guardando…'
                                        : 'Guardar cambios')),
                              ]))))));
}
