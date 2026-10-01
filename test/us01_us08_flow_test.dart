// Pruebas de aceptación con almacenamiento y repositorio simulados.
// Comprueban UI, navegación y bloqueo de HTTP; no prueban el servidor real.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fake_store_roles/models/product.dart';
import 'package:fake_store_roles/models/session_data.dart';
import 'package:fake_store_roles/screens/product_create_screen.dart';
import 'package:fake_store_roles/screens/product_edit_screen.dart';
import 'package:fake_store_roles/screens/product_detail_screen.dart';
import 'package:fake_store_roles/screens/catalog_screen.dart';
import 'package:fake_store_roles/screens/login_screen.dart';
import 'package:fake_store_roles/services/product_repository.dart';
import 'package:fake_store_roles/services/session_service.dart';
import 'package:fake_store_roles/state/cart_state.dart';
import 'package:fake_store_roles/state/login_controller.dart';

const article = Product(
  id: 1,
  title: 'Camisa',
  price: 19.5,
  description: 'Algodón',
  category: 'jewelery',
  image: 'https://example.com/a.png',
);
const admin = SessionData(
  token: 'test',
  userId: 2,
  username: 'admin',
  role: UserRole.administrador,
);

/// Registra escrituras; permite mantener PUT pendiente para verificar el bloqueo.
class RecordingRepository implements ProductRepository {
  int creates = 0, updates = 0, deletes = 0;
  Product? submitted;
  Completer<Product>? pendingUpdate;
  @override
  Future<List<Product>> products([String? category]) async => [];
  @override
  Future<List<String>> categories() async => ['jewelery'];
  @override
  Future<Product> detail(int id) async => article;
  @override
  Future<Product> create(Product p, List<String> categories) async {
    creates++;
    submitted = p;
    return Product(
      id: 21,
      title: p.title,
      price: p.price,
      description: p.description,
      category: p.category,
      image: p.image,
    );
  }

  @override
  Future<Product> update(Product p, List<String> categories) async {
    updates++;
    submitted = p;
    return pendingUpdate?.future ?? Future.value(p);
  }

  @override
  Future<void> delete(int id) async {
    deletes++;
  }

  @override
  void close() {}
}

/// Simula exactamente las claves que usa SessionService en el dispositivo.
void setRole(UserRole role) => FlutterSecureStorage.setMockInitialValues({
  'session_token': 'test',
  'session_user_id': '2',
  'session_username': 'admin',
  'session_role': role.name,
});

/// Abre una pantalla mediante Navigator para observar su resultado al cerrarse.
Future<void> open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    setRole(UserRole.administrador);
    CartState.clear();
  });
  testWidgets(
    'US06 valida campos sin POST y confirma ID con formulario limpio',
    (tester) async {
      final repo = RecordingRepository();
      await open(tester, ProductCreateScreen(repository: repo));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(repo.creates, 0);
      expect(find.text('Este campo es obligatorio.'), findsWidgets);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nueva camisa');
      await tester.enterText(fields.at(1), 'letras');
      await tester.enterText(fields.at(2), 'Algodón');
      await tester.enterText(fields.at(3), 'https://example.com/a.png');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('jewelery').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(repo.creates, 0);
      await tester.enterText(fields.at(1), '25.50');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.creates, 1);
      expect(find.textContaining('Nuevo ID: 21'), findsOneWidget);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      for (final field in tester.widgetList<TextFormField>(fields)) {
        expect(field.controller!.text, '');
      }
    },
  );
  testWidgets('US07 precarga, bloquea doble PUT y devuelve cambios al cerrar', (
    tester,
  ) async {
    final repo = RecordingRepository()..pendingUpdate = Completer<Product>();
    await open(tester, ProductEditScreen(product: article, repository: repo));
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Camisa',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      '19.50',
    );
    expect(find.text('jewelery'), findsOneWidget);
    await tester.enterText(fields.at(0), 'Camisa editada');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    expect(repo.updates, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    repo.pendingUpdate!.complete(repo.submitted!);
    await tester.pumpAndSettle();
    expect(find.byType(ProductEditScreen), findsNothing);
    expect(find.text('Producto actualizado (Simulación)'), findsOneWidget);
    expect(repo.submitted!.title, 'Camisa editada');
  });
  testWidgets(
    'US08 cancelar no envía DELETE; confirmar vuelve a pantalla anterior',
    (tester) async {
      final repo = RecordingRepository();
      await open(tester, ProductDetailScreen(id: 1, repository: repo));
      await tester.ensureVisible(find.text('Eliminar'));
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.deletes, 0);
      expect(find.text('Camisa'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(find.text('Abrir'), findsOneWidget);
    },
  );
  testWidgets('US02 borra sesión y carrito e impide volver al catálogo', (
    tester,
  ) async {
    CartState.add(1);
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(session: admin, repository: RecordingRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(await SessionService.loadSession(), isNull);
    expect(CartState.count, 0);
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CatalogScreen), findsNothing);
  });
  test(
    'US01 destruir controlador antes de respuesta no guarda sesión',
    () async {
      final pending = Completer<SessionData>();
      var saved = 0;
      final controller = LoginController(
        authenticate: (_, __) => pending.future,
        saveSession: (_) async {
          saved++;
        },
      );
      final result = controller.submit('admin', 'clave');
      controller.dispose();
      pending.complete(admin);
      expect(await result, isNull);
      expect(saved, 0);
    },
  );
}
