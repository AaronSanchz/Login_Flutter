# Fake Store US03 US04 y US05

Esta entrega continúa los proyectos recibidos de Flutter/Dart y Kotlin/Android. Conserva el inicio de sesión con Fake Store, la sesión local, la asignación de perfiles, la consulta de usuarios del Administrador y el contador local del carrito. Añade un catálogo común a los tres roles, categorías remotas y detalle con gestión condicionada por el perfil de sesión.

## Alcance y decisiones

El servicio es https://fakestoreapi.com. Las lecturas no requieren un token de autorización de Fake Store, pero la aplicación exige una sesión local para entrar al catálogo. Se conserva la política académica previa: IDs 1 y 2 son Administrador; ID 3 es Auditor; los demás son Cliente. La política se aplica al iniciar sesión y se almacena; el detalle consulta ese valor almacenado y no vuelve a pedir un rol a la API.

US05 incluye una inconsistencia textual: en su escenario administrativo dice «Cuando selecciona una categoría específica», aunque el objetivo y las demás condiciones hablan del detalle. La implementación habilita Editar y Eliminar al abrir cualquier detalle con sesión Administrador, independientemente del filtro. Así se mantiene la coherencia con el objetivo de la historia.

Editar envía PUT /products/{id}; eliminar envía DELETE /products/{id}, con confirmación previa. Fake Store responde de forma simulada y no persiste esas operaciones. Tras editar se presenta la respuesta en el detalle actual; al volver a consultar puede aparecer el contenido original. Tras eliminar se confirma la respuesta y se vuelve al catálogo general; el producto puede seguir apareciendo. La interfaz lo explica y no afirma que se borró permanentemente. No se mantiene una base de datos paralela que contradiga futuras consultas GET.

La protección local de roles cumple la regla académica de la historia; una aplicación de producción necesitaría autorización en un servidor propio. Esta entrega no añade registro, pago, pedidos, eliminación de usuarios ni un carrito remoto. El contador del carrito conserva el alcance del código anterior y se limpia al cerrar sesión.

## Matriz de requisitos

| Historia y escenario | Comportamiento implementado | Evidencia principal |
|---|---|---|
| US03 catálogo correcto | GET /products; imagen, título y precio por fila | Modelo Product y lista reciclable |
| US03 carga | Indicador central durante la petición; sin datos anteriores | Estado loading y arreglo vacío |
| US03 error | Mensaje comprensible y Reintentar | Manejo de error de repositorio y estado |
| US04 categorías | GET /products/categories al iniciar | Carga independiente de categorías |
| US04 filtro | GET /products/category/{category} codificando el segmento | Repositorio; pruebas de rutas |
| US04 quitar filtro | Ver todos o desactivar selección consulta GET /products | Método load con categoría nula |
| US05 Cliente y Auditor | Imagen, título, precio, descripción y categoría | Detalle con sesión local |
| US05 Administrador | Editar y Eliminar funcionales con validaciones y confirmación | PUT y DELETE protegidos en el repositorio |
| US05 fallo o inexistencia | Aviso Producto no disponible y retorno automático al catálogo general | Navegación de resultado y nueva consulta sin filtro |

Las filas se construyen bajo demanda con ListView.builder en Flutter y RecyclerView en Android. Las imágenes se descargan mediante Image.network o Glide; tienen marcador de carga y sustituto de error. Las categorías se muestran en una franja horizontal que no tapa los productos. Los fallos de categorías permiten reintentar sin inutilizar el catálogo general.

## Flujo completo

1. El arranque consulta la sesión local; si falta o es inválida abre el acceso.
2. El acceso valida usuario y contraseña antes de enviar POST /auth/login. Obtiene el usuario y asigna el rol local según la política heredada.
3. El catálogo inicia GET de productos y categorías por separado.
4. Elegir un filtro borra la lista anterior, activa la carga y consulta la categoría codificada. Una respuesta antigua no puede reemplazar una selección más reciente.
5. Tocar un producto envía GET /products/{id}; no utiliza únicamente el resumen de la lista.
6. El detalle lee el perfil de sesión. Solo crea botones de gestión para Administrador. El repositorio vuelve a comprobar el perfil antes de una escritura, aunque alguien eluda la pantalla.
7. El editor valida cada campo, bloquea envíos duplicados, comunica un error recuperable y conserva los datos del formulario si la operación falla.
8. Cerrar sesión elimina sus valores y vacía el contador del carrito.

## Validaciones y errores

