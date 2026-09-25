# FakeStore Flutter Dart

**Versión reestructurada:** consulta [ARQUITECTURA_Y_PRUEBAS.md](ARQUITECTURA_Y_PRUEBAS.md) para la arquitectura y el código actual. La guía HTML incluida documenta la base anterior.

Proyecto completo de continuación de Fake Store para US03, US04 y US05. Empieza abriendo **docs/GUIA_COMPLETA.html** en un navegador; contiene requisitos, arquitectura, explicación por archivo y código completo numerado.


## Abrir y ejecutar Flutter

Extrae el ZIP en una carpeta local. Abre FakeStore_Flutter_Dart en Android Studio o VS Code. Este proyecto incluye el destino Android, como la base recibida; no incluye carpetas iOS, web o escritorio.

Instala Flutter y configura el SDK Android con licencias aceptadas. La entrega se comprobó con Flutter 3.47.2 y Dart 3.13.2. No uses el límite inferior del pubspec como garantía de compatibilidad con SDK antiguos: las dependencias bloqueadas y los widgets usados se comprobaron con esa versión concreta.

```powershell
flutter doctor
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter run
```

Para construir un APK de prueba:

```powershell
flutter build apk --debug
```

El resultado se crea en build/app/outputs/flutter-apk/app-debug.apk. No está firmado para publicación en una tienda. Flutter prepara android/local.properties con tus rutas locales; no copies las rutas de otra computadora. Selecciona un dispositivo/emulador Android antes de flutter run. Las dependencias y Gradle se descargan la primera vez.

Configuración Android conservada: AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14 y lenguaje JVM 17. Flutter 3.47.2 advierte que esas versiones requerirán actualización en una versión futura; la advertencia no equivale a un fallo de compilación. El applicationId permanece com.example.fakestoreroles.

## Cuentas de demostración del proyecto base

| Perfil | Usuario | Contraseña |
|---|---|---|
| Administrador ID 2 | mor_2314 | 83r5^_ |
| Auditor ID 3 | kevinryan | kev02937@ |
| Cliente ID 4 | donero | ewedon |

Son cuentas públicas de ejemplo del código recibido. Su disponibilidad depende del servicio y no se garantiza si cambia la base remota. No se añade un acceso que omita la autenticación cuando la API no está disponible.

## Documentación

- docs/ARQUITECTURA_Y_REQUISITOS.md
- docs/CODIGO_EXPLICADO.md
- docs/VERIFICACION.md
- docs/CAMBIOS_SOBRE_BASE.md
- docs/historias

Los avisos y límites de Fake Store están descritos en la guía y en las pantallas de gestión.
# Reestructuración POO US03–US05

Consulta [ARQUITECTURA_Y_PRUEBAS.md](ARQUITECTURA_Y_PRUEBAS.md) para la separación de vistas, controladores, modelos, validaciones y servicios, junto con los botones, permisos, códigos HTTP y pruebas ampliadas.
