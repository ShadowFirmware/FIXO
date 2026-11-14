import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/chat_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/domain/entities/app_user.dart';
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
    DateTime Function()? clock,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? ChatRepositoryImpl(),
       _clock = clock ?? DateTime.now {
    load();
  }

  /// Incidencia a la que pertenece el chat.
  final String incidentId;

  final AuthSession _session;
  final ChatRepository _repository;
  final DateTime Function() _clock;
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
  static const noMessagesReadOnlyMessage =
      'No se enviaron mensajes en esta incidencia.';

  /// `true` si [message] lo envió el usuario en sesión.
  bool isMine(ChatMessage message) =>
      message.authorId == _session.currentUser?.uid;

  /// Quién envió [message], por ejemplo "Juan Pérez · Técnico". Usa el
  /// nombre guardado en el mensaje, así se conserva aunque la persona ya no
  /// participe en la incidencia.
  static String authorLabel(ChatMessage message) {
    final role = switch (message.authorRole) {
      UserRole.technician => 'Técnico',
      UserRole.resident => 'Residente',
      UserRole.admin => 'Administrador',
    };
    final name = message.authorName;
    return name.isEmpty ? role : '$name · $role';
  }

  /// Día del mensaje en [index]. Uno que se está enviando cuenta como de hoy.
  DateTime _dayOf(int index) {
    final date = (_messages[index].sentAt ?? _clock()).toLocal();
    return DateTime(date.year, date.month, date.day);
  }

  /// Etiqueta del día si el mensaje en [index] es el primero de ese día, o
  /// `null` si es del mismo día que el anterior.
  String? dayLabelAt(int index) {
    final day = _dayOf(index);
    if (index > 0 && _dayOf(index - 1) == day) return null;
    return dayLabel(day, _clock());
  }

  /// "Hoy", "Ayer" o la fecha, por ejemplo "9 de octubre de 2026".
  static String dayLabel(DateTime day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(day.year, day.month, day.day);
    final difference = today.difference(date).inHours;
    // En horas redondeadas, por los cambios de horario.
    return switch ((difference / 24).round()) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ => DateFormats.longDate(date),
    };
  }

  /// Hora del mensaje, o vacío si se está enviando.
  static String timeLabel(ChatMessage message) => switch (message.sentAt) {
    final sentAt? => DateFormats.time(sentAt.toLocal()),
    null => '',
  };

  ChatContext? _context;

  /// Incidencia del chat, o `null` mientras carga.
  Incident? get incident => _context?.incident;

  static const notFoundMessage = 'No se encontró la incidencia.';

  StreamSubscription<ChatContext?>? _contextSubscription;

  /// Escucha la incidencia y su vivienda. Con cada cambio se vuelve a
  /// revisar el acceso, así el chat se abre o se cierra en cuanto cambia el
  /// residente de la vivienda o el técnico asignado.
  void load() {
    _contextSubscription?.cancel();
    _stopMessages();
    _state = ChatState.loading;
    _errorMessage = null;
    _notify();
    _contextSubscription = _repository
        .watchContext(incidentId)
        .listen(_onContext, onError: _onError);
  }

  ChatAccess _access = const ChatAccess.denied(ChatAccess.notAllowed);

  /// Puede enviar mensajes. Si no, el chat es de solo lectura y
  /// [readOnlyReason] dice por qué.
  bool get canWrite => _access.canWrite;

  /// Por qué el chat es de solo lectura, o `null` si se puede escribir.
  String? get readOnlyReason =>
      _access.canRead && !_access.canWrite ? _access.reason : null;

  void _onContext(ChatContext? context) {
    _context = context;
    // Antes de mostrar los mensajes se revisa que el usuario pueda verlos.
    final access = _access = context == null
        ? const ChatAccess.denied(notFoundMessage)
        : ChatAccess.of(_session.currentUser, context);
    if (!access.canRead) {
      _stopMessages();
      _messages = const [];
      _errorMessage = access.reason;
      _state = ChatState.denied;
      _notify();
      return;
    }
    // Ya tenía acceso: los mensajes siguen llegando por el mismo stream.
    if (_subscription == null) {
      _state = ChatState.loading;
      _errorMessage = null;
      _listen();
    }
    _notify();
  }

  void _onError(Object error) {
    _stopMessages();
    _errorMessage = error is ChatFailure
        ? error.message
        : ChatFailure.loadFailed.message;
    _state = ChatState.error;
    _notify();
  }

  void _stopMessages() {
    _subscription?.cancel();
    _subscription = null;
  }

  StreamSubscription<List<ChatMessage>>? _subscription;

  /// Escucha los mensajes: el chat queda listo con la primera lista y se
  /// actualiza con cada mensaje nuevo, de quien sea.
  void _listen() {
    _subscription?.cancel();
    _subscription = _repository.watchMessages(incidentId).listen((messages) {
      _messages = List.unmodifiable(messages);
      _state = ChatState.ready;
      _errorMessage = null;
      _notify();
    }, onError: _onError);
  }

  bool _sending = false;
  bool get isSending => _sending;

  /// Envía [text]. Devuelve el mensaje de error, o `null` si se envió.
  Future<String?> send(String text) async {
    if (_sending || _state != ChatState.ready) return null;
    if (!canWrite) return _access.reason ?? ChatAccess.notAllowed;
    final invalid = ChatMessage.validate(text);
    if (invalid != null) return invalid;
    final author = _session.currentUser;
    if (author == null) return ChatAccess.notAllowed;

    _sending = true;
    _notify();
    try {
      await _repository.send(
        incidentId: incidentId,
        authorId: author.uid,
        text: text.trim(),
      );
      // El mensaje aparece por el stream; no hace falta volver a consultar.
      return null;
    } on ChatFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return ChatFailure.sendFailed.message;
    } finally {
      _sending = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _contextSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
