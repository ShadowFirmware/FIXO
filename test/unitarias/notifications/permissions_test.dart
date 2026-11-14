import 'dart:typed_data';

import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/services/app_permissions.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_picker.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:fixo/features/notifications/data/datasources/system_notifier.dart';
import 'package:fixo/features/notifications/domain/entities/app_notification.dart';
import 'package:fixo/features/notifications/presentation/providers/notification_alerts.dart';
import 'package:fixo/features/notifications/presentation/widgets/notification_permission.dart';
import 'package:fixo/features/technician/presentation/providers/solution_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/fakes.dart';
import '../technician/assigned_incidents_fakes.dart';
import 'notification_fakes.dart';

/// Permisos del teléfono: notificaciones (HU-6.1) y cámara.
void main() {
  /// Deja que lleguen los eventos de los streams.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('permiso de notificaciones', () {
    test('PU-639 solo se pide la primera vez y si todavía se puede', () {
      expect(
        NotificationPermissionPolicy.shouldAsk(
          alreadyAsked: false,
          state: PermissionState.denied,
        ),
        isTrue,
      );
      expect(
        NotificationPermissionPolicy.shouldAsk(
          alreadyAsked: true,
          state: PermissionState.denied,
        ),
        isFalse,
      );
      for (final state in [
        PermissionState.granted,
        PermissionState.permanentlyDenied,
        PermissionState.notRequired,
      ]) {
        expect(
          NotificationPermissionPolicy.shouldAsk(
            alreadyAsked: false,
            state: state,
          ),
          isFalse,
          reason: state.name,
        );
      }

      expect(
        NotificationPermissionPolicy.showBanner(PermissionState.denied),
        isTrue,
      );
      expect(
        NotificationPermissionPolicy.showBanner(
          PermissionState.permanentlyDenied,
        ),
        isTrue,
      );
      expect(
        NotificationPermissionPolicy.showBanner(PermissionState.granted),
        isFalse,
      );
      expect(
        NotificationPermissionPolicy.showBanner(PermissionState.notRequired),
        isFalse,
      );
    });

    Future<void> pumpAsk(
      WidgetTester tester,
      FakePermissions permissions,
      FakePromptStore store,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => askNotificationsOnce(
                  context,
                  permissions: permissions,
                  store: store,
                ),
                child: const Text('Entrar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('PU-640 al entrar por primera vez explica y pide el permiso', (
      tester,
    ) async {
      final permissions = FakePermissions();
      final store = FakePromptStore();
      await pumpAsk(tester, permissions, store);

      expect(
        find.byKey(const Key('notifications.permissionDialog')),
        findsOneWidget,
      );
      expect(find.text('Activa las notificaciones'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notifications.permissionAllow')));
      await tester.pumpAndSettle();
      expect(permissions.notificationRequests, 1);
      expect(store.asked, isTrue);

      // Ya se preguntó: no se insiste.
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('notifications.permissionDialog')),
        findsNothing,
      );
    });

    testWidgets('PU-641 si elige "Ahora no", no se pide ni se vuelve a '
        'preguntar', (tester) async {
      final permissions = FakePermissions();
      final store = FakePromptStore();
      await pumpAsk(tester, permissions, store);
      await tester.tap(find.byKey(const Key('notifications.permissionLater')));
      await tester.pumpAndSettle();
      expect(permissions.notificationRequests, 0);
      expect(store.asked, isTrue);

      // Con el permiso ya concedido o sin poder consultarlo, no se pregunta.
      await pumpAsk(
        tester,
        FakePermissions(notifications: PermissionState.granted),
        FakePromptStore(),
      );
      expect(
        find.byKey(const Key('notifications.permissionDialog')),
        findsNothing,
      );
      await pumpAsk(tester, FakePermissions(fails: true), FakePromptStore());
      expect(
        find.byKey(const Key('notifications.permissionDialog')),
        findsNothing,
      );
    });

    testWidgets('PU-642 en Avisos se ofrece activarlas si están '
        'desactivadas', (tester) async {
      Future<void> pumpBanner(FakePermissions permissions) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: NotificationsPermissionBanner(permissions: permissions),
            ),
          ),
        );
        await tester.pump();
      }

      final denied = FakePermissions()..afterRequest = PermissionState.granted;
      await pumpBanner(denied);
      expect(
        find.byKey(const Key('notifications.permissionBanner')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('notifications.enable')));
      await tester.pump();
      await tester.pump();
      expect(denied.notificationRequests, 1);
      expect(
        find.byKey(const Key('notifications.permissionBanner')),
        findsNothing,
      );

      // Si el sistema ya no pregunta, se abren los ajustes.
      final blocked = FakePermissions(
        notifications: PermissionState.permanentlyDenied,
      );
      await pumpBanner(blocked);
      await tester.tap(find.byKey(const Key('notifications.enable')));
      await tester.pump();
      expect(blocked.notificationRequests, 0);
      expect(blocked.settingsOpened, 1);

      await pumpBanner(FakePermissions(notifications: PermissionState.granted));
      expect(
        find.byKey(const Key('notifications.permissionBanner')),
        findsNothing,
      );
    });
  });

  group('notificaciones del teléfono', () {
    late FakeNotificationRepository repository;
    late FakeSystemNotifier notifier;
    late AuthSession session;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      repository = FakeNotificationRepository();
      notifier = FakeSystemNotifier();
      session = AuthSession.withRepository(FakeAuthRepository());
      navigatorKey = GlobalKey<NavigatorState>();
    });
    tearDown(() => repository.close());

    Future<NotificationAlerts> attach() async {
      final alerts = NotificationAlerts(
        navigatorKey: navigatorKey,
        session: session,
        repository: repository,
        notifier: notifier,
      );
      addTearDown(alerts.dispose);
      await alerts.attach();
      return alerts;
    }

    test('PU-643 solo se notifican los avisos nuevos del usuario en '
        'sesión', () async {
      await attach();
      expect(notifier.initialized, isTrue);
      expect(repository.watched, isEmpty);

      session.start(TestUsers.resident());
      expect(repository.watched, ['uid-residente']);

      // Los que ya tenía al entrar no se notifican.
      repository.controller.add([notice('viejo')]);
      await flush();
      expect(notifier.shown, isEmpty);

      repository.controller.add([
        notice('nuevo'),
        notice('viejo'),
        notice('leido', read: true),
        notice('ajeno', userId: 'uid-otro'),
      ]);
      await flush();
      expect(notifier.shown.map((n) => n.id), ['nuevo']);

      // El mismo aviso no se notifica dos veces.
      repository.controller.add([notice('nuevo'), notice('viejo')]);
      await flush();
      expect(notifier.shown, hasLength(1));

      // Al cerrar sesión se deja de escuchar.
      await session.signOut();
      expect(repository.controller.hasListener, isFalse);
    });

    testWidgets('PU-644 al tocar la notificación se abre el aviso', (
      tester,
    ) async {
      final opened = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(),
          onGenerateRoute: (settings) {
            opened.add(settings);
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      );
      await tester.runAsync(attach);
      session.start(TestUsers.technician);

      notifier.tap(notice('n1', userId: 'uid-tecnico'));
      await tester.pump();
      expect(repository.markedRead, ['n1']);
      expect(opened.single.name, RouteNames.technicianIncidentDetail);
      expect(opened.single.arguments, 'inc-1');

      // Uno de otra persona (por ejemplo, de una sesión anterior) se ignora.
      notifier.tap(notice('n2', userId: 'uid-residente'));
      await tester.pump();
      expect(repository.markedRead, ['n1']);
      expect(opened, hasLength(1));
    });

    test('PU-645 la notificación guarda lo necesario para abrir el aviso', () {
      final original = notice(
        'n1',
        type: NotificationType.incidentRejected,
        refId: 'inc-7',
      );
      final decoded = LocalSystemNotifier.decodePayload(
        LocalSystemNotifier.encodePayload(original),
      )!;
      expect(decoded.id, 'n1');
      expect(decoded.userId, 'uid-residente');
      expect(decoded.type, NotificationType.incidentRejected);
      expect(decoded.incidentId, 'inc-7');

      expect(LocalSystemNotifier.decodePayload(null), isNull);
      expect(LocalSystemNotifier.decodePayload('no es json'), isNull);
      expect(LocalSystemNotifier.decodePayload('{"tipo": 3}'), isNull);
      expect(
        LocalSystemNotifier.idFor(original),
        LocalSystemNotifier.idFor(notice('n1')),
      );
      expect(LocalSystemNotifier.idFor(original), isNonNegative);
    });
  });

  group('permiso de la cámara', () {
    test(
      'PU-646 se pide antes de abrir la cámara, no para la galería',
      () async {
        final images = FakeImagePicker();
        final granted = FakePermissions(camera: PermissionState.granted);
        final picker = EvidencePicker(picker: images, permissions: granted);

        expect(await picker.pickPhotos(fromCamera: true), hasLength(1));
        expect(await picker.pickVideo(fromCamera: true), isNotNull);
        expect(granted.cameraRequests, 2);
        await picker.pickPhotos(fromCamera: false);
        await picker.pickVideo(fromCamera: false);
        expect(granted.cameraRequests, 2);
        expect(images.cameraOpened, 2);

        final denied = EvidencePicker(
          picker: images,
          permissions: FakePermissions(camera: PermissionState.denied),
        );
        await expectLater(
          denied.pickPhotos(fromCamera: true),
          throwsA(
            isA<CameraPermissionDeniedException>().having(
              (e) => e.permanently,
              'permanently',
              isFalse,
            ),
          ),
        );
        final blocked = EvidencePicker(
          picker: images,
          permissions: FakePermissions(
            camera: PermissionState.permanentlyDenied,
          ),
        );
        await expectLater(
          blocked.pickVideo(fromCamera: true),
          throwsA(
            isA<CameraPermissionDeniedException>().having(
              (e) => e.message,
              'message',
              contains('ajustes del teléfono'),
            ),
          ),
        );
        // Sin permiso, la cámara no se abre.
        expect(images.cameraOpened, 2);

        // Donde el sistema pregunta por su cuenta (iOS) se abre directo.
        final ios = EvidencePicker(
          picker: images,
          permissions: FakePermissions(camera: PermissionState.notRequired),
        );
        expect(await ios.pickPhotos(fromCamera: true), hasLength(1));
      },
    );

    test('PU-647 si no se concede, se explica cómo activarla', () async {
      final viewModel = SolutionFormViewModel(
        item: assignedItem(assignedIncident(1)),
        repository: FakeAssignedIncidentRepository(),
        picker: _DeniedCameraPicker(),
      );
      addTearDown(viewModel.dispose);
      await viewModel.addPhotos(fromCamera: true);
      expect(viewModel.evidence, isEmpty);
      expect(
        viewModel.evidenceMessage,
        const CameraPermissionDeniedException(permanently: false).message,
      );
    });
  });
}

