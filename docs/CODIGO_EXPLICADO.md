# Explicación del código por archivo

Lee primero los modelos, después servicios, estado y pantallas. Este documento explica las responsabilidades y los métodos; el anexo HTML permite seguir el código completo por línea.

## lib/main.dart

Punto de entrada y composición visual. main inicializa los servicios de Flutter antes de runApp. FakeStoreApp configura Material 3, un color verde y fondos claros. SessionGate espera loadSession mediante FutureBuilder, presenta un indicador y selecciona acceso o catálogo. _screenFor conserva una única ruta común para los tres perfiles.

## lib/models/session_data.dart

UserRole enumera Administrador, Auditor y Cliente, evitando comparar textos libres. UserRoleText traduce el nombre de almacenamiento a una etiqueta visual. SessionData agrupa token, ID, username y role en campos final; nunca contiene la contraseña.

## lib/models/product.dart

Product declara los campos de la API: id, title, price, description, category, image y rating. fromJson comprueba tipos y valores obligatorios antes de construir el objeto; la función interna text concentra la validación de cadenas. toJson prepara el cuerpo de edición. Rating.tryParse permite que una puntuación opcional inválida no rompa el detalle. ProductRules.requiredText controla vacíos y longitudes; parsePrice normaliza coma decimal; price valida el texto; image verifica la URL; validate revalida el modelo y la categoría antes del envío.

## lib/services/api_service.dart

Se conserva el servicio de autenticación y usuarios anterior, endureciendo token, ID y entradas. ApiException transporta un mensaje legible. hasInternetConnection realiza la comprobación de DNS previa heredada. roleFromId implementa la política de roles académicos. authenticate valida entradas, obtiene el token, busca al usuario y crea SessionData. _login configura POST y JSON, aplica un plazo de 15 segundos y distingue credenciales inválidas de errores de red. getUsers pide GET /users, verifica que sea una lista y entrega mapas a la pantalla administrativa. El antiguo getProducts sin modelo fue retirado a favor del repositorio tipado.

## lib/services/session_service.dart

SessionService encapsula FlutterSecureStorage. saveSession escribe token, ID, usuario y rol con claves estables para conservar compatibilidad. loadSession lee esos datos, comprueba campos, convierte el ID y reconoce el enum; una sesión incompleta no concede acceso. clearSession elimina todas sus claves. Este servicio no consulta roles en Fake Store.

## lib/services/product_repository.dart

StoreException presenta fallos de consulta. ProductRepository es el contrato de lectura, categorías, detalle, actualización, eliminación y liberación. HttpProductRepository admite un http.Client y un lector de sesión inyectados para pruebas. _request crea una Uri con segmentos para codificar categorías, configura encabezados, usa un plazo de 15 segundos y convierte errores de transporte/formato en mensajes. _parse normaliza errores del modelo. products distingue catálogo y filtro, mapea cada Product y verifica consistencia de categoría. categories elimina duplicados y rechaza elementos vacíos. detail valida el ID y la identidad recibida. _requireAdmin vuelve a leer el perfil local. update valida permiso y campos antes de PUT; delete verifica permiso y confirmación por ID después de DELETE. close libera el cliente HTTP.

## lib/state/catalog_controller.dart

CatalogController hereda ChangeNotifier y conserva listas, filtro, errores y cargas privados. Los getters exponen datos para dibujar; las listas se entregan sin permitir modificaciones externas. loadCategories carga categorías por separado y evita duplicar esa petición. load incrementa un número de generación, vacía productos y activa el indicador antes de consultar. Solo publica el resultado si corresponde a la generación vigente. finally detiene la carga tanto en éxito como en error. _emit evita notificar tras dispose; dispose invalida peticiones pendientes antes de liberar el observador.

## lib/state/cart_state.dart

CartState mantiene una lista privada de IDs. count expone el total; add acepta únicamente IDs positivos; clear la vacía al salir. Es un contador local heredado, sin compra ni persistencia remota.

## lib/widgets/product_image.dart

ProductImage es un componente reutilizable. Recibe URL, etiqueta accesible y tamaño. Image.network realiza la descarga fuera del dibujo síncrono; loadingBuilder muestra progreso y errorBuilder un icono de sustitución. Una URL vacía utiliza el sustituto directamente. cacheWidth limita el tamaño de decodificación y fit conserva proporciones.

## lib/screens/login_screen.dart

LoginScreen administra dos controladores de texto y una bandera de carga. _login impide doble envío, rechaza espacios/vacíos, llama authenticate y guarda la sesión. _destination abre CatalogScreen. Antes de navegar después de un await verifica mounted. finally devuelve el botón a su estado normal; dispose libera los controladores. build contiene la tarjeta de acceso, mensajes y cuentas de demostración heredadas.

## lib/screens/catalog_screen.dart