| Dato o situación | Regla y respuesta |
|---|---|
| Usuario y contraseña | No vacíos ni solo espacios; límites de 100 y 256 caracteres; la contraseña se envía sin recortar su contenido |
| Sesión | Token y nombre no vacíos, ID positivo, rol reconocido; una sesión no válida no concede acceso |
| Producto remoto | ID entero positivo; título, descripción y categoría de tipo texto no vacíos; precio numérico finito y no negativo |
| Imagen remota ausente o inválida | Se conserva el producto y se muestra un sustituto de imagen |
| Rating opcional | Puntuación de 0 a 5, conteo entero no negativo; valores inválidos se omiten |
| Título editado | Obligatorio; hasta 200 caracteres después de recortar bordes |
| Descripción editada | Obligatoria; hasta 5000 caracteres |
| Precio editado | Mayor que cero, hasta 1000000, máximo dos decimales en el formulario; acepta punto o coma decimal, sin separadores de miles |
| Imagen editada | URL HTTPS con host y sin usuario/contraseña incrustados |
| Categoría editada | Selección perteneciente a la lista descargada; no texto libre ni valor vacío |
| Red | Tiempo de conexión/lectura limitado; estados HTTP fuera de 2xx se tratan como error |
| Cuerpo HTTP | Vacío, null, JSON mal formado o estructura incorrecta no se convierten en un éxito falso |
| Detalle | ID de respuesta distinto al solicitado o consulta fallida genera Producto no disponible |
| Lista vacía | Estado vacío explícito; no se confunde con un error de conexión |
| Permisos | Cliente, Auditor y sesión ausente no pueden ejecutar PUT/DELETE |
| Cambio de filtro rápido | Limpieza previa y descarte de respuesta obsoleta |

Los límites de edición son decisiones de validación de esta entrega; las historias no fijan longitudes máximas ni moneda. El signo $ conserva la presentación anterior, sin afirmar una moneda o conversión que la API no declara.

## Programación orientada a objetos

**Encapsulación.** Product contiene datos inmutables; los servicios controlan sus clientes y acceso a sesión; el estado de catálogo expone lectura a la UI y cambia por métodos explícitos. CartState mantiene su colección privada. Se impide añadir IDs inválidos.

**Abstracción.** ProductRepository declara operaciones de negocio sin obligar a conocer HTTP. La pantalla utiliza el contrato; HttpProductRepository conoce endpoints, JSON y permisos. ProductRules separa las reglas del formulario.

**Polimorfismo.** HttpProductRepository y los repositorios falsos de las pruebas implementan el mismo contrato. La lógica de catálogo funciona con cualquiera. En Kotlin StoreTransport permite sustituir las llamadas HTTP y verificar rutas y métodos sin Internet.

**Herencia.** Se utiliza donde el framework lo exige: StatefulWidget/StatelessWidget y ChangeNotifier en Flutter; AppCompatActivity, ViewModel y RecyclerView.Adapter en Android. No se crean cadenas artificiales de herencia entre roles. Se usa composición para servicios y permisos.

**Responsabilidades.** El modelo valida la forma de los datos, el repositorio comunica con la API, el controlador/ViewModel representa el estado y la pantalla decide cómo mostrarlo. El editor reúne entradas; el repositorio comprueba nuevamente permiso y validez antes de enviarlas.

## Pruebas manuales de aceptación

| Caso | Pasos | Resultado esperado |
|---|---|---|
| Acceso inválido | Dejar ambos campos vacíos; después escribir espacios | Mensaje sin petición de autenticación |
| Catálogo | Acceder con cada perfil | Carga y luego imagen, título, precio en cada fila |
| Filtro remoto | Seleccionar cada categoría; cambiar rápidamente entre dos | Solo productos del último filtro; indicador y limpieza entre peticiones |
| Restablecer | Elegir Ver todos | GET general y lista completa |
| Sin conexión | Desactivar Internet y actualizar; restaurar y Reintentar | Error amigable; después recuperación |
| Imagen fallida | Probar una respuesta con URL que no resuelva | Sustituto sin caída de aplicación |
| Detalle | Abrir un producto | GET por ID y descripción completa |
| Permisos | Abrir detalle como Cliente y Auditor | No existen botones Editar ni Eliminar |
| Editar | Entrar como Administrador; vaciar título; precio negativo; URL inválida | Campos señalados y no se envía PUT |
| Editar válido | Corregir todos los campos y guardar | Respuesta visible y aviso de simulación |
| Eliminar | Cancelar; después confirmar | Cancelar no envía DELETE; confirmar comunica simulación y vuelve al catálogo |
| Inexistente | Usar un doble de repositorio con 404/null o ID distinto | Aviso y retorno automático sin filtro |
| Ciclo de vida | Rotar Android durante carga; salir de detalle mientras carga | Sin actualizar una pantalla destruida ni sobrescribir el estado vigente |
| Cierre | Agregar al carrito como Cliente y cerrar sesión | Sesión eliminada y contador restablecido |

Estas pruebas manuales son una guía reproducible, no una afirmación de que se ejecutaron todas en un dispositivo físico. El informe de verificación distingue lo ejecutado de lo pendiente.

## Fuentes

- Historias US03, US04 y US05 proporcionadas por el usuario, transcritas en docs/historias.
- Fake Store API y límites de persistencia: https://github.com/keikaavousi/fake-store-api
- Listas Flutter: https://docs.flutter.dev/cookbook/lists/long-lists
- RecyclerView Android: https://developer.android.com/develop/ui/views/layout/recyclerview
