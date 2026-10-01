// GUÍA DEL ARCHIVO: Traducción de códigos HTTP a mensajes. El parámetro login distingue credenciales incorrectas de errores generales. Este archivo no hace peticiones ni guarda estado.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

/// Traduce códigos de respuesta HTTP a mensajes visibles y comprobables.
abstract final class HttpErrorMapper {
  /// Traduce código HTTP a mensaje visible; login distingue un fallo de credenciales de errores generales.
  static String message(int code, {bool login = false}) {
    if (code == 400 || code == 401) {
      return login
          ? 'Usuario o contraseña inválidos (HTTP $code).'
          : 'Solicitud o acceso no válido (HTTP $code).';
    }
    if (code == 403) return 'Acceso rechazado por el servicio (HTTP 403).';
    if (code == 404) return 'Producto no disponible (HTTP 404).';
    if (code == 408 || code == 504) {
      return 'El servicio tardó demasiado (HTTP $code). Reintenta.';
    }
    if (code == 429) {
      return 'Demasiadas solicitudes (HTTP 429). Espera y reintenta.';
    }
    if (code >= 500 && code <= 599) {
      return 'El servicio no está disponible (HTTP $code). Reintenta.';
    }
    return 'No se pudo completar la consulta (HTTP $code).';
  }
}
