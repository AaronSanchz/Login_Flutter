// GUÍA DEL ARCHIVO: US02 a US06: catálogo reciclable, filtros, detalle, carrito local del Cliente y acciones del Administrador. AnimatedBuilder escucha CatalogController. _logout borra almacenamiento y carrito, y reemplaza toda la navegación.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

import 'package:flutter/material.dart';

import '../models/session_data.dart';
import '../services/product_repository.dart';
import '../services/session_service.dart';
import '../state/catalog_controller.dart';
import '../state/cart_state.dart';
import '../widgets/product_image.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'product_create_screen.dart';

/// Catálogo, filtros, carga, errores y selección.
class CatalogScreen extends StatefulWidget {
  final SessionData session;
  final ProductRepository? repository;
  const CatalogScreen({super.key, required this.session, this.repository});
  @override
  /// Crea el objeto State asociado al widget para conservar campos, carga y errores entre reconstrucciones.
  State<CatalogScreen> createState() => _CatalogScreenState();
}

/// Conecta los controles de catálogo con el controlador y la navegación.
class _CatalogScreenState extends State<CatalogScreen> {
  late final ProductRepository _repository =
      widget.repository ?? HttpProductRepository();
  late final _state = CatalogController(_repository);
  @override
  /// Inicializa el estado una vez al insertar la pantalla; inicia la carga correspondiente y llama al ciclo de vida heredado.
  void initState() {
    super.initState();
    _state.load();
    _state.loadCategories();
  }

  @override
  /// Libera recursos de esta instancia e invalida sus notificaciones; no debe usarse para iniciar peticiones.
  void dispose() {
    _state.dispose();
    _repository.close();
    super.dispose();
  }

  /// Borra token, ID, nombre y rol del almacenamiento, reinicia carrito y elimina historial al abrir Login. Un fallo de borrado impide anunciar éxito.
  Future<void> _logout() async {
    try {
      await SessionService.clearSession();
      CartState.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión. Reintenta.'),
          ),
        );
      }
    }
  }

  @override
  /// Describe la interfaz a partir del estado actual. El framework puede ejecutarlo varias veces; las peticiones se inician fuera de este método.
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Fake Store'),
      actions: [
        // Control de usuarios: solo se construye para el administrador.
        if (widget.session.role == UserRole.administrador)
          IconButton(
            tooltip: 'Agregar producto',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductCreateScreen(repository: _repository),
              ),
            ),
          ),
        if (widget.session.role == UserRole.administrador)
          IconButton(
            tooltip: 'Usuarios',
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminScreen(session: widget.session),
              ),
            ),
          ),
        // Actualizar conserva el filtro; el controlador descarta respuestas antiguas.
        IconButton(
          tooltip: 'Actualizar catálogo',
          onPressed: () => _state.load(_state.selected),
          icon: const Icon(Icons.refresh),
        ),
        // Cerrar sesión borra también el carrito local.
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.session.username} · ${widget.session.role.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (widget.session.role == UserRole.cliente)
              Text('Carrito local: ${CartState.count}'),
            if (_state.categoriesLoading)
              const LinearProgressIndicator(
                semanticsLabel: 'Cargando categorías',
              ),
            if (_state.categoryError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('No se pudieron cargar las categorías.'),
                    // Reintento independiente de las categorías.
                    TextButton(
                      onPressed: _state.loadCategories,
                      child: const Text('Reintentar categorías'),
                    ),
                  ],
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    // Ver todos elimina el filtro activo.
                    child: ChoiceChip(
                      label: const Text('Ver todos'),
                      selected: _state.selected == null,
                      onSelected: (_) => _state.load(),
                    ),
                  ),
                  ..._state.categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.all(4),
                      // Cada categoría solicita productos filtrados.
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _state.selected == c,
                        onSelected: (active) => _state.load(active ? c : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _state.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Cargando productos',
                      ),
                    )
                  : _state.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_state.error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            // Reintenta la última consulta de productos.
                            FilledButton(
                              onPressed: () => _state.load(_state.selected),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _state.products.isEmpty
                  ? const Center(
                      child: Text('No hay productos en esta categoría.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _state.products.length,
                      itemBuilder: (context, index) {
                        final p = _state.products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          // La fila abre el detalle del producto elegido.
                          child: InkWell(
                            onTap: () async {
                              final reset = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    id: p.id,
                                    repository: _repository,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              if (reset == true) {
                                _state.load();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ProductImage(
                                    url: p.image,
                                    label: p.title,
                                    height: 88,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          p.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        if (widget.session.role ==
                                            UserRole.cliente)
                                          // Agregar solo aparece en el rol cliente.
                                          TextButton.icon(
                                            onPressed: () {
                                              CartState.add(p.id);
                                              setState(() {});
                                            },
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                            ),
                                            label: const Text('Agregar'),
                                          ),
                                        const Text(
                                          'Ver detalle',
                                          style: TextStyle(
                                            color: Color(0xff12685e),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
