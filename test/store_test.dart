import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fake_store_roles/models/product.dart';
import 'package:fake_store_roles/models/session_data.dart';
import 'package:fake_store_roles/services/product_repository.dart';
import 'package:fake_store_roles/state/catalog_controller.dart';
import 'package:fake_store_roles/screens/product_detail_screen.dart';
import 'package:fake_store_roles/screens/catalog_screen.dart';

final raw = {
  'id': 1,
  'title': 'Camisa',
  'price': 19.5,
  'description': 'Algodón',
  'category': "men's clothing",
  'image': 'https://example.com/image.png',
  'rating': {'rate': 4.2, 'count': 9}
};
Product product({String title = 'Camisa'}) => Product(
    id: 1,
    title: title,
    price: 19.5,
    description: 'Algodón',
    category: "men's clothing",
    image: '');
SessionData session(UserRole role) =>
    SessionData(token: 'test', userId: 1, username: 'test', role: role);

class FakeRepository implements ProductRepository {
  final pending = <Completer<List<Product>>>[];
  bool failDetail = false;
  @override
  Future<List<Product>> products([String? category]) {
    final c = Completer<List<Product>>();
    pending.add(c);
    return c.future;
  }

  @override
  Future<List<String>> categories() async => ["men's clothing", 'jewelery'];
  @override
  Future<Product> detail(int id) async {
    if (failDetail) throw const StoreException('404');
    return product();
  }

