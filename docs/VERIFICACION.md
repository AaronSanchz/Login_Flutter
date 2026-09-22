# Informe de verificación Flutter

Fecha de la revisión local 17 de septiembre de 2026.

| Comprobación | Resultado observado |
|---|---|
| Resolución de dependencias | flutter pub get completado |
| Análisis estático | flutter analyze --no-pub sin observaciones |
| Pruebas automatizadas | flutter test --no-pub, 17 aprobadas |
| Compilación Dart para Android | compileFlutterBuildDebug completada |
| Capturas de widgets | Catálogo Cliente y detalle Administrador inspeccionados a 430 × 960; comparación golden aprobada |
| APK Android | No completado: faltó descargar el componente Android ARM64 del motor Flutter |

Las capturas test/goldens utilizan datos de prueba y sustitutos de imagen; no representan una sesión con datos reales. test/fonts incluye fuentes de prueba y sus licencias para hacer reproducible la comparación visual en el entorno comprobado. Las capturas pueden necesitar regeneración deliberada si se cambia Flutter o el diseño; no deben actualizarse automáticamente para ocultar un fallo.

Los tests cubren datos obligatorios y opcionales, validaciones, endpoints, errores de JSON/HTTP, lista vacía, ID inconsistente, permisos de escritura, PUT/DELETE, descarte de respuestas obsoletas, reintento, dispose, jerarquía de botones por rol y regreso automático ante detalle fallido. Se comprobaron también las filas y categorías del catálogo.

La compilación intentó obtener io.flutter:arm64_v8a_debug:1.0.0-1cf1c4773fb941c4c74a7f8bb144a8837596c0f4. La compilación sin red confirmó que faltaba ese JAR en la caché. La versión de código y las pruebas Dart sí fueron verificadas; no se presenta un APK Flutter como compilado. Para completar la comprobación en una red con acceso a los repositorios, ejecutar flutter build apk --debug.

Las consultas GET de comprobación al servidor real devolvieron HTTP 403 o tiempos de espera desde este entorno. No se afirma que el flujo completo contra Internet se haya validado. No se ejecutaron PUT ni DELETE sobre el servicio real: las escrituras se verificaron con dobles de transporte. No había teléfono ni emulador conectado; no se ejecutaron pruebas instrumentadas en un dispositivo Android.

Se observaron advertencias de futura obsolescencia de Gradle 8.14, AGP 8.11.1 y Kotlin 2.2.20 para futuras versiones de Flutter, además de advertencias del lector de metadatos SDK. No se desactivaron validaciones para ocultarlas.
