import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/core/errors/notification_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/admin/data/models/assignment_plan.dart';
import 'package:fixo/features/admin/data/models/rejection_plan.dart';
import 'package:fixo/features/admin/presentation/screens/admin_notifications_screen.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:fixo/features/notifications/data/models/notification_model.dart';
import 'package:fixo/features/notifications/data/models/notification_notices.dart';
import 'package:fixo/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:fixo/features/notifications/domain/entities/app_notification.dart';
import 'package:fixo/features/notifications/domain/entities/notification_recipients.dart';
import 'package:fixo/features/notifications/presentation/providers/notifications_view_model.dart';
import 'package:fixo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:fixo/features/technician/data/models/finalize_plan.dart';
import 'package:fixo/features/technician/data/models/start_attention_plan.dart';
import 'package:fixo/shared/widgets/floating_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'notification_fakes.dart';

/// HU-6.1 Recibir notificaciones sobre incidencias y reportes de conducta.
void main() {
  final now = DateTime(2026, 11, 14, 10);

  /// Deja que lleguen los eventos de los streams.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  AuthSession sessionOf(UserModel user) =>
      AuthSession.withRepository(FakeAuthRepository())..start(user);

  late FakeNotificationRepository repository;

  setUp(() => repository = FakeNotificationRepository());
  tearDown(() => repository.close());

  NotificationsViewModel viewModelFor(UserModel? user) {
    final viewModel = NotificationsViewModel(
      session: user == null
          ? AuthSession.withRepository(FakeAuthRepository())
          : sessionOf(user),
      repository: repository,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('estructura (T 6.1.1)', () {
    test('PU-619 lee y crea los documentos de avisos', () {
      final date = DateTime(2026, 11, 14, 9);
      final model = NotificationModel.fromMap('n1', {
        'usuarioId': 'uid-residente',
        'tipo': 'incidencia_resuelta',
        'titulo': ' Incidencia INC-0001 resuelta ',
        'mensaje': 'Juan resolvió "Fuga".',
        'refId': 'inc-1',
        'leida': true,
        'fecha': Timestamp.fromDate(date),
      });
      expect(model.userId, 'uid-residente');
      expect(model.type, NotificationType.incidentResolved);
      expect(model.title, 'Incidencia INC-0001 resuelta');
      expect(model.message, 'Juan resolvió "Fuga".');
      expect(model.refId, 'inc-1');
      expect(model.read, isTrue);
      expect(model.date, date);

      // Un tipo desconocido se muestra igual; sin fecha ni leída.
      final unknown = NotificationModel.fromMap('n2', {
        'usuarioId': 'uid-residente',
        'tipo': 'otro_tipo',
        'titulo': 'Aviso',
      });
      expect(unknown.type, isNull);
      expect(unknown.read, isFalse);
      expect(unknown.date, isNull);
      expect(unknown.message, '');

      for (final invalid in [
        {'titulo': 'Sin destinatario'},
        {'usuarioId': 'uid-residente', 'titulo': '  '},
      ]) {
        expect(
          () => NotificationModel.fromMap('x', invalid),
          throwsFormatException,
        );
      }

      final data = NotificationModel.newNotice(
        userId: 'uid-admin',
        type: NotificationType.conductReport,
        title: 'Nuevo reporte de conducta',
        message: 'Se reportó a Ana.',
        refId: 'rep-1',
      );
      expect(data, {
        'usuarioId': 'uid-admin',
        'tipo': 'reporte_conducta',
        'titulo': 'Nuevo reporte de conducta',
        'mensaje': 'Se reportó a Ana.',
        'refId': 'rep-1',
        'leida': false,
        'fecha': isA<FieldValue>(),
      });
      expect(NotificationModel.markRead, {'leida': true});
    });

    test('PU-620 cada tipo tiene su valor y solo los de incidencias llevan '
        'a una incidencia', () {
      expect(
        {for (final type in NotificationType.values) type.value},
        {
          'nueva_incidencia',
          'incidencia_asignada',
          'incidencia_en_proceso',
          'incidencia_resuelta',
          'incidencia_rechazada',
          'reporte_conducta',
          'advertencia_conducta',
          'cuenta_suspendida',
          'cuenta_reactivada',
          'cuenta_deshabilitada',
        },
      );
      for (final type in NotificationType.values) {
        expect(NotificationType.fromValue(type.value), type);
      }
      expect(notice('n1').incidentId, 'inc-1');
      expect(
        notice(
          'n2',
          type: NotificationType.conductWarning,
          refId: 'rep-1',
        ).incidentId,
        isNull,
      );
      expect(notice('n3', refId: null).incidentId, isNull);
      expect(notice('n4', type: null).incidentId, isNull);

      final read = notice('n5', date: now).copyWith(read: true);
      expect(read.read, isTrue);
      expect(read.id, 'n5');
      expect(read.date, now);
    });
  });

  group('servicio (T 6.1.2, T 6.1.4)', () {
    test('PU-621 los avisos se ordenan del más reciente al más antiguo', () {
      final list = [
        notice('viejo', date: DateTime(2026, 11, 1)),
        notice('pendiente'),
        notice('nuevo', date: DateTime(2026, 11, 14)),
      ]..sort(NotificationRemoteDataSource.newestFirst);
      expect(list.map((n) => n.id), ['pendiente', 'nuevo', 'viejo']);
    });

    test('PU-622 el repositorio traduce los errores de Firestore', () async {
      final remote = FakeNotificationRemoteDataSource();
      final repo = NotificationRepositoryImpl(remote: remote);
      FirebaseException firebase(String code) =>
          FirebaseException(plugin: 'cloud_firestore', code: code);

      Future<String?> streamError(Object error) async {
        final first = repo.watchFor('uid-residente').first;
        remote.controller.addError(error);
        try {
          await first;
          return null;
        } on NotificationFailure catch (failure) {
          return failure.message;
        }
      }

      expect(
        await streamError(firebase('unavailable')),
        NotificationFailure.offline.message,
      );
      expect(
        await streamError(firebase('internal')),
        NotificationFailure.loadFailed.message,
      );

      remote.updateError = firebase('permission-denied');
      expect(
        () => repo.markRead('n1'),
        throwsA(NotificationFailure.updateFailed),
      );
      expect(
        () => repo.markAllRead(['n1']),
        throwsA(NotificationFailure.updateFailed),
      );
      remote.updateError = firebase('unavailable');
      expect(() => repo.markRead('n1'), throwsA(NotificationFailure.offline));

      // Sin avisos por marcar no se escribe nada.
      remote.updateError = null;
      await repo.markAllRead(const []);
      expect(remote.markedAll, isEmpty);
    });
  });

  group('avisos de incidencias (T 6.1.5 a T 6.1.8)', () {
    test('PU-623 avisos de incidencia nueva, asignación, atención, '
        'resolución y rechazo', () {
      final newIncident = NotificationNotices.newIncident(
        adminId: 'uid-admin',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga en el baño',
        typeLabel: 'Agua',
      );
      expect(newIncident['usuarioId'], 'uid-admin');
      expect(newIncident['tipo'], 'nueva_incidencia');
      expect(newIncident['titulo'], 'Nueva incidencia INC-0001');
      expect(
        newIncident['mensaje'],
        '"Fuga en el baño" (Agua) está pendiente de asignación.',
      );
      expect(newIncident['refId'], 'inc-1');
      expect(
        NotificationNotices.newIncident(
          adminId: 'uid-admin',
          incidentId: 'inc-1',
          reportNumber: 'INC-0001',
          title: 'Fuga',
        )['mensaje'],
        '"Fuga" está pendiente de asignación.',
      );

      final arrival = DateTime(2026, 11, 14, 16, 5);
      final assigned = AssignmentPlan.residentNotice(
        residentId: 'uid-residente',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga en el baño',
        technicianName: 'Juan Pérez',
        estimatedTime: arrival,
      );
      expect(assigned['tipo'], 'incidencia_asignada');
      // Nombre del técnico y hora estimada de llegada.
      expect(assigned['mensaje'], contains('Juan Pérez'));
      expect(assigned['mensaje'], contains(DateFormats.dateTime(arrival)));

      final technician = AssignmentPlan.technicianNotice(
        technicianId: 'uid-tecnico',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga en el baño',
        typeLabel: 'Agua',
        housingLabel: 'Torre A – 4B',
        description: 'Gotea',
        estimatedTime: arrival,
      );
      expect(technician['usuarioId'], 'uid-tecnico');
      expect(technician['tipo'], 'incidencia_asignada');
      // Identifica el reporte.
      expect(technician['titulo'], 'Nueva asignación INC-0001');
      expect(technician['refId'], 'inc-1');

      final inProgress = StartAttentionPlan.notice(
        userId: 'uid-residente',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga',
        technicianName: 'Juan Pérez',
      );
      expect(inProgress['tipo'], 'incidencia_en_proceso');

      final resolved = FinalizePlan.notice(
        userId: 'uid-residente',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga',
        technicianName: 'Juan Pérez',
        solution: 'Se cambió el empaque.',
      );
      expect(resolved['tipo'], 'incidencia_resuelta');
      expect(resolved['titulo'], 'Incidencia INC-0001 resuelta');

      final rejected = RejectionPlan.residentNotice(
        residentId: 'uid-residente',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga',
        comment: 'Es un área común.',
      );
      expect(rejected['tipo'], 'incidencia_rechazada');
      // Con el motivo del rechazo.
      expect(rejected['mensaje'], contains('Motivo: Es un área común.'));

      for (final data in [
        newIncident,
        assigned,
        technician,
        inProgress,
        resolved,
        rejected,
      ]) {
        expect(data['leida'], isFalse);
        expect(data['fecha'], isA<FieldValue>());
      }
    });
  });

  group('destinatarios (T 6.1.14)', () {
    test('PU-624 se avisa al residente que registró y al residente activo, '
        'sin repetir ni a cuentas dadas de baja', () {
      expect(
        NotificationRecipients.residents(
          createdBy: 'uid-ana',
          activeResidentId: 'uid-pedro',
        ),
        ['uid-ana', 'uid-pedro'],
      );
      expect(
        NotificationRecipients.residents(
          createdBy: 'uid-ana',
          activeResidentId: 'uid-ana',
        ),
        ['uid-ana'],
      );
      // Vivienda sin residente activo o incidencia sin autor.
      expect(
        NotificationRecipients.residents(
          createdBy: 'uid-ana',
          activeResidentId: null,
        ),
        ['uid-ana'],
      );
      expect(
        NotificationRecipients.residents(
          createdBy: ' ',
          activeResidentId: 'uid-pedro',
        ),
        ['uid-pedro'],
      );

      expect(NotificationRecipients.canReceive(null), isFalse);
      expect(
        NotificationRecipients.canReceive({'estadoCuenta': 'baja'}),
        isFalse,
      );
      for (final status in ['activa', 'suspendida', 'deshabilitada']) {
        expect(
          NotificationRecipients.canReceive({'estadoCuenta': status}),
          isTrue,
          reason: status,
        );
      }
    });
  });

  group('avisos de conducta (T 6.1.9 a T 6.1.13)', () {
    test('PU-625 al levantar un reporte se avisa a cada administrador', () {
      final notices = NotificationNotices.conductReport(
        adminIds: ['uid-admin', 'uid-admin-2', 'uid-admin'],
        reportId: 'rep-1',
        reportedName: 'Ana López',
        reportedRole: UserRole.resident,
        reason: 'x' * 250,
      );
      expect(notices.map((n) => n['usuarioId']), ['uid-admin', 'uid-admin-2']);
      final first = notices.first;
      expect(first['tipo'], 'reporte_conducta');
      expect(first['titulo'], 'Nuevo reporte de conducta');
      expect(first['refId'], 'rep-1');
      expect(
        first['mensaje'],
        startsWith('Se reportó a Ana López (Residente).'),
      );
      expect(first['mensaje'], contains('${'x' * 200}…'));

      expect(
        NotificationNotices.conductReport(
          adminIds: ['uid-admin'],
          reportId: 'rep-2',
          reportedName: 'Juan Pérez',
          reportedRole: UserRole.technician,
        ).single['mensaje'],
        'Se reportó a Juan Pérez (Técnico). Revísalo para validarlo o '
        'descartarlo.',
      );
    });

    test('PU-626 al validar un reporte se advierte al usuario y, con el '
        'quinto, se deshabilita su cuenta', () {
      final third = NotificationNotices.reportValidated(
        userId: 'uid-ana',
        reportId: 'rep-3',
        validatedReports: 3,
        reason: 'Ruido excesivo',
      );
      expect(third, hasLength(1));
      expect(third.single['tipo'], 'advertencia_conducta');
      expect(third.single['usuarioId'], 'uid-ana');
      expect(third.single['titulo'], 'Advertencia por conducta');
      expect(
        third.single['mensaje'],
        'Se validó un reporte de conducta en tu contra. Motivo: Ruido '
        'excesivo Llevas 3 de 5 reportes validados. Al llegar a 5 tu cuenta '
        'se deshabilitará.',
      );

      final fifth = NotificationNotices.reportValidated(
        userId: 'uid-ana',
        reportId: 'rep-5',
        validatedReports: 5,
      );
      expect(fifth.map((n) => n['tipo']), [
        'advertencia_conducta',
        'cuenta_deshabilitada',
      ]);
      expect(fifth.first['mensaje'], isNot(contains('Al llegar')));
      final disabled = fifth.last;
      expect(disabled['titulo'], 'Cuenta deshabilitada');
      expect(disabled['mensaje'], contains('de forma indefinida'));
      expect(disabled['mensaje'], contains('5 reportes'));
      expect(disabled['refId'], 'rep-5');
    });

    test('PU-627 la suspensión indica cuánto dura y cuándo termina', () {
      final until = DateTime(2026, 11, 21, 10);
      final suspended = NotificationNotices.accountSuspended(
        userId: 'uid-ana',
        from: now,
        until: until,
        reportId: 'rep-4',
      );
      expect(suspended['tipo'], 'cuenta_suspendida');
      expect(suspended['titulo'], 'Cuenta suspendida');
      expect(
        suspended['mensaje'],
        'Tu cuenta se suspendió por 7 días, hasta el '
        '${DateFormats.dateTime(until)}. Mientras tanto no podrás iniciar '
        'sesión.',
      );

      String label(Duration d) => NotificationNotices.durationLabel(d);
      expect(label(const Duration(days: 1)), '1 día');
      expect(label(const Duration(days: 2, hours: 1)), '3 días');
      expect(label(const Duration(hours: 5)), '5 horas');
      expect(label(const Duration(minutes: 61)), '2 horas');
      expect(label(const Duration(hours: 1)), '1 hora');
      expect(label(const Duration(minutes: 30)), '30 minutos');
      expect(label(const Duration(seconds: 20)), '1 minuto');
      expect(label(Duration.zero), '1 minuto');
    });

    test('PU-628 avisos de reactivación', () {
      final afterSuspension = NotificationNotices.accountReactivated(
        userId: 'uid-ana',
      );
      expect(afterSuspension['tipo'], 'cuenta_reactivada');
      expect(afterSuspension['titulo'], 'Cuenta reactivada');
      expect(afterSuspension['mensaje'], startsWith('Terminó la suspensión'));
      expect(
        NotificationNotices.accountReactivated(
          userId: 'uid-ana',
          byAdmin: true,
        )['mensaje'],
        startsWith('El administrador reactivó tu cuenta.'),
      );
    });

    test('PU-629 al terminar la suspensión, el inicio de sesión reactiva la '
        'cuenta', () async {
      FakeAuthRemoteDataSource remote(UserModel user) =>
          FakeAuthRemoteDataSource(
            passwords: {'maria@correo.com': TestUsers.password},
            profiles: {user.uid: user},
            currentEmail: 'maria@correo.com',
          );
      Future<AppUser> signIn(FakeAuthRemoteDataSource source) =>
          AuthRepositoryImpl(remote: source)
              .signIn(email: 'maria@correo.com', password: TestUsers.password);

      final expired = remote(
        TestUsers.resident(
          status: AccountStatus.suspended,
          suspendedUntil: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );
      expect((await signIn(expired)).uid, 'uid-residente');
      expect(expired.reactivated, ['uid-residente']);

      // Con la suspensión vigente no entra ni se reactiva.
      final current = remote(
        TestUsers.resident(
          status: AccountStatus.suspended,
          suspendedUntil: DateTime.now().add(const Duration(days: 2)),
        ),
      );
      await expectLater(signIn(current), throwsA(isA<AuthFailure>()));
      expect(current.reactivated, isEmpty);

      final active = remote(TestUsers.resident());
      await signIn(active);
      expect(active.reactivated, isEmpty);
    });
  });

  group('ViewModel (T 6.1.4)', () {
    test('PU-630 escucha los avisos del usuario en sesión', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      expect(viewModel.state, NotificationsState.loading);
      expect(repository.watched, ['uid-residente']);

      repository.controller.add([
        notice('n1', date: now),
        notice('n2', read: true, date: now),
        // Nunca se muestran los de otra persona.
        notice('ajeno', userId: 'uid-otro', date: now),
      ]);
      await flush();
      expect(viewModel.state, NotificationsState.ready);
      expect(viewModel.notifications.map((n) => n.id), ['n1', 'n2']);
      expect(viewModel.unreadCount, 1);

      repository.controller.addError(NotificationFailure.offline);
      await flush();
      expect(viewModel.state, NotificationsState.error);
      expect(viewModel.errorMessage, NotificationFailure.offline.message);

      viewModel.load();
      expect(viewModel.state, NotificationsState.loading);
      expect(repository.watched, hasLength(2));

      // Sin sesión no se consulta nada.
      final signedOut = viewModelFor(null);
      expect(signedOut.state, NotificationsState.ready);
      expect(signedOut.notifications, isEmpty);
      expect(repository.watched, hasLength(2));
    });

    test('PU-631 al abrir un aviso se marca como leído y se pueden marcar '
        'todos', () async {
      final viewModel = viewModelFor(TestUsers.resident());
      repository.controller.add([
        notice('n1', date: now),
        notice('n2', date: now),
        notice('n3', read: true, date: now),
      ]);
      await flush();

      expect(await viewModel.open(viewModel.notifications.first), isNull);
      expect(repository.markedRead, ['n1']);
      expect(viewModel.notifications.first.read, isTrue);
      expect(viewModel.unreadCount, 1);
      // Uno ya leído no se vuelve a marcar.
      expect(await viewModel.open(viewModel.notifications.last), isNull);
      expect(repository.markedRead, ['n1']);

      expect(await viewModel.markAllRead(), isNull);
      expect(repository.markedAll, [
        ['n2'],
      ]);
      expect(viewModel.unreadCount, 0);
      // Sin pendientes no se escribe nada.
      expect(await viewModel.markAllRead(), isNull);
      expect(repository.markedAll, hasLength(1));

      repository.controller.add([notice('n4', date: now)]);
      await flush();
      repository.updateError = NotificationFailure.offline;
      expect(
        await viewModel.markAllRead(),
        NotificationFailure.offline.message,
      );
      expect(viewModel.unreadCount, 1);
      repository.updateError = StateError('falla');
      expect(
        await viewModel.open(viewModel.notifications.single),
        NotificationFailure.updateFailed.message,
      );
    });

    test('PU-632 cada aviso abre la pantalla que corresponde al rol', () {
      final incident = notice('n1');
      final newIncident = notice('n2', type: NotificationType.newIncident);
      final account = notice(
        'n3',
        type: NotificationType.accountSuspended,
        refId: null,
      );

      final resident = viewModelFor(TestUsers.resident());
      expect(resident.destinationFor(incident), (
        RouteNames.incidentDetail,
        'inc-1',
      ));
      expect(resident.destinationFor(account), isNull);

      final technician = viewModelFor(TestUsers.technician);
      expect(technician.destinationFor(incident), (
        RouteNames.technicianIncidentDetail,
        'inc-1',
      ));

      final admin = viewModelFor(TestUsers.admin);
      expect(admin.destinationFor(newIncident), (
        RouteNames.adminPendingIncidents,
        null,
      ));
      expect(admin.destinationFor(incident), (
        RouteNames.adminIncidentHistory,
        null,
      ));
      expect(
        admin.destinationFor(
          notice('n4', type: NotificationType.conductReport, refId: 'rep-1'),
        ),
        isNull,
      );
    });

    test('PU-633 muestra cuándo llegó cada aviso', () {
      String label(DateTime? date) =>
          NotificationsViewModel.relativeDate(date, now);
      expect(label(null), 'Ahora');
      expect(
        label(now.subtract(const Duration(seconds: 30))),
        'Hace un momento',
      );
      expect(label(now.subtract(const Duration(minutes: 5))), 'Hace 5 min');
      expect(label(DateTime(2026, 11, 14, 8, 5)), 'Hoy, 8:05 a. m.');
      expect(label(DateTime(2026, 11, 13, 16, 5)), 'Ayer, 4:05 p. m.');
      expect(label(DateTime(2026, 11, 9)), '9 nov 2026');
    });
  });

  group('pantallas (T 6.1.3)', () {
    Future<List<RouteSettings>> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: home,
          onGenerateRoute: (settings) {
            opened.add(settings);
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      );
      return opened;
    }

    testWidgets('PU-634 muestra los avisos y abre la incidencia', (
      tester,
    ) async {
      final viewModel = viewModelFor(TestUsers.resident());
      final opened = await pump(
        tester,
        NotificationsScreen(viewModel: viewModel),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.controller.add([
        notice('n1', date: now.subtract(const Duration(minutes: 5))),
        notice(
          'n2',
          type: NotificationType.incidentRejected,
          title: 'Incidencia INC-0002 rechazada',
          message: 'Motivo: Es un área común.',
          refId: 'inc-2',
          read: true,
          date: DateTime(2026, 11, 9),
        ),
      ]);
      await tester.pump();
      expect(find.text('Avisos'), findsOneWidget);
      expect(find.text('Incidencia INC-0001 asignada'), findsOneWidget);
      expect(find.text('Hace 5 min'), findsOneWidget);
      expect(find.text('Motivo: Es un área común.'), findsOneWidget);
      expect(find.text('9 nov 2026'), findsOneWidget);
      // Solo el que no se ha leído lleva el punto.
      expect(find.byKey(const Key('notification.unread')), findsOneWidget);
      expect(find.byKey(const Key('notifications.markAll')), findsOneWidget);

      await tester.tap(find.text('Incidencia INC-0001 asignada'));
      await tester.pump();
      expect(repository.markedRead, ['n1']);
      expect(opened.single.name, RouteNames.incidentDetail);
      expect(opened.single.arguments, 'inc-1');
    });

    testWidgets('PU-635 marca todos como leídos', (tester) async {
      final viewModel = viewModelFor(TestUsers.technician);
      await pump(tester, NotificationsScreen(viewModel: viewModel));
      repository.controller.add([
        notice('n1', userId: 'uid-tecnico', date: now),
        notice('n2', userId: 'uid-tecnico', date: now),
      ]);
      await tester.pump();

      await tester.tap(find.byKey(const Key('notifications.markAll')));
      await tester.pump();
      expect(repository.markedAll, [
        ['n1', 'n2'],
      ]);
      expect(
        find.text('Marcaste todos los avisos como leídos.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('notification.unread')), findsNothing);
      expect(find.byKey(const Key('notifications.markAll')), findsNothing);
    });

    testWidgets('PU-636 sin avisos o con error', (tester) async {
      final viewModel = viewModelFor(TestUsers.resident());
      await pump(tester, NotificationsScreen(viewModel: viewModel));
      repository.controller.add(const []);
      await tester.pump();
      expect(find.text(NotificationsViewModel.emptyMessage), findsOneWidget);
      expect(find.byKey(const Key('notifications.markAll')), findsNothing);

      repository.controller.addError(NotificationFailure.offline);
      await tester.pump();
      expect(find.text(NotificationFailure.offline.message), findsOneWidget);
      await tester.tap(find.byKey(const Key('notifications.retry')));
      await tester.pump();
      expect(repository.watched, hasLength(2));
    });

    testWidgets('PU-637 el administrador ve sus avisos y abre los reportes '
        'pendientes', (tester) async {
      final viewModel = viewModelFor(TestUsers.admin);
      final opened = await pump(
        tester,
        AdminNotificationsScreen(viewModel: viewModel),
      );
      repository.controller.add([
        notice(
          'n1',
          userId: 'uid-admin',
          type: NotificationType.newIncident,
          title: 'Nueva incidencia INC-0003',
          message: '"Fuga" (Agua) está pendiente de asignación.',
          refId: 'inc-3',
          date: now,
        ),
      ]);
      await tester.pump();
      expect(find.text('Nueva incidencia INC-0003'), findsOneWidget);

      await tester.tap(find.text('Nueva incidencia INC-0003'));
      await tester.pump();
      expect(repository.markedRead, ['n1']);
      expect(opened.last.name, RouteNames.adminPendingIncidents);
    });

    testWidgets('PU-638 la barra muestra cuántos avisos no se han leído', (
      tester,
    ) async {
      const item = FloatingBottomBarItem(
        icon: Icons.notifications_none_rounded,
        selectedIcon: Icons.notifications_rounded,
        label: 'Avisos',
      );
      Future<void> pumpBar(int badge) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            bottomNavigationBar: FloatingBottomBar(
              items: [
                const FloatingBottomBarItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Inicio',
                ),
                item.withBadge(badge),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await pumpBar(3);
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Avisos, 3 sin leer'), findsOneWidget);
      await pumpBar(12);
      expect(find.text('9+'), findsOneWidget);
      await pumpBar(0);
      expect(find.text('0'), findsNothing);
      expect(find.bySemanticsLabel('Avisos'), findsOneWidget);
    });
  });
}