  @override
  Future<Product> update(Product p, List<String> categories) async => p;
  @override
  Future<void> delete(int id) async {}
  @override
  void close() {}
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    loader.addFont(File('test/fonts/roboto-regular.ttf')
        .readAsBytes()
        .then(ByteData.sublistView));
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('test/fonts/materialicons-regular.otf')
        .readAsBytes()
        .then(ByteData.sublistView));
    await icons.load();
  });
  test('Mapea todos los campos y rating', () {
    final p = Product.fromJson(raw);
    expect(p.id, 1);
    expect(p.rating!.count, 9);
    expect(p.description, 'Algodón');
  });
  test('Rechaza datos obligatorios nulos, vacíos, ID y precio inválidos', () {
    for (final patch in [
      {'title': null},
      {'description': '  '},
      {'category': 12},
      {'id': 0},
      {'id': 1.2},
      {'price': double.nan},
      {'price': -1}
    ]) {
      expect(() => Product.fromJson({...raw, ...patch}), throwsFormatException);
    }
  });
  test('Imagen y rating inválidos tienen sustituto seguro', () {
    final p = Product.fromJson({
      ...raw,
      'image': null,
      'rating': {'rate': 8, 'count': -1}
    });
    expect(p.image, '');
    expect(p.rating, isNull);
  });
  test('Valida entradas sin aceptar vacíos, NaN o cantidades negativas', () {
    for (final text in [
      '',
      ' ',
      '-1',
      '0',
      'NaN',
      'Infinity',
      '1000001',
      '1.234',
      '1e3'
    ]) {
      expect(ProductRules.price(text), isNotNull, reason: text);
    }
    expect(ProductRules.price('12,50'), isNull);
    expect(ProductRules.parsePrice('12,50'), 12.5);
    expect(ProductRules.requiredText('  '), isNotNull);
    expect(ProductRules.image('http://example.com/a'), isNotNull);
    expect(ProductRules.image('https://example.com/a'), isNull);
  });
  test('HTTP consulta productos, categorías, filtro codificado y detalle',
      () async {
    final paths = <String>[];
    final repo = HttpProductRepository(client: MockClient((request) async {
      paths.add(request.url.path);
      final body = request.url.path.endsWith('/categories')
          ? ["men's clothing"]
          : request.url.path.endsWith('/1')
              ? raw
              : [raw];
      return http.Response(jsonEncode(body), 200);
    }));
    expect((await repo.products()).length, 1);
    expect(await repo.categories(), ["men's clothing"]);
    await repo.products("men's clothing");
    await repo.detail(1);
    expect(paths, [
      '/products',
      '/products/categories',
      "/products/category/men's%20clothing",
      '/products/1'
    ]);
    repo.close();
  });
  test('Errores HTTP, cuerpo vacío, null y JSON inválido se controlan',
      () async {
    for (final response in [
      http.Response('', 200),
      http.Response('null', 200),
      http.Response('bad', 200),
      http.Response('{}', 503),
      http.Response('{}', 404)
    ]) {
      final repo =
          HttpProductRepository(client: MockClient((_) async => response));
      await expectLater(repo.products(), throwsA(isA<StoreException>()));
      repo.close();
    }
  });
  test('La API puede devolver lista vacía sin provocar error', () async {
    final repo = HttpProductRepository(
        client: MockClient((_) async => http.Response('[]', 200)));
    expect(await repo.products(), isEmpty);
    repo.close();
  });
  test('Rechaza categorías incompletas y detalle con ID diferente', () async {
    final repo = HttpProductRepository(
        client: MockClient((r) async => http.Response(
            r.url.path.endsWith('categories')
                ? '[null]'
                : jsonEncode({...raw, 'id': 2}),
            200)));
    await expectLater(repo.categories(), throwsA(isA<StoreException>()));
    await expectLater(repo.detail(1), throwsA(isA<StoreException>()));
    repo.close();
  });
  test('Cliente, Auditor y sesión ausente no ejecutan escrituras HTTP',
      () async {
    for (final role in [UserRole.cliente, UserRole.auditor, null]) {
      var calls = 0;
      final repo = HttpProductRepository(
          session: () async => role == null ? null : session(role),
          client: MockClient((_) async {
            calls++;
            return http.Response(jsonEncode(raw), 200);
          }));
      await expectLater(repo.update(Product.fromJson(raw), ["men's clothing"]),
          throwsA(isA<StoreException>()));
      await expectLater(repo.delete(1), throwsA(isA<StoreException>()));
      expect(calls, 0);
      repo.close();
    }
  });
  test('Admin envía PUT y DELETE después de validar', () async {
    final methods = <String>[];
    final repo = HttpProductRepository(
        session: () async => session(UserRole.administrador),
        client: MockClient((r) async {
          methods.add(r.method);
          if (r.method == 'PUT') expect(jsonDecode(r.body)['title'], 'Camisa');
          return http.Response(jsonEncode(raw), 200);
        }));
    await repo.update(Product.fromJson(raw), ["men's clothing"]);
    await repo.delete(1);
    expect(methods, ['PUT', 'DELETE']);
    repo.close();
  });
  test('Cambio de filtro limpia datos y descarta respuestas antiguas',
      () async {
    final repo = FakeRepository();
    final c = CatalogController(repo);
    await c.loadCategories();
    final first = c.load();
    final second = c.load('jewelery');
    expect(c.products, isEmpty);
    expect(c.loading, isTrue);
    repo.pending[1].complete([product(title: 'Último')]);
    await second;
    repo.pending[0].complete([product(title: 'Antiguo')]);
    await first;
    expect(c.products.single.title, 'Último');
    expect(c.selected, 'jewelery');
    expect(c.loading, isFalse);
    c.dispose();
  });
  test('Reintento recupera un error y dispose tolera petición en curso',
      () async {
    final repo = FakeRepository();
    final c = CatalogController(repo);
    final load = c.load();
    repo.pending[0].completeError(const StoreException('Sin red'));
    await load;
    expect(c.error, 'Sin red');
    expect(c.loading, isFalse);
    final retry = c.load();
    repo.pending[1].complete([product()]);
    await retry;
    expect(c.error, isNull);
    final late = c.load();
    c.dispose();
    repo.pending[2].complete([]);
    await late;
  });
  for (final role in UserRole.values) {
    testWidgets('Detalle construye acciones según sesión local: ${role.name}',
        (tester) async {
      tester.view.physicalSize = const Size(430, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({
        'session_token': 'test',
        'session_user_id': '1',
        'session_username': 'test',
        'session_role': role.name
      });
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xff12685e)),
              scaffoldBackgroundColor: const Color(0xfff5f7f6)),
          home: ProductDetailScreen(id: 1, repository: FakeRepository())));
      await tester.pumpAndSettle();
      expect(find.text('Camisa'), findsOneWidget);
      expect(find.text('Algodón'), findsOneWidget);
      expect(find.text('Editar'),
          role == UserRole.administrador ? findsOneWidget : findsNothing);
      expect(find.text('Eliminar'),
          role == UserRole.administrador ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
      if (role == UserRole.administrador) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/detail_admin.png'));
      }
    });
  }
  testWidgets('Detalle fallido muestra aviso y regresa automáticamente',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'session_token': 'test',
      'session_user_id': '1',
      'session_username': 'test',
      'session_role': 'cliente'
    });
    final repo = FakeRepository()..failDetail = true;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('Abrir'),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                                id: 1, repository: repo))))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Producto no disponible'), findsOneWidget);
  });
  testWidgets('Catálogo dibuja filas, imágenes sustitutas y categorías',
      (tester) async {
    tester.view.physicalSize = const Size(430, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeRepository();
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff12685e)),
            scaffoldBackgroundColor: const Color(0xfff5f7f6)),
        home: CatalogScreen(
            session: session(UserRole.cliente), repository: repo)));
    repo.pending.single.complete([
      product(title: 'Camisa de algodón'),
      const Product(
          id: 2,
          title: 'Mochila para todos los días',
          price: 49.90,
          description: 'Ligera',
          category: "men's clothing",
          image: ''),
      const Product(
          id: 3,
          title: 'Anillo de plata',
          price: 24.50,
          description: 'Plata',
          category: 'jewelery',
          image: '')
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Camisa de algodón'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.text('Agregar'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/catalog_client.png'));
  });
}
