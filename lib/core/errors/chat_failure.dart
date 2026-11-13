/// Error del chat de una incidencia (HU-5.1), con un mensaje listo para
/// mostrarse.
class ChatFailure implements Exception {
  const ChatFailure(this.message);

  final String message;

  static const loadFailed = ChatFailure(
    'No se pudieron cargar los mensajes. Inténtalo de nuevo.',
  );
  static const offline = ChatFailure(
    'No hay conexión a internet. Revisa tu conexión e inténtalo de nuevo.',
  );
  static const sendFailed = ChatFailure(
    'No se pudo enviar el mensaje. Inténtalo de nuevo.',
  );

  @override
  String toString() => message;
}
