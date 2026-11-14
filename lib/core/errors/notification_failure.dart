/// Error de los avisos (HU-6.1), con un mensaje listo para mostrarse.
class NotificationFailure implements Exception {
  const NotificationFailure(this.message);

  final String message;

  static const loadFailed = NotificationFailure(
    'No se pudieron cargar tus avisos. Inténtalo de nuevo.',
  );
  static const updateFailed = NotificationFailure(
    'No se pudieron marcar los avisos como leídos. Inténtalo de nuevo.',
  );
  static const offline = NotificationFailure(
    'No hay conexión a internet. Revisa tu conexión e inténtalo de nuevo.',
  );

  @override
  String toString() => message;
}
