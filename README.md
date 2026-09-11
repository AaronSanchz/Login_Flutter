# Fake Store Roles - Flutter / Dart

Proyecto escolar basado en las historias de usuario US01 y US02.

## Lo que cumple
- Comprueba la conectividad antes de intentar el login.
- Autentica con `POST https://fakestoreapi.com/auth/login`.
- Después del token consulta `GET /users` para obtener el ID del usuario.
- Asigna los roles por ID: 1 y 2 Administrador, 3 Auditor, restantes Cliente.
- Guarda token, ID, username y rol con `flutter_secure_storage`.
- Restaura una sesión guardada al volver a abrir la app.
- Cierra sesión eliminando token, ID, username, rol y el estado local del carrito.
- Al cerrar sesión elimina el historial de navegación para impedir volver a una pantalla protegida con Atrás.

## Usuarios de prueba
- Administrador (ID 2): `mor_2314` / `83r5^_`
- Auditor (ID 3): `kevinryan` / `kev02937@`
- Cliente (ID 4): `donero` / `ewedon`

> Nota: `johnd` tiene ID 1, por lo tanto también es Administrador según la regla de negocio de US01.

## Cómo ejecutar
1. Instala Flutter y Android Studio.
2. Abre esta carpeta en VS Code o Android Studio.
3. Ejecuta `flutter pub get`.
4. Ejecuta `flutter run`.
5. Para generar APK: `flutter build apk --release`.

## Android
El proyecto usa Java 17 y `minSdk = 23`.
