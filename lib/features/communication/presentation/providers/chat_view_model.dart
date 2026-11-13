import 'package:flutter/foundation.dart';

import '../../../../core/errors/chat_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_access.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

enum ChatState { loading, ready, denied, error }

/// ViewModel del chat de una incidencia (HU-5.1).
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required this.incidentId,
    AuthSession? session,
    ChatRepository? repository,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? ChatRepositoryImpl() {
    load();
  }

  /// Incidencia a la que pertenece el chat.
  final String incidentId;

  final AuthSession _session;
  final ChatRepository _repository;
  bool _disposed = false;

  ChatState _state = ChatState.loading;
  ChatState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ChatMessage> _messages = const [];

  /// Mensajes del más antiguo al más reciente.
  List<ChatMessage> get messages => _messages;

  static const noMessagesMessage =
      'Aún no hay mensajes. Escribe para aclarar dudas sobre la incidencia.';

  /// `true` si [message] lo envió el usuario en sesión.
  bool isMine(ChatMessage message) =>
      message.authorId == _session.currentUser?.uid;

  ChatContext? _context;

  /// Incidencia del chat, o `null` mientras carga.
  Incident? get incident => _context?.incident;

  static const notFoundMessage = 'No se encontró la incidencia.';

  Future<void> load() async {
    _state = ChatState.loading;
    _errorMessage = null;
    _notify();
    try {
      final context = _context = await _repository.context(incidentId);
      // Antes de mostrar los mensajes se revisa que el usuario pueda verlos.
      final access = context == null
          ? const ChatAccess.denied(notFoundMessage)
          : ChatAccess.of(_session.currentUser, context);
      if (!access.canRead) {
        _messages = const [];
        _errorMessage = access.reason;
        _state = ChatState.denied;
        _notify();
        return;
      }
      _messages = List.unmodifiable(await _repository.messages(incidentId));
      _state = ChatState.ready;
    } on ChatFailure catch (failure) {
      _errorMessage = failure.message;
      _state = ChatState.error;
    } catch (_) {
      _errorMessage = ChatFailure.loadFailed.message;
      _state = ChatState.error;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
