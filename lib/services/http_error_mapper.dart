/// Traduce códigos de respuesta HTTP a mensajes visibles y comprobables.
abstract final class HttpErrorMapper {
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