CatalogScreen compone repositorio y controlador. initState lanza ambas lecturas; dispose libera estado y cliente. _logout elimina sesión y carrito antes de reemplazar todas las rutas. AnimatedBuilder escucha cambios del controlador. ChoiceChip permite elegir o desactivar categorías y Ver todos representa null. La zona central alterna carga, error, vacío y ListView.builder. Cada fila tiene imagen, categoría, título, precio y enlace al detalle. Cliente conserva Agregar; Administrador dispone de Usuarios. El resultado true del detalle solicita recargar el catálogo general tras fallo o eliminación.

## lib/screens/product_detail_screen.dart

ProductDetailScreen recibe únicamente ID y contrato de repositorio. _load lee sesión local y después obtiene el detalle por endpoint; cualquier fallo muestra un SnackBar y devuelve true al catálogo. build muestra información y, mediante if(_admin), construye los controles de gestión solo cuando procede. _edit abre el formulario y usa la respuesta temporal recibida. _delete pide confirmación, bloquea doble interacción, envía DELETE y comunica su naturaleza simulada. Los guardas mounted evitan actualizaciones después de salir.

## lib/screens/product_edit_screen.dart

ProductEditScreen precarga los valores del producto y carga categorías vigentes. Los TextEditingController se liberan en dispose. _loadCategories soporta reintento si falla. _save comprueba Form.validate, construye un Product, llama update y devuelve la respuesta al detalle. El formulario asocia una regla a cada campo, usa selección de categoría en lugar de texto libre y no permite guardar durante otra petición. PopScope impide abandonar durante el envío; errores de red permanecen visibles y no borran lo escrito.

## lib/screens/admin_screen.dart

Conserva la consulta administrativa de usuarios del proyecto anterior, accesible desde el catálogo del Administrador. initState prepara getUsers; _reload recrea la consulta; _logout limpia sesión y carrito. FutureBuilder representa espera, error y datos. ListView.separated crea una fila por usuario y muestra el rol local correspondiente. No incorpora altas, edición ni eliminación de usuarios.

## lib/screens/client_screen.dart

Adaptador de compatibilidad. Conserva el nombre ClientScreen para referencias anteriores y delega el dibujo al catálogo común, recibiendo la sesión sin alterarla.

## lib/screens/auditor_screen.dart

Adaptador equivalente para Auditor. Usa el catálogo compartido; los controles se derivan del perfil guardado y las escrituras también se bloquean en el repositorio.

## test/store_test.dart

Pruebas unitarias de JSON, datos opcionales, reglas, rutas, errores, permisos y carreras entre peticiones. MockClient intercepta HTTP sin red. FakeRepository controla cuándo completa cada solicitud. Las pruebas de widgets guardan sesiones de prueba, montan el detalle y verifican presencia/ausencia de acciones por rol y regreso automático ante fallo. No son pruebas sobre datos reales del servidor.


## Archivos de configuración y recursos

El README es el punto de entrada. docs/GUIA_COMPLETA.html reúne requisitos, explicación y anexos en un archivo que se abre sin Internet. docs/ARQUITECTURA_Y_REQUISITOS.md explica decisiones y criterios; docs/CODIGO_EXPLICADO.md explica cada archivo de aplicación. docs/VERIFICACION.md separa comprobaciones reales y pendientes. docs/historias contiene transcripciones de los documentos recibidos.

Los manifests Android declaran permiso INTERNET, pantalla de arranque, nombre y actividades internas no exportadas. ACCESS_NETWORK_STATE en Kotlin permite la comprobación heredada de conectividad. allowBackup=false evita restaurar sesiones cifradas en otro dispositivo. Los estilos definen temas y colores; los layouts XML restantes de Kotlin corresponden al acceso y la consulta administrativa heredados. Las nuevas pantallas Android se construyen en Kotlin para mantener toda la lógica de presentación explicada junto a sus componentes.

Los archivos build.gradle.kts describen plugin, namespace, SDK, versión, dependencias y opciones de compilación. settings.gradle.kts registra repositorios y módulos; en Flutter localiza también su SDK. gradle.properties configura AndroidX y memoria. gradle-wrapper.properties fija la distribución de Gradle; gradlew, gradlew.bat y gradle-wrapper.jar la inician. El wrapper es infraestructura generada, no lógica de negocio.

En Flutter pubspec.yaml declara dependencias, versión y recursos; pubspec.lock fija las versiones resueltas; analysis_options.yaml activa reglas del analizador. MainActivity.kt del contenedor Flutter hereda FlutterActivity y deja renderizado y lógica a Dart. GeneratedPluginRegistrant.java es registro generado de plugins; Flutter puede recrearlo. .gitignore evita incorporar cachés, APK, carpetas de IDE y rutas personales.

El anexo HTML presenta el código de aplicación y sus archivos de configuración completos con números de línea. La explicación se organiza por clase, método y bloque funcional: imports reúnen dependencias, constructores fijan colaboradores, campos conservan estado, métodos aplican comportamiento y callbacks conectan acciones del usuario. Los números corresponden a los archivos de esta entrega, no al ZIP previo.
