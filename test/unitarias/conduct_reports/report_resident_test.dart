import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/conduct_report_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_model.dart';
import 'package:fixo/features/conduct_reports/data/models/resident_report_plan.dart';
import 'package:fixo/features/conduct_reports/data/repositories/conduct_report_repository_impl.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report_conditions.dart';
import 'package:fixo/features/conduct_reports/domain/usecases/report_resident.dart';
import 'package:fixo/features/conduct_reports/domain/usecases/report_technician.dart';
import 'package:fixo/features/conduct_reports/presentation/providers/report_resident_view_model.dart';
import 'package:fixo/features/conduct_reports/presentation/screens/report_resident_screen.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/notifications/domain/entities/app_notification.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../incidents/fakes.dart';
import '../technician/assigned_incidents_fakes.dart';
import 'conduct_report_fakes.dart';

const description = 'Me insultó cuando le expliqué la reparación.';
const reportId = 'inc-1_uid-tecnico_uid-residente';

/// HU-7.2 Reportar la conducta de un residente.
void main() {
  AuthSession sessionOf(AppUser user) =>
      AuthSession.withRepository(FakeAuthRepository())..start(user);

  /// Incidencia 1 atendida por el técnico de prueba y registrada por el
  /// residente de prueba.
  Incident incident({
    IncidentStatus status = IncidentStatus.resolved,
    String? technician = technicianId,
  }) => assignedIncident(
    1,
    status: status,
    technician: technician,
    createdBy: 'uid-residente',
  );

  group('motivos e identificador (T 7.2.3, T 7.2.6)', () {
    test('PU-668 motivos disponibles para reportar al residente', () {
      expect(ConductReason.forResident.map((r) => r.label), [
        'Insultos',
        'Groserías',
        'Falta de cooperación',
        'Otro motivo',
      ]);
      // Los del residente contra el técnico no cambian (HU-7.1).
      expect(ConductReason.forTechnician.map((r) => r.label), [
        'Retraso',
        'Mala actitud',
        'Trabajo mal realizado',
        'Lenguaje inapropiado',
        'Otro motivo',
      ]);
      expect(ConductReason.values.map((r) => r.value).toSet(), hasLength(8));
      for (final reason in ConductReason.forResident) {
        expect(ConductReason.fromValue(reason.value), reason);
        expect(reason.hint, isNotEmpty);
      }
    });

    test('PU-669 un reporte por técnico, residente e incidencia', () {
      String id(String resident) => ConductReport.docIdFor(
        incidentId: 'inc-1',
        reporterId: 'uid-tecnico',
        reportedId: resident,
      );

      expect(id('uid-residente'), reportId);
      expect(id('uid-residente-2'), isNot(reportId));
      // El del residente contra el técnico sigue igual (HU-7.1).
      expect(
        ConductReport.docIdFor(
          incidentId: 'inc-1',
          reporterId: 'uid-residente',
        ),
        'inc-1_uid-residente',
      );
    });
  });

  group('condiciones (T 7.2.5, T 7.2.6)', () {
    test('PU-670 solo se reporta en una incidencia Resuelta que atendió', () {
      ConductReportFailure? check(Incident value, [AppUser? user]) =>
          ConductReportConditions.checkForTechnician(
            value,
            technician: user ?? TestUsers.technician,
          );

      expect(check(incident()), isNull);
      for (final status in [
        IncidentStatus.pending,
        IncidentStatus.assigned,
        IncidentStatus.inProgress,
        IncidentStatus.rejected,
      ]) {
        expect(
          check(incident(status: status)),
          ConductReportFailure.residentNotResolved,
          reason: status.label,
        );
      }
      expect(
        check(incident(technician: 'otro-tecnico')),
        ConductReportFailure.notYourAttendedIncident,
      );
      expect(
        check(incident(), TestUsers.resident()),
        ConductReportFailure.notTechnician,
      );
      expect(
        ConductReportConditions.checkForTechnician(
          incident(),
          technician: null,
        ),
        ConductReportFailure.notTechnician,
      );
      expect(
        check(
          incident(),
          const AppUser(
            uid: technicianId,
            name: 'Juan Pérez Ramírez',
            email: 'juan@correo.com',
            phone: '7774445566',
            role: UserRole.technician,
            accountStatus: AccountStatus.suspended,
          ),
        ),
        ConductReportFailure.accountNotActive,
      );
    });

    test('PU-671 la transacción revisa las condiciones, al residente y los '
        'duplicados', () {
      void validate({
        Map<String, dynamic>? incident = const {
          'estado': 'resuelta',
          'tecnicoId': technicianId,
          'creadaPor': 'uid-residente',
        },
        String reporterRole = 'tecnico',
        String account = 'activa',
        Map<String, dynamic>? resident = const {'rol': 'residente'},
        String residentId = 'uid-residente',
        bool wroteInChat = false,
        bool alreadyReported = false,
      }) => ResidentReportPlan.validate(
        incident: incident,
        reporter: {'rol': reporterRole, 'estadoCuenta': account},
        reporterId: technicianId,
        resident: resident,
        residentId: residentId,
        wroteInChat: wroteInChat,
        alreadyReported: alreadyReported,
      );

      Matcher fails(ConductReportFailure failure) => throwsA(same(failure));

      // Registró la incidencia, o escribió en el chat.
      expect(validate, returnsNormally);
      expect(
        () => validate(residentId: 'uid-residente-2', wroteInChat: true),
        returnsNormally,
      );
      expect(
        () => validate(residentId: 'uid-residente-2'),
        fails(ConductReportFailure.notParticipant),
      );
      expect(
        () => validate(resident: {'rol': 'tecnico'}),
        fails(ConductReportFailure.notParticipant),
      );
      expect(
        () => validate(resident: null),
        fails(ConductReportFailure.notParticipant),
      );
      expect(
        () => validate(alreadyReported: true),
        fails(ConductReportFailure.duplicateResident),
      );
      for (final status in ['pendiente', 'asignada', 'en_proceso']) {
        expect(
          () => validate(
            incident: {
              'estado': status,
              'tecnicoId': technicianId,
              'creadaPor': 'uid-residente',
            },
          ),
          fails(ConductReportFailure.residentNotResolved),
        );
      }
      // Se reasignó a otro técnico antes de resolverse.
      expect(
        () => validate(
          incident: {
            'estado': 'resuelta',
            'tecnicoId': 'otro-tecnico',
            'creadaPor': 'uid-residente',
          },
        ),
        fails(ConductReportFailure.notYourAttendedIncident),
      );
      expect(
        () => validate(incident: null),
        fails(ConductReportFailure.incidentNotFound),
      );
      expect(
        () => validate(account: 'suspendida'),
        fails(ConductReportFailure.accountNotActive),
      );
      expect(
        () => validate(reporterRole: 'residente'),
        fails(ConductReportFailure.notTechnician),
      );
    });

    test('PU-672 residentes que se pueden reportar', () {
      final residents = ResidentReportPlan.reportable(
        createdBy: 'uid-residente',
        registeredName: 'María López Hernández',
        chatAuthors: {
          'uid-residente': 'María López',
          'uid-residente-2': 'Carlos Ruiz Soto',
          'uid-residente-3': '  ',
        },
      );

      expect(residents.map((r) => r.id), [
        'uid-residente',
        'uid-residente-2',
        'uid-residente-3',
      ]);
      expect(residents[0].name, 'María López Hernández');
      expect(
        residents[0].participation,
        'Registró la incidencia · Participó en el chat',
      );
      expect(residents[1].name, 'Carlos Ruiz Soto');
      expect(residents[1].participation, 'Participó en el chat');
      expect(residents[2].name, 'Residente');

      // Sin chat: solo quien la registró; sin los ya reportados.
      expect(
        ResidentReportPlan.reportable(
          createdBy: 'uid-residente',
          registeredName: null,
          chatAuthors: const {},
        ).single.participation,
        'Registró la incidencia',
      );
      expect(
        ResidentReportPlan.reportable(
          createdBy: 'uid-residente',
          registeredName: 'María',
          chatAuthors: const {'uid-residente-2': 'Carlos'},
          alreadyReported: const {'uid-residente'},
        ).map((r) => r.id),
        ['uid-residente-2'],
      );
      expect(
        ResidentReportPlan.reportable(
          createdBy: '',
          registeredName: null,
          chatAuthors: const {},
        ),
        isEmpty,
      );
    });
  });

  group('registro y aviso (T 7.2.7, T 7.2.8)', () {
    ConductReportModel build({Map<String, dynamic>? resident}) =>
        ResidentReportPlan.build(
          id: reportId,
          folio: 15,
          incidentId: 'inc-1',
          incident: {'folio': 7, 'nombre': 'Fuga en baño'},
          reporterId: technicianId,
          reporter: {'nombre': 'Juan Pérez Ramírez'},
          residentId: 'uid-residente',
          resident: resident ?? {'nombre': 'María López Hernández'},
          reason: ConductReason.lackOfCooperation,
          description: '  $description  ',
          evidence: const ['https://x/1.jpg'],
        );

    test('PU-673 el reporte se registra Pendiente de revisión, sin tocar la '
        'cuenta del residente', () {
      final report = build();

      expect(report.id, reportId);
      expect(report.reportNumber, 'RC-0015');
      expect(report.status, ConductReportStatus.pendingReview);
      expect(report.incidentNumber, 'INC-0007');
      expect(report.incidentTitle, 'Fuga en baño');
      expect(report.reporterId, technicianId);
      expect(report.reporterName, 'Juan Pérez Ramírez');
      expect(report.reporterRole, UserRole.technician);
      expect(report.reportedId, 'uid-residente');
      expect(report.reportedName, 'María López Hernández');
      expect(report.reportedRole, UserRole.resident);
      expect(report.reason, ConductReason.lackOfCooperation);
      expect(report.description, description);
      expect(report.evidence, ['https://x/1.jpg']);
      // Solo contará como antecedente cuando se valide.
      expect(report.countsAsRecord, isFalse);

      final data = report.toFirestore();
      expect(data['reportanteRol'], 'tecnico');
      expect(data['reportadoRol'], 'residente');
      expect(data['motivo'], 'falta_cooperacion');
      expect(data['estado'], 'pendiente_revision');
      for (final key in [
        'estadoConducta',
        'estadoCuenta',
        'reportesValidados',
        'suspendidaHasta',
      ]) {
        expect(data.containsKey(key), isFalse, reason: key);
      }

      // Se lee igual que los de la HU-7.1.
      final read = ConductReportModel.fromMap(reportId, {
        ...data,
        'fechaCreacion': null,
      });
      expect(read.reportedRole, UserRole.resident);
      expect(read.reason, ConductReason.lackOfCooperation);

      expect(build(resident: {'nombre': ' '}).reportedName, 'Residente');
    });

    test('PU-674 cada administrador recibe un aviso del reporte nuevo', () {
      final notices = ResidentReportPlan.notices(
        adminIds: ['uid-admin', 'uid-admin-2', 'uid-admin'],
        report: build(),
      );

      expect(notices.map((n) => n['usuarioId']), ['uid-admin', 'uid-admin-2']);
      for (final notice in notices) {
        expect(notice['tipo'], NotificationType.conductReport.value);
        expect(notice['titulo'], 'Nuevo reporte de conducta');
        expect(notice['refId'], reportId);
        expect(notice['leida'], isFalse);
        expect(
          notice['mensaje'],
          'Se reportó a María López Hernández (Residente). Motivo: Falta de '
          'cooperación (incidencia INC-0007) Revísalo para validarlo o '
          'descartarlo.',
        );
      }
    });

    test('PU-675 el caso de uso revisa al técnico, al residente, la '
        'descripción y las evidencias', () async {
      final repository = FakeConductReportRepository();
      final useCase = ReportResident(repository);
      NewResidentConductReport data({
        ReportableResident resident = registrant,
        String text = '  $description ',
        int evidence = 0,
      }) => NewResidentConductReport(
        incidentId: 'inc-1',
        resident: resident,
        reason: ConductReason.insults,
        description: text,
        evidence: List.filled(evidence, photo),
      );

      await expectLater(
        useCase(technician: TestUsers.resident(), data: data()),
        throwsA(same(ConductReportFailure.notTechnician)),
      );
      await expectLater(
        useCase(technician: null, data: data()),
        throwsA(same(ConductReportFailure.notTechnician)),
      );
      await expectLater(
        useCase(
          technician: TestUsers.technician,
          data: data(
            resident: const ReportableResident(id: ' ', name: 'X'),
          ),
        ),
        throwsA(same(ConductReportFailure.residentRequired)),
      );
      await expectLater(
        useCase(
          technician: TestUsers.technician,
          data: data(text: 'corto'),
        ),
        throwsA(isA<ConductReportIncompleteException>()),
      );
      await expectLater(
        useCase(technician: TestUsers.technician, data: data(evidence: 6)),
        throwsA(same(ConductReportFailure.tooManyEvidence)),
      );
      expect(repository.residentReports, isEmpty);

      final report = await useCase(
        technician: TestUsers.technician,
        data: data(evidence: 5),
      );
      expect(report.status, ConductReportStatus.pendingReview);
      final sent = repository.residentReports.single;
      expect(sent.reporterId, technicianId);
      expect(sent.data.resident.id, 'uid-residente');
      expect(sent.data.description, description);
      expect(sent.data.evidence, hasLength(5));
    });

    test('PU-676 el repositorio revisa duplicados y el chat, sube las '
        'evidencias, guarda y avisa', () async {
      final remote = FakeConductReportRemoteDataSource(
        adminIds: ['uid-admin', 'uid-admin-2'],
      )..chatAuthors = const {'uid-residente-2': 'Carlos Ruiz Soto'};
      final storage = FakeEvidenceStorage();
      final repository = ConductReportRepositoryImpl(
        remote: remote,
        storage: storage,
      );

      await repository.reportResident(
        reporterId: technicianId,
        data: const NewResidentConductReport(
          incidentId: 'inc-1',
          resident: chatResident,
          reason: ConductReason.rudeness,
          description: description,
          evidence: [photo, video],
        ),
      );

      const chatId = 'inc-1_uid-tecnico_uid-residente-2';
      expect(remote.checked, [chatId]);
      expect(storage.conductUploads, [chatId]);
      final created = remote.residentReports.single;
      expect(created.incidentId, 'inc-1');
      expect(created.reporterId, technicianId);
      expect(created.residentId, 'uid-residente-2');
      expect(created.wroteInChat, isTrue);
      expect(created.reason, ConductReason.rudeness);
      expect(created.evidence, [
        'https://storage/reportes/$chatId/1.jpg',
        'https://storage/reportes/$chatId/2.mp4',
      ]);
      expect(created.adminIds, ['uid-admin', 'uid-admin-2']);

      // Ya existe: no se suben las evidencias.
      final duplicateStorage = FakeEvidenceStorage();
      await expectLater(
        ConductReportRepositoryImpl(
          remote: FakeConductReportRemoteDataSource(existing: {reportId}),
          storage: duplicateStorage,
        ).reportResident(
          reporterId: technicianId,
          data: const NewResidentConductReport(
            incidentId: 'inc-1',
            resident: registrant,
            reason: ConductReason.insults,
            description: description,
            evidence: [photo],
          ),
        ),
        throwsA(same(ConductReportFailure.duplicateResident)),
      );
      expect(duplicateStorage.conductUploads, isEmpty);

      Future<void> fails(Object error) =>
          ConductReportRepositoryImpl(
            remote: FakeConductReportRemoteDataSource(createError: error),
            storage: FakeEvidenceStorage(),
          ).reportResident(
            reporterId: technicianId,
            data: const NewResidentConductReport(
              incidentId: 'inc-1',
              resident: registrant,
              reason: ConductReason.insults,
              description: description,
            ),
          );
      await expectLater(
        fails(ConductReportFailure.notParticipant),
        throwsA(same(ConductReportFailure.notParticipant)),
      );
      await expectLater(
        fails(FirebaseException(plugin: 'x', code: 'unavailable')),
        throwsA(same(ConductReportFailure.network)),
      );
      await expectLater(
        fails(StateError('x')),
        throwsA(same(ConductReportFailure.unknown)),
      );
    });

    test('PU-677 el repositorio consulta a quién reportar y los reportes '
        'enviados', () async {
      final remote = FakeConductReportRemoteDataSource()
        ..chatAuthors = const {'uid-residente-2': 'Carlos Ruiz Soto'}
        ..names = const {'uid-residente': 'María López Hernández'};
      final repository = ConductReportRepositoryImpl(
        remote: remote,
        storage: FakeEvidenceStorage(),
      );

      final residents = await repository.reportableResidents(
        incidentId: 'inc-1',
        createdBy: 'uid-residente',
      );
      expect(residents.map((r) => r.name), [
        'María López Hernández',
        'Carlos Ruiz Soto',
      ]);

      remote.chatError = FirebaseException(plugin: 'x', code: 'unavailable');
      await expectLater(
        repository.reportableResidents(
          incidentId: 'inc-1',
          createdBy: 'uid-residente',
        ),
        throwsA(same(ConductReportFailure.network)),
      );
      remote.chatError = StateError('x');
      await expectLater(
        repository.reportableResidents(
          incidentId: 'inc-1',
          createdBy: 'uid-residente',
        ),
        throwsA(same(ConductReportFailure.residentsLoadFailed)),
      );

      final received = <List<ConductReport>>[];
      final errors = <Object>[];
      final subscription = repository
          .watchOwnReports(incidentId: 'inc-1', reporterId: technicianId)
          .listen(received.add, onError: errors.add);
      addTearDown(subscription.cancel);
      remote.reporterChanges
        ..add([residentReport()])
        ..addError(FirebaseException(plugin: 'x', code: 'permission-denied'));
      await pumpEventQueue();
      expect(received.single.single.reportedId, 'uid-residente');
      expect(errors, [same(ConductReportFailure.permissionDenied)]);
    });
  });

  group('formulario (T 7.2.2 a T 7.2.4)', () {
    late FakeConductReportRepository repository;

    ReportResidentViewModel viewModel({
      ResidentReportTarget target = residentTarget,
      AppUser? user,
    }) {
      final vm = ReportResidentViewModel(
        target: target,
        session: sessionOf(user ?? TestUsers.technician),
        repository: repository,
        picker: FakeEvidencePicker(),
      );
      addTearDown(vm.dispose);
      return vm;
    }

    setUp(() => repository = FakeConductReportRepository());
    tearDown(() => repository.close());

    test('PU-678 con un solo residente queda elegido; se piden el motivo y '
        'la descripción', () async {
      final vm = viewModel();
      expect(vm.choosesResident, isFalse);
      expect(vm.resident, registrant);
      expect(vm.reasons, ConductReason.forResident);

      expect(await vm.submit(), isNull);
      expect(vm.residentError, isNull);
      expect(vm.reasonError, 'Elige el motivo del reporte.');

      vm.selectReason(ConductReason.insults);
      expect(await vm.submit(), isNull);
      expect(vm.errorMessage, 'Describe lo que ocurrió');
      expect(repository.residentReports, isEmpty);

      vm.description = description;
      await vm.addPhotos(fromCamera: false);
      final report = await vm.submit();
      expect(report?.reportNumber, 'RC-0004');
      final sent = repository.residentReports.single;
      expect(sent.reporterId, technicianId);
      expect(sent.data.incidentId, 'inc-1');
      expect(sent.data.resident.id, 'uid-residente');
      expect(sent.data.reason, ConductReason.insults);
      expect(sent.data.evidence, hasLength(1));
    });

    test('PU-679 con varios residentes se elige a quién reportar', () async {
      final vm =
          viewModel(
              target: const ResidentReportTarget(
                incidentId: 'inc-1',
                incidentNumber: 'INC-0007',
                incidentTitle: 'Fuga en baño',
                residents: [registrant, chatResident],
              ),
            )
            ..selectReason(ConductReason.rudeness)
            ..description = description;
      expect(vm.choosesResident, isTrue);
      expect(vm.resident, isNull);

      expect(await vm.submit(), isNull);
      expect(vm.residentError, 'Elige al residente que quieres reportar.');

      // Solo se elige entre los de la lista.
      vm.selectResident(const ReportableResident(id: 'otro', name: 'Otro'));
      expect(vm.resident, isNull);

      vm.selectResident(chatResident);
      expect(vm.residentError, isNull);
      await vm.submit();
      expect(
        repository.residentReports.single.data.resident.id,
        'uid-residente-2',
      );
    });

    test('PU-680 envío en curso y errores del envío', () async {
      final gate = repository.gate = Completer<void>();
      final vm = viewModel()
        ..selectReason(ConductReason.other)
        ..description = description;

      final first = vm.submit();
      expect(vm.isSaving, isTrue);
      expect(await vm.submit(), isNull);
      gate.complete();
      expect(await first, isNotNull);
      expect(repository.residentReports, hasLength(1));

      repository
        ..gate = null
        ..error = ConductReportFailure.duplicateResident;
      expect(await vm.submit(), isNull);
      expect(vm.errorMessage, ConductReportFailure.duplicateResident.message);

      // Con la sesión de un residente no se envía.
      final resident = viewModel(user: TestUsers.resident())
        ..selectReason(ConductReason.other)
        ..description = description;
      expect(await resident.submit(), isNull);
      expect(resident.errorMessage, ConductReportFailure.notTechnician.message);
    });
  });

  group('opción en el detalle (T 7.2.1)', () {
    late FakeAssignedIncidentRepository incidents;
    late FakeConductReportRepository reports;

    AssignedIncidentDetailViewModel detail() {
      final vm = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
        session: sessionOf(TestUsers.technician),
        repository: incidents,
        conductReports: reports,
      );
      addTearDown(vm.dispose);
      return vm;
    }

    Future<void> emit(Incident value) async {
      incidents.detailController.add(assignedItem(value));
      await pumpEventQueue();
    }

    setUp(() {
      incidents = FakeAssignedIncidentRepository();
      reports = FakeConductReportRepository()
        ..residents = const [registrant, chatResident];
    });
    tearDown(() => reports.close());

    test('PU-681 solo aparece cuando la incidencia está Resuelta', () async {
      final vm = detail();
      for (final status in [
        IncidentStatus.assigned,
        IncidentStatus.inProgress,
      ]) {
        await emit(incident(status: status));
        expect(vm.showConductSection, isFalse, reason: status.label);
        expect(vm.canReportResident, isFalse, reason: status.label);
        expect(vm.residentReportTarget, isNull, reason: status.label);
      }
      // Mientras no esté resuelta ni siquiera se consulta.
      expect(reports.residentQueries, isEmpty);
      expect(reports.watchedReports, isEmpty);

      await emit(incident());
      expect(vm.showConductSection, isTrue);
      expect(reports.residentQueries, [
        (incidentId: 'inc-1', createdBy: 'uid-residente'),
      ]);
      expect(reports.watchedReports, [
        (incidentId: 'inc-1', reporterId: technicianId),
      ]);
      expect(vm.isConductLoading, isTrue);
      expect(vm.canReportResident, isFalse);

      reports.reportsChanges.add(const []);
      await pumpEventQueue();
      expect(vm.isConductLoading, isFalse);
      expect(vm.canReportResident, isTrue);
      final target = vm.residentReportTarget!;
      expect(target.incidentNumber, 'INC-0001');
      expect(target.residents, [registrant, chatResident]);

      // Al volver a emitirse la incidencia no se consulta de nuevo.
      await emit(incident());
      expect(reports.residentQueries, hasLength(1));
    });

    test('PU-682 los residentes ya reportados dejan de ofrecerse', () async {
      final vm = detail();
      await emit(incident());
      reports.reportsChanges.add([residentReport()]);
      await pumpEventQueue();

      expect(vm.ownReports.single.reportedId, 'uid-residente');
      expect(vm.pendingResidents, [chatResident]);
      expect(vm.residentReportTarget!.residents, [chatResident]);

      // Recién enviado, antes de que llegue de Firestore.
      vm.reportSent(
        residentReport(residentId: 'uid-residente-2', residentName: 'Carlos'),
      );
      expect(vm.pendingResidents, isEmpty);
      expect(vm.canReportResident, isFalse);
      expect(vm.reportBlockReason, ConductReportFailure.allResidentsReported);

      // Firestore todavía no lo trae: se conserva.
      reports.reportsChanges.add([residentReport()]);
      await pumpEventQueue();
      expect(vm.ownReports, hasLength(2));
    });

    test('PU-683 sin residentes que reportar y errores al consultar', () async {
      reports.residents = const [];
      final empty = detail();
      await emit(incident());
      reports.reportsChanges.add(const []);
      await pumpEventQueue();
      expect(empty.reportBlockReason, ConductReportFailure.noResidents);
      expect(empty.canReportResident, isFalse);

      reports.residentsError = ConductReportFailure.residentsLoadFailed;
      final failing = detail();
      await emit(incident());
      await pumpEventQueue();
      expect(
        failing.conductError,
        ConductReportFailure.residentsLoadFailed.message,
      );
      expect(failing.canReportResident, isFalse);
    });
  });

  group('pantallas (T 7.2.1, T 7.2.2)', () {
    void phoneScreen(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(430, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('PU-684 formulario con un residente: queda fijo, se pide el '
        'motivo y se confirma el envío', (tester) async {
      phoneScreen(tester);
      final repository = FakeConductReportRepository();
      final vm = ReportResidentViewModel(
        target: residentTarget,
        session: sessionOf(TestUsers.technician),
        repository: repository,
        picker: FakeEvidencePicker(),
      );
      addTearDown(vm.dispose);
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<Object?>(
                    context,
                    MaterialPageRoute<Object?>(
                      builder: (_) => ReportResidentScreen(
                        target: residentTarget,
                        viewModel: vm,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Residente reportado'), findsOneWidget);
      expect(find.text('María López Hernández'), findsOneWidget);
      expect(find.text('INC-0007 · Fuga en baño'), findsOneWidget);
      for (final reason in ConductReason.forResident) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(find.textContaining('cuenta del residente'), findsOneWidget);

      final submit = find.byKey(const Key('reportResident.submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Elige el motivo del reporte.'), findsOneWidget);
      expect(find.text('Describe lo que ocurrió'), findsOneWidget);
      expect(repository.residentReports, isEmpty);

      final reason = find.byKey(const Key('reportResident.reason.insultos'));
      await tester.ensureVisible(reason);
      await tester.tap(reason);
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('reportResident.description')),
        description,
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        repository.residentReports.single.data.reason,
        ConductReason.insults,
      );
      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(
        find.textContaining(
          'RC-0004 contra María López Hernández quedó con estado '
          '"Pendiente de revisión"',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('reportResident.done')));
      await tester.pumpAndSettle();
      expect(result, isA<ConductReport>());
    });

    testWidgets('PU-685 formulario con varios residentes: se elige a quién '
        'reportar', (tester) async {
      phoneScreen(tester);
      const target = ResidentReportTarget(
        incidentId: 'inc-1',
        incidentNumber: 'INC-0007',
        incidentTitle: 'Fuga en baño',
        residents: [registrant, chatResident],
      );
      final repository = FakeConductReportRepository();
      final vm = ReportResidentViewModel(
        target: target,
        session: sessionOf(TestUsers.technician),
        repository: repository,
        picker: FakeEvidencePicker(),
      )..selectReason(ConductReason.lackOfCooperation);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReportResidentScreen(target: target, viewModel: vm),
        ),
      );

      expect(find.text('¿A QUIÉN REPORTAS?'), findsOneWidget);
      expect(find.text('Registró la incidencia'), findsOneWidget);
      expect(find.text('Participó en el chat'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('reportResident.description')),
        description,
      );
      final submit = find.byKey(const Key('reportResident.submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Elige al residente que quieres reportar.'),
        findsOneWidget,
      );
      expect(repository.residentReports, isEmpty);
      // Se quita el aviso de campos incompletos, que tapa el botón.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();

      final carlos = find.byKey(
        const Key('reportResident.resident.uid-residente-2'),
      );
      await tester.ensureVisible(carlos);
      await tester.tap(carlos);
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        repository.residentReports.single.data.resident.id,
        'uid-residente-2',
      );
      expect(find.text('Reporte enviado'), findsOneWidget);
    });

    testWidgets('PU-686 detalle: "Reportar residente" abre el formulario y, '
        'al enviarlo, se muestra el reporte', (tester) async {
      phoneScreen(tester);
      final incidents = FakeAssignedIncidentRepository();
      final reports = FakeConductReportRepository();
      addTearDown(reports.close);
      final vm = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
        session: sessionOf(TestUsers.technician),
        repository: incidents,
        conductReports: reports,
      );
      addTearDown(vm.dispose);
      final opened = <Object?>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianIncidentDetailScreen(
            incidentId: 'inc-1',
            viewModel: vm,
          ),
          onGenerateRoute: (settings) {
            expect(settings.name, RouteNames.reportResident);
            opened.add(settings.arguments);
            return MaterialPageRoute<dynamic>(
              settings: settings,
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.pop(context, residentReport()),
                  child: const Text('Enviar'),
                ),
              ),
            );
          },
        ),
      );

      // En proceso: no aparece la opción.
      incidents.detailController.add(
        assignedItem(incident(status: IncidentStatus.inProgress)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reportar residente'), findsNothing);

      // Mientras se consulta se muestra un indicador.
      incidents.detailController.add(assignedItem(incident()));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      reports.reportsChanges.add(const []);
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('detail.reportResident'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final target = opened.single as ResidentReportTarget;
      expect(target.residents, [registrant]);

      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Reportar residente'), findsNothing);
      expect(find.text('Reportaste a María López Hernández'), findsOneWidget);
      expect(find.text('RC-0004 · Pendiente de revisión'), findsOneWidget);
    });
  });
}
