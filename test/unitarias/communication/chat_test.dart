import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/chat_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/communication/data/datasources/chat_remote_data_source.dart';
import 'package:fixo/features/communication/data/models/chat_message_model.dart';
import 'package:fixo/features/communication/data/repositories/chat_repository_impl.dart';
import 'package:fixo/features/communication/domain/entities/chat_access.dart';
import 'package:fixo/features/communication/domain/entities/chat_message.dart';
import 'package:fixo/features/communication/presentation/providers/chat_view_model.dart';
import 'package:fixo/features/communication/presentation/screens/incident_chat_screen.dart';
import 'package:fixo/features/communication/presentation/widgets/chat_widgets.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../technician/assigned_incidents_fakes.dart';
import 'chat_fakes.dart';

/// HU-5.1 Comunicarse mediante chat dentro de una incidencia: mensajes,
/// acceso, envío, tiempo real, historial y modo de solo lectura.
void main() {
  final now = DateTime(2026, 11, 12, 10);

  /// Deja que lleguen los eventos de los streams.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  AuthSession sessionOf(UserModel user) =>
      AuthSession.withRepository(FakeAuthRepository())..start(user);

  late FakeChatRepository repository;

  setUp(() => repository = FakeChatRepository());
  tearDown(() => repository.close());

  ChatViewModel viewModelFor(UserModel user) {
    final viewModel = ChatViewModel(
      incidentId: 'inc-1',
      session: sessionOf(user),
      repository: repository,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('mensajes (T 5.1.2)', () {
    test('PU-602 valida el texto antes de enviarlo', () {
      expect(ChatMessage.validate(''), 'Escribe un mensaje');
      expect(ChatMessage.validate('   \n '), 'Escribe un mensaje');
      expect(ChatMessage.validate('¿A qué hora llega?'), isNull);
      expect(ChatMessage.validate('a' * ChatMessage.maxLength), isNull);
      // Los espacios de los extremos no cuentan.
      expect(
        ChatMessage.validate('  ${'a' * ChatMessage.maxLength}  '),
        isNull,
      );
      expect(
        ChatMessage.validate('a' * (ChatMessage.maxLength + 1)),
        'El mensaje no debe pasar de 1000 caracteres',
      );
    });

    test('PU-603 lee y crea los documentos de mensajes', () {
      final sentAt = DateTime(2026, 11, 12, 9, 30);
      final message = ChatMessageModel.fromMap('m1', 'inc-1', {
        'autorId': technicianUid,
        'autorNombre': ' Juan Pérez Ramírez ',
        'autorRol': 'tecnico',
        'texto': 'Llego en 10 minutos.',
        'fecha': Timestamp.fromDate(sentAt),
      });
      expect(message.id, 'm1');
      expect(message.incidentId, 'inc-1');
      expect(message.authorId, technicianUid);
      expect(message.authorName, 'Juan Pérez Ramírez');
      expect(message.authorRole, UserRole.technician);
      expect(message.text, 'Llego en 10 minutos.');
      expect(message.sentAt, sentAt);
      expect(message.isPending, isFalse);

      // Mientras no llega al servidor, no tiene fecha.
      final pending = ChatMessageModel.fromMap('m2', 'inc-1', {
        'autorId': residentUid,
        'autorRol': 'residente',
        'texto': 'Gracias',
      });
      expect(pending.isPending, isTrue);
      expect(pending.authorName, '');

      for (final invalid in [
        {'autorRol': 'residente', 'texto': 'Hola'},
        {'autorId': residentUid, 'autorRol': 'otro', 'texto': 'Hola'},
        {'autorId': residentUid, 'autorRol': 'residente', 'texto': '  '},
      ]) {
        expect(
          () => ChatMessageModel.fromMap('x', 'inc-1', invalid),
          throwsFormatException,
        );
      }

      final data = ChatMessageModel.newMessage(
        authorId: residentUid,
        authorName: ' María López Hernández ',
        authorRole: UserRole.resident,
        text: '  ¿Ya viene?  ',
      );
      expect(data['autorId'], residentUid);
      expect(data['autorNombre'], 'María López Hernández');
      expect(data['autorRol'], 'residente');
      expect(data['texto'], '¿Ya viene?');
      expect(data['fecha'], isA<FieldValue>());
    });
  });

  group('acceso (T 5.1.4, T 5.1.9, T 5.1.10)', () {
    test('PU-604 solo el técnico asignado y el residente activo de la '
        'vivienda pueden ver el chat', () {
      final context = chatContext();

      expect(ChatAccess.of(TestUsers.technician, context).canRead, isTrue);
      expect(ChatAccess.of(TestUsers.resident(), context).canRead, isTrue);
      expect(ChatAccess.of(TestUsers.resident(), context).canWrite, isTrue);

      final otherTechnician = ChatAccess.of(
        TestUsers.technician,
        chatContext(incident: chatIncident(technician: 'uid-otro')),
      );
      expect(otherTechnician.canRead, isFalse);
      expect(otherTechnician.reason, ChatAccess.notAssignedTechnician);

      final admin = ChatAccess.of(TestUsers.admin, context);
      expect(admin.canRead, isFalse);
      expect(admin.reason, ChatAccess.notAllowed);

      expect(ChatAccess.of(null, context).canRead, isFalse);
      for (final status in [
        AccountStatus.suspended,
        AccountStatus.disabled,
        AccountStatus.removed,
      ]) {
        final access = ChatAccess.of(
          TestUsers.resident(status: status),
          context,
        );
        expect(access.canRead, isFalse, reason: status.name);
        expect(access.reason, ChatAccess.notAllowed);
      }
    });

    test('PU-605 si cambia el residente de la vivienda, el nuevo usa el chat '
        'y el anterior lo pierde', () {
      final changed = chatContext(resident: 'uid-nuevo');
      final previous = ChatAccess.of(TestUsers.resident(), changed);
      expect(previous.canRead, isFalse);
      expect(previous.reason, ChatAccess.notActiveResident);

      // No depende de quién registró la incidencia.
      final newResident = UserModel(
        uid: 'uid-nuevo',
        name: 'Pedro Ruiz',
        email: 'pedro@correo.com',
        phone: '7779998877',
        role: UserRole.resident,
        accountStatus: AccountStatus.active,
        housingId: 'vivienda-4b',
      );
      expect(ChatAccess.of(newResident, changed).canWrite, isTrue);

      // Vivienda sin residente activo (por ejemplo, tras darlo de baja).
      expect(
        ChatAccess.of(
          TestUsers.resident(),
          chatContext(resident: null),
        ).canRead,
        isFalse,
      );
    });

    test('PU-606 el chat es de solo lectura si la incidencia terminó o aún '
        'no tiene técnico', () {
      void expectReadOnly(ChatContext context, String reason) {
        for (final user in [TestUsers.resident(), TestUsers.technician]) {
          final access = ChatAccess.of(user, context);
          if (user.role == UserRole.technician &&
              context.incident.technicianId != technicianUid) {
            continue;
          }
          expect(access.canRead, isTrue);
          expect(access.canWrite, isFalse);
          expect(access.reason, reason);
        }
      }

      expectReadOnly(
        chatContext(incident: chatIncident(status: IncidentStatus.resolved)),
        ChatAccess.resolvedReadOnly,
      );
      expectReadOnly(
        chatContext(incident: chatIncident(chatClosed: true)),
        ChatAccess.resolvedReadOnly,
      );
      expectReadOnly(
        chatContext(incident: chatIncident(status: IncidentStatus.rejected)),
        ChatAccess.rejectedReadOnly,
      );
      expectReadOnly(
        chatContext(
          incident: chatIncident(
            status: IncidentStatus.pending,
            technician: null,
          ),
        ),
        ChatAccess.waitingTechnician,
      );

      for (final status in [
        IncidentStatus.assigned,
        IncidentStatus.inProgress,
      ]) {
        final context = chatContext(incident: chatIncident(status: status));
        expect(ChatAccess.of(TestUsers.technician, context).canWrite, isTrue);
        expect(ChatAccess.of(TestUsers.resident(), context).canWrite, isTrue);
      }
    });
  });

  group('ViewModel', () {
    test('PU-607 revisa el acceso antes de consultar los mensajes', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      expect(viewModel.state, ChatState.loading);
      expect(repository.contextListens, 1);

      repository.contextController.add(chatContext(resident: 'uid-otro'));
      await flush();
      expect(viewModel.state, ChatState.denied);
      expect(viewModel.errorMessage, ChatAccess.notActiveResident);
      // Sin acceso, ni siquiera se consultan los mensajes.
      expect(repository.messageListens, 0);

      repository.contextController.add(null);
      await flush();
      expect(viewModel.state, ChatState.denied);
      expect(viewModel.errorMessage, ChatViewModel.notFoundMessage);
    });

    test('PU-608 recibe los mensajes en tiempo real', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      repository.contextController.add(chatContext());
      await flush();
      expect(repository.messageListens, 1);
      expect(viewModel.state, ChatState.loading);
      expect(viewModel.incident?.reportNumber, 'INC-0001');

      repository.messagesController.add(const []);
      await flush();
      expect(viewModel.state, ChatState.ready);
      expect(viewModel.messages, isEmpty);

      // Llega un mensaje del técnico y luego otro del residente.
      final first = chatMessage(
        'm1',
        authorId: technicianUid,
        authorRole: UserRole.technician,
        sentAt: now,
      );
      repository.messagesController.add([first]);
      await flush();
      expect(viewModel.messages.map((m) => m.id), ['m1']);
      expect(viewModel.isMine(first), isFalse);

      final second = chatMessage('m2', sentAt: now);
      repository.messagesController.add([first, second]);
      await flush();
      expect(viewModel.messages.map((m) => m.id), ['m1', 'm2']);
      expect(viewModel.isMine(second), isTrue);

      // Un cambio en la incidencia no vuelve a abrir el stream de mensajes.
      repository.contextController.add(chatContext());
      await flush();
      expect(repository.messageListens, 1);
      expect(viewModel.messages, hasLength(2));
    });

    test('PU-609 si falla, muestra el error y permite reintentar', () async {
      final viewModel = viewModelFor(TestUsers.technician);
      repository.contextController.addError(ChatFailure.offline);
      await flush();
      expect(viewModel.state, ChatState.error);
      expect(viewModel.errorMessage, ChatFailure.offline.message);

      viewModel.load();
      expect(viewModel.state, ChatState.loading);
      expect(repository.contextListens, 2);
      repository.contextController.add(chatContext());
      await flush();
      repository.messagesController.addError(StateError('sin formato'));
      await flush();
      expect(viewModel.state, ChatState.error);
      expect(viewModel.errorMessage, ChatFailure.loadFailed.message);
    });

    test('PU-610 actualiza el acceso cuando cambia el residente o el '
        'técnico', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      repository.contextController.add(chatContext());
      await flush();
      repository.messagesController.add([chatMessage('m1', sentAt: now)]);
      await flush();
      expect(viewModel.state, ChatState.ready);

      // El administrador asigna la vivienda a otro residente.
      repository.contextController.add(chatContext(resident: 'uid-nuevo'));
      await flush();
      expect(viewModel.state, ChatState.denied);
      expect(viewModel.errorMessage, ChatAccess.notActiveResident);
      expect(viewModel.messages, isEmpty);
      expect(repository.listeningMessages, isFalse);

      // Si vuelve a ser el residente activo, recupera el historial.
      repository.contextController.add(chatContext());
      await flush();
      expect(viewModel.state, ChatState.loading);
      expect(repository.messageListens, 2);
      repository.messagesController.add([chatMessage('m1', sentAt: now)]);
      await flush();
      expect(viewModel.state, ChatState.ready);
      expect(viewModel.messages, hasLength(1));

      // Al técnico que reasignan a otra incidencia le pasa lo mismo.
      final technician = viewModelFor(TestUsers.technician);
      repository.contextController.add(
        chatContext(incident: chatIncident(technician: 'uid-otro')),
      );
      await flush();
      expect(technician.state, ChatState.denied);
      expect(technician.errorMessage, ChatAccess.notAssignedTechnician);
    });

    test('PU-611 envía los mensajes del usuario en sesión', () async {
      final viewModel = viewModelFor(TestUsers.technician);
      repository.contextController.add(chatContext());
      await flush();
      repository.messagesController.add(const []);
      await flush();
      expect(viewModel.canWrite, isTrue);
      expect(viewModel.readOnlyReason, isNull);

      expect(await viewModel.send('   '), 'Escribe un mensaje');
      expect(repository.sent, isEmpty);

      repository.sendGate = Completer();
      final sending = viewModel.send('  Voy en camino.  ');
      expect(viewModel.isSending, isTrue);
      // Mientras se envía, no se manda otro.
      expect(await viewModel.send('Otro'), isNull);
      repository.sendGate!.complete();
      expect(await sending, isNull);
      expect(viewModel.isSending, isFalse);
      expect(repository.sent, [('inc-1', technicianUid, 'Voy en camino.')]);

      repository
        ..sendGate = null
        ..sendError = const ChatFailure(ChatAccess.notAssignedTechnician);
      expect(await viewModel.send('Hola'), ChatAccess.notAssignedTechnician);
      repository.sendError = StateError('falla');
      expect(await viewModel.send('Hola'), ChatFailure.sendFailed.message);
    });

    test('PU-612 en solo lectura no se envían mensajes', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      repository.contextController.add(chatContext());
      await flush();
      repository.messagesController.add([chatMessage('m1', sentAt: now)]);
      await flush();
      expect(viewModel.canWrite, isTrue);

      // El técnico finaliza la incidencia con el chat abierto.
      repository.contextController.add(
        chatContext(
          incident: chatIncident(
            status: IncidentStatus.resolved,
            chatClosed: true,
          ),
        ),
      );
      await flush();
      expect(viewModel.state, ChatState.ready);
      expect(viewModel.messages, hasLength(1));
      expect(viewModel.canWrite, isFalse);
      expect(viewModel.readOnlyReason, ChatAccess.resolvedReadOnly);
      expect(await viewModel.send('Gracias'), ChatAccess.resolvedReadOnly);
      expect(repository.sent, isEmpty);
    });

    test('PU-613 muestra quién envió cada mensaje y separa los días', () async {
      expect(
        ChatViewModel.authorLabel(
          chatMessage(
            'm1',
            authorName: 'Juan Pérez Ramírez',
            authorRole: UserRole.technician,
          ),
        ),
        'Juan Pérez Ramírez · Técnico',
      );
      expect(
        ChatViewModel.authorLabel(chatMessage('m2', authorName: '')),
        'Residente',
      );

      expect(ChatViewModel.dayLabel(DateTime(2026, 11, 12, 23), now), 'Hoy');
      expect(ChatViewModel.dayLabel(DateTime(2026, 11, 11, 1), now), 'Ayer');
      expect(
        ChatViewModel.dayLabel(DateTime(2026, 11, 9), now),
        '9 de noviembre de 2026',
      );
      // Primero de enero visto el 2 de enero.
      expect(
        ChatViewModel.dayLabel(DateTime(2026), DateTime(2026, 1, 2, 8)),
        'Ayer',
      );

      final sentAt = DateTime(2026, 11, 12, 16, 5);
      expect(
        ChatViewModel.timeLabel(chatMessage('m1', sentAt: sentAt)),
        '4:05 p. m.',
      );
      expect(ChatViewModel.timeLabel(chatMessage('m2')), '');

      final viewModel = viewModelFor(TestUsers.resident());
      repository.contextController.add(chatContext());
      await flush();
      repository.messagesController.add([
        chatMessage('m1', sentAt: DateTime(2026, 11, 10, 9)),
        chatMessage('m2', sentAt: DateTime(2026, 11, 10, 18)),
        chatMessage('m3', sentAt: DateTime(2026, 11, 12, 8)),
        // El que se está enviando cuenta como de hoy.
        chatMessage('m4'),
      ]);
      await flush();
      expect(
        [for (var i = 0; i < 4; i++) viewModel.dayLabelAt(i)],
        ['10 de noviembre de 2026', null, 'Hoy', null],
      );
    });
  });

  test('PU-614 el repositorio traduce los errores de Firestore', () async {
    final remote = FakeChatRemoteDataSource();
    final repo = ChatRepositoryImpl(remote: remote);
    FirebaseException firebase(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code);

    Future<String?> sendError(Object error) async {
      remote.sendError = error;
      try {
        await repo.send(incidentId: 'inc-1', authorId: residentUid, text: 'a');
        return null;
      } on ChatFailure catch (failure) {
        return failure.message;
      }
    }

    expect(
      await sendError(const ChatDeniedException(ChatAccess.resolvedReadOnly)),
      ChatAccess.resolvedReadOnly,
    );
    expect(
      await sendError(firebase('unavailable')),
      ChatFailure.offline.message,
    );
    expect(
      await sendError(firebase('deadline-exceeded')),
      ChatFailure.offline.message,
    );
    expect(
      await sendError(firebase('permission-denied')),
      ChatFailure.sendFailed.message,
    );

    final messages = failureOf(repo.watchMessages('inc-1'));
    remote.messagesController.addError(firebase('unavailable'));
    expect(await messages, ChatFailure.offline.message);

    final context = failureOf(repo.watchContext('inc-1'));
    remote.contextController.addError(firebase('internal'));
    expect(await context, ChatFailure.loadFailed.message);
  });

  group('pantalla (T 5.1.1)', () {
    Future<ChatViewModel> pumpChat(WidgetTester tester, UserModel user) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final viewModel = viewModelFor(user);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: IncidentChatScreen(incidentId: 'inc-1', viewModel: viewModel),
        ),
      );
      return viewModel;
    }

    testWidgets('PU-615 muestra la conversación y envía mensajes', (
      tester,
    ) async {
      await pumpChat(tester, TestUsers.resident());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.contextController.add(chatContext());
      await tester.pump();
      repository.messagesController.add(const []);
      await tester.pump();
      expect(find.text('Chat de la incidencia'), findsOneWidget);
      expect(find.text('INC-0001 · Fuga en el baño'), findsOneWidget);
      expect(find.text(ChatViewModel.noMessagesMessage), findsOneWidget);

      repository.messagesController.add([
        chatMessage(
          'm1',
          authorId: technicianUid,
          authorName: 'Juan Pérez Ramírez',
          authorRole: UserRole.technician,
          text: 'Llego a las 11.',
          sentAt: DateTime(2026, 11, 11, 16, 5),
        ),
        chatMessage('m2', text: 'Perfecto, aquí estoy.', sentAt: now),
      ]);
      await tester.pump();
      expect(find.text('Llego a las 11.'), findsOneWidget);
      expect(find.text('Juan Pérez Ramírez · Técnico'), findsOneWidget);
      expect(find.text('4:05 p. m.'), findsOneWidget);
      expect(find.text('Ayer'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      // Los propios no llevan el nombre.
      expect(find.text('Perfecto, aquí estoy.'), findsOneWidget);
      expect(find.textContaining('María López'), findsNothing);
      expect(find.text(ChatHistoryNote.message), findsOneWidget);

      // El botón se habilita al escribir.
      final send = find.byKey(const Key('chat.send'));
      expect(tester.widget<IconButton>(send).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('chat.input')), ' Gracias ');
      await tester.pump();
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);
      await tester.tap(send);
      await tester.pump();
      expect(repository.sent, [('inc-1', residentUid, 'Gracias')]);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat.input')))
            .controller!
            .text,
        isEmpty,
      );

      // Si falla, el texto se conserva y se avisa.
      repository.sendError = ChatFailure.offline;
      await tester.enterText(find.byKey(const Key('chat.input')), 'Otra vez');
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
      expect(find.text(ChatFailure.offline.message), findsOneWidget);
      expect(find.text('Otra vez'), findsOneWidget);
    });

    testWidgets('PU-616 en solo lectura muestra el aviso en lugar del campo', (
      tester,
    ) async {
      await pumpChat(tester, TestUsers.technician);
      repository.contextController.add(
        chatContext(incident: chatIncident(status: IncidentStatus.resolved)),
      );
      await tester.pump();
      repository.messagesController.add([chatMessage('m1', sentAt: now)]);
      await tester.pump();

      expect(find.text('Hola'), findsOneWidget);
      expect(find.byKey(const Key('chat.notice')), findsOneWidget);
      expect(find.text(ChatAccess.resolvedReadOnly), findsOneWidget);
      expect(find.byKey(const Key('chat.input')), findsNothing);

      repository.messagesController.add(const []);
      await tester.pump();
      expect(
        find.text(ChatViewModel.noMessagesReadOnlyMessage),
        findsOneWidget,
      );
    });

    testWidgets('PU-617 sin acceso o con error no se puede escribir', (
      tester,
    ) async {
      final viewModel = await pumpChat(tester, TestUsers.resident());
      repository.contextController.add(chatContext(resident: 'uid-nuevo'));
      await tester.pump();
      expect(find.text(ChatAccess.notActiveResident), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byKey(const Key('chat.input')), findsNothing);
      expect(find.byKey(const Key('chat.retry')), findsNothing);

      repository.contextController.addError(ChatFailure.offline);
      await tester.pump();
      expect(viewModel.state, ChatState.error);
      expect(find.text(ChatFailure.offline.message), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat.retry')));
      await tester.pump();
      expect(repository.contextListens, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PU-618 el detalle de la incidencia abre el chat', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final detail = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
        initial: assignedItem(assignedIncident(1)),
        session: sessionOf(TestUsers.technician),
        repository: FakeAssignedIncidentRepository(),
        clock: () => now,
      );
      addTearDown(detail.dispose);
      final opened = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianIncidentDetailScreen(
            incidentId: 'inc-1',
            viewModel: detail,
          ),
          onGenerateRoute: (settings) {
            opened.add(settings);
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      );

      await tester.tap(find.byKey(const Key('detail.chat')));
      await tester.pump();
      expect(opened.single.name, RouteNames.incidentChat);
      expect(opened.single.arguments, 'inc-1');
    });
  });
}