class FakePermissions implements AppPermissions {
  FakePermissions({
    this.notifications = PermissionState.denied,
    this.camera = PermissionState.granted,
    this.fails = false,
  });

  PermissionState notifications;
  final PermissionState camera;
  final bool fails;

  /// Estado después de pedir el permiso de notificaciones.
  PermissionState? afterRequest;

  var notificationRequests = 0;
  var cameraRequests = 0;
  var settingsOpened = 0;

  @override
  Future<PermissionState> notificationStatus() async {
    if (fails) throw StateError('Sin plugin');
    return notifications;
  }

  @override
  Future<PermissionState> requestNotifications() async {
    notificationRequests++;
    notifications = afterRequest ?? notifications;
    return notifications;
  }

  @override
  Future<PermissionState> requestCamera() async {
    cameraRequests++;
    return camera;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakePromptStore implements NotificationPromptStore {
  bool asked = false;

  @override
  Future<bool> wasAsked() async => asked;

  @override
  Future<void> markAsked() async => asked = true;
}

class FakeSystemNotifier implements SystemNotifier {
  bool initialized = false;
  final shown = <AppNotification>[];
  void Function(AppNotification)? _onOpen;

  void tap(AppNotification notification) => _onOpen?.call(notification);

  @override
  Future<void> init({required void Function(AppNotification) onOpen}) async {
    initialized = true;
    _onOpen = onOpen;
  }

  @override
  Future<void> show(AppNotification notification) async =>
      shown.add(notification);
}

/// Simula la cámara y la galería con archivos en memoria.
class FakeImagePicker extends ImagePicker {
  var cameraOpened = 0;

  XFile _file(String name) =>
      XFile.fromData(Uint8List.fromList([1, 2, 3]), path: name, name: name);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (source == ImageSource.camera) cameraOpened++;
    return _file('foto.jpg');
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [_file('galeria.jpg')];

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    if (source == ImageSource.camera) cameraOpened++;
    return _file('video.mp4');
  }
}

/// Selector cuyo permiso de cámara siempre se niega.
class _DeniedCameraPicker implements EvidencePicker {
  @override
  Future<List<EvidenceFile>> pickPhotos({required bool fromCamera}) async =>
      throw const CameraPermissionDeniedException(permanently: false);

  @override
  Future<EvidenceFile?> pickVideo({required bool fromCamera}) async =>
      throw const CameraPermissionDeniedException(permanently: false);
}
