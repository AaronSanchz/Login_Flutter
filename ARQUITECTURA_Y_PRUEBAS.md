# Fake Store API: arquitectura Flutter

## Versiones conservadas

Flutter 3.47.2, Dart 3.13.2, Gradle 8.14, Android Gradle Plugin 8.11.1 y Kotlin 2.2.20. Se conservaron las restricciones de `pubspec.yaml` y las dependencias existentes.

## Organización orientada a objetos

| Carpeta | Responsabilidad |
| --- | --- |
| `lib/models/` | Productos, puntuación, sesión y roles. |
| `lib/validation/` | Reglas reutilizables del formulario y producto. |
| `lib/services/` | Autenticación, repositorio HTTP, sesión segura y errores por código HTTP. |
| `lib/state/` | Controladores de acceso y catálogo; carrito temporal. |
| `lib/screens/` | Vistas, navegación, mensajes y controles de usuario. |
| `lib/widgets/` | Imagen reutilizable con sustituto si falla. |

`LoginScreen` presenta los campos y observa `LoginController`, que valida, evita dobles envíos, autentica y guarda la sesión. `CatalogScreen` observa `CatalogController`, que conserva filtros, carga, errores y descarta respuestas antiguas. `ProductRepository` permite inyectar un repositorio falso en pruebas; `HttpProductRepository` vuelve a verificar permisos y campos antes de enviar PUT o DELETE. Cada clase documenta su función junto a su declaración.

## Controles y permisos

| Control | Función y validación |
| --- | --- |
| Iniciar sesión | Comprueba campos obligatorios y límites; se deshabilita durante la autenticación. |
| Actualizar, Reintentar y Reintentar categorías | Repiten una consulta tras error o cuando el usuario lo solicita. |
| Ver todos y categorías | Filtran productos y descartan resultados de solicitudes anteriores. |
| Ver detalle | Abre el producto seleccionado; el error devuelve al catálogo. |
| Agregar | Solo cliente; actualiza el carrito local. |
| Editar y Guardar cambios | Solo administrador; valida campos antes de PUT. |
| Eliminar y Cancelar | Solo administrador; muestran confirmación previa a DELETE. |
| Cerrar sesión | Borra sesión y carrito y regresa al acceso. |

La API Fake Store simula PUT y DELETE, por lo que sus respuestas no persisten cambios. `HttpErrorMapper` identifica 400/401, 403, 404, 408/504, 429 y 5xx; el repositorio maneja también esperas, desconexión, JSON inválido y respuesta vacía.

## Pruebas

Ejecutar `flutter pub get`, `flutter analyze --no-pub` y `flutter test --no-pub`. La suite usa `MockClient`, repositorios falsos, pruebas de controladores y pruebas de widgets. Verifica validaciones, acceso según rol, ausencia de escrituras no autorizadas, doble envío de login, error al guardar sesión, rutas y filtros, solicitudes concurrentes, recuperación de errores y controles visibles. El análisis y las pruebas pasaron en esta entrega.
