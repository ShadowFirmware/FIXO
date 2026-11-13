import 'package:flutter/foundation.dart';

enum ChatState { loading, ready, denied, error }

/// ViewModel del chat de una incidencia (HU-5.1).
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({required this.incidentId});

  /// Incidencia a la que pertenece el chat.
  final String incidentId;

  ChatState _state = ChatState.ready;
  ChatState get state => _state;

  static const noMessagesMessage =
      'Aún no hay mensajes. Escribe para aclarar dudas sobre la incidencia.';

  @protected
  set state(ChatState value) {
    _state = value;
    notifyListeners();
  }
}
