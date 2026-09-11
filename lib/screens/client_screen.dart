import 'package:flutter/material.dart';

import '../models/session_data.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../state/cart_state.dart';
import 'login_screen.dart';

class ClientScreen extends StatefulWidget {
  final SessionData session;

  const ClientScreen({super.key, required this.session});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _api.getProducts();
  }

  void _reload() {
    setState(() => _productsFuture = _api.getProducts());
  }

  void _addToCart(int id) {
    CartState.add(id);
    setState(() {});
  }

  Future<void> _logout() async {
    await SessionService.clearSession();
    CartState.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          Center(child: Text('Carrito: ${CartState.count}  ')),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesión: ${widget.session.username}'),
            Text('ID: ${widget.session.userId}'),
            const Text(
              'Rol: Cliente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Productos', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(snapshot.error.toString()),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final price = product['price'];
                      final rawId = product['id'];
                      final id = rawId is int
                          ? rawId
                          : int.tryParse(rawId?.toString() ?? '') ?? 0;

                      return ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(product['title']?.toString() ?? 'Producto'),
                        subtitle: Text(product['category']?.toString() ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('\$${price ?? 0}'),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _addToCart(id),
                              child: const Text(
                                'Agregar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
