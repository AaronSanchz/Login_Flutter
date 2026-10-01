# Fake Store Flutter — Actualización US06 a US08

Esta actualización agrega **US06: agregar producto**, **US07: editar producto** y **US08: eliminar producto**. Conserva la base US01–US05: login, roles locales, sesión segura, cierre de sesión, catálogo, categorías y detalle. El proyecto completo abarca US01–US08; el alcance nuevo de esta entrega es US06–US08.

## Versiones conservadas

Flutter 3.47.2 · Dart 3.13.2 · Gradle 8.14 · AGP 8.11.1 · Kotlin Android 2.2.20. Java utilizado: Microsoft OpenJDK 21.0.12.1; destino Java/JVM 17. No se actualizaron SDK ni plugins. Flutter mantiene pubspec.lock del ZIP original.

## Ejecutar

Abre la raíz del proyecto en tu editor. Configura tu SDK Android y JDK; local.properties es personal y no se publica. En Flutter usa el SDK 3.47.2. En Kotlin abre el módulo app en Android Studio y selecciona JDK 21 y SDK 35.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
flutter run
```

## Reglas de US06–US08

Solo Administrador puede crear, editar y eliminar. El repositorio comprueba el rol antes de enviar POST, PUT o DELETE, además de restringir los botones. La creación valida campos, muestra el ID recibido y limpia el formulario. La edición precarga valores, bloquea el guardado mientras espera y actualiza el detalle local. El borrado pide confirmación; Cancelar conserva el detalle sin enviar DELETE y confirmar vuelve al catálogo.

Fake Store **simula las escrituras y no persiste cambios**. Un producto eliminado puede reaparecer al consultar; la edición se refleja localmente con la respuesta recibida. Los controles de rol son académicos y locales; un backend propio debe validar permisos en servidor.

## Roles y prueba

IDs 1 y 2: Administrador; ID 3: Auditor; demás: Cliente. Cuenta pública de ejemplo Administrador: mor_2314 / 83r5^_. No es una credencial privada.

Flutter: 27 pruebas aprobadas, análisis sin incidencias y APK debug. Kotlin: 22 pruebas aprobadas, APK debug y lint con cero errores y 34 avisos. Emulador Android 35: login/catálogo y creación real con ID 21 en ambas apps; edición y eliminación nativas; modo avión Flutter. Falta reproducir todos los escenarios en teléfono físico.

El repositorio contiene código comentado, pruebas, configuración y este README. La guía de aprendizaje y el informe detallado se entregan por separado.
