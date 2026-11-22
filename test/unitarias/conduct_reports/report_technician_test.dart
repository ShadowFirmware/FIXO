import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/conduct_report_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/validators.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_model.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_plan.dart';
import 'package:fixo/features/conduct_reports/data/repositories/conduct_report_repository_impl.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report_conditions.dart';
import 'package:fixo/features/conduct_reports/domain/usecases/report_technician.dart';
import 'package:fixo/features/conduct_reports/presentation/providers/report_technician_view_model.dart';
import 'package:fixo/features/conduct_reports/presentation/screens/report_technician_screen.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_storage_data_source.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/notifications/domain/entities/app_notification.dart';
import 'package:fixo/features/resident/presentation/providers/incident_detail_view_model.dart';
import 'package:fixo/features/resident/presentation/screens/incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';
import 'conduct_report_fakes.dart';

const description = 'Me habló de forma grosera al terminar.';
const reportId = 'inc-1_uid-residente';

/// HU-7.1 Reportar la conducta de un técnico.
void main() {
  Incident incident({
    IncidentStatus status = IncidentStatus.resolved,
    String housingId = 'vivienda-4b',
    String? technicianId = 'uid-tecnico',
  }) => Incident(
    id: 'inc-1',
    folio: 7,
    title: 'Fuga en baño',
    type: IncidentType.water,
    description: 'Gotea la llave del lavabo',
    housingId: housingId,
    createdBy: 'uid-residente',
    status: status,
    technicianId: technicianId,
    solution: status == IncidentStatus.resolved ? 'Se cambió el empaque' : null,
    resolvedAt: status == IncidentStatus.resolved
        ? DateTime(2026, 11, 20, 12)
        : null,
  );

  AuthSession sessionOf(AppUser user) =>
      AuthSession.withRepository(FakeAuthRepository())..start(user);

  group('motivos y estructura (T 7.1.3, T 7.1.7)', () {
    test('PU-648 motivos disponibles para reportar al técnico', () {
      expect(ConductReason.forTechnician.map((r) => r.label), [
        'Retraso',
        'Mala actitud',
        'Trabajo mal realizado',
        'Lenguaje inapropiado',
        'Otro motivo',
      ]);
      for (final reason in ConductReason.values) {
        expect(ConductReason.fromValue(reason.value), reason);
        expect(reason.hint, isNotEmpty);
      }
      expect(ConductReason.fromValue('desconocido'), isNull);
      expect(ConductReportStatus.pendingReview.label, 'Pendiente de revisión');
    });

    test('PU-649 lee y crea los documentos de reportes', () {
      final date = DateTime(2026, 11, 21, 10);
      final report = sentReport(
        evidence: const ['https://x/1.jpg'],
        createdAt: date,
      );
      final data = report.toFirestore();

      expect(data, {
        'folio': 3,
        'incidenciaId': 'inc-1',
        'incidenciaFolio': 7,
        'incidenciaTitulo': 'Fuga en baño',
        'reportanteId': 'uid-residente',
        'reportanteNombre': 'María López Hernández',
        'reportanteRol': 'residente',
        'reportadoId': 'uid-tecnico',
        'reportadoNombre': 'Juan Pérez Ramírez',
        'reportadoRol': 'tecnico',
        'motivo': 'mala_actitud',
        'descripcion': description,
        'evidencias': ['https://x/1.jpg'],
        'estado': 'pendiente_revision',
        'fechaCreacion': Timestamp.fromDate(date),
      });

      final read = ConductReportModel.fromMap(reportId, data);
      expect(read.id, reportId);
      expect(read.reportNumber, 'RC-0003');
      expect(read.incidentNumber, 'INC-0007');
      expect(read.reason, ConductReason.badAttitude);
      expect(read.status, ConductReportStatus.pendingReview);
      expect(read.reporterRole, UserRole.resident);
      expect(read.reportedRole, UserRole.technician);
      expect(read.evidence, ['https://x/1.jpg']);
      expect(read.createdAt, date);

      // Sin fecha, la pone el servidor.
      expect(sentReport().toFirestore()['fechaCreacion'], isA<FieldValue>());

      // Datos inválidos se rechazan.
      expect(
        () => ConductReportModel.fromMap('x', {...data, 'motivo': 'otro_x'}),
        throwsFormatException,
      );
      expect(
        () => ConductReportModel.fromMap('x', {...data, 'estado': 'abierto'}),
        throwsFormatException,
      );
      expect(
        () => ConductReportModel.fromMap('x', {...data, 'reportadoRol': null}),
        throwsFormatException,
      );

      // Solo un reporte validado cuenta como antecedente.
      expect(sentReport().countsAsRecord, isFalse);
      expect(
        sentReport(status: ConductReportStatus.rejected).countsAsRecord,
        isFalse,
      );
      expect(
        sentReport(status: ConductReportStatus.validated).countsAsRecord,
        isTrue,
      );

      // Un ID por usuario e incidencia.
      expect(
        ConductReport.docIdFor(
          incidentId: 'inc-1',
          reporterId: 'uid-residente',
        ),
        reportId,
      );
    });

    test('PU-650 descripción de lo ocurrido', () {
      expect(Validators.conductDescription(''), 'Describe lo que ocurrió');
      expect(Validators.conductDescription('   '), 'Describe lo que ocurrió');
      expect(
        Validators.conductDescription('Muy mal'),
        'La descripción debe tener al menos 10 caracteres',
      );
      expect(Validators.conductDescription('  ${'a' * 10}  '), isNull);
      expect(Validators.conductDescription('a' * 500), isNull);
      expect(
        Validators.conductDescription('a' * 501),
        'La descripción no debe pasar de 500 caracteres',
      );
    });
  });

  group('condiciones (T 7.1.5, T 7.1.6)', () {
    test('PU-651 solo se reporta al técnico de una incidencia Resuelta de la '
        'vivienda', () {
      final resident = TestUsers.resident();
      ConductReportFailure? check(Incident value, [AppUser? user]) =>
          ConductReportConditions.check(value, resident: user ?? resident);

      expect(check(incident()), isNull);
      for (final status in [
        IncidentStatus.pending,
        IncidentStatus.assigned,
        IncidentStatus.inProgress,
        IncidentStatus.rejected,
      ]) {
        expect(
          check(incident(status: status)),
          ConductReportFailure.notResolved,
          reason: status.label,
        );
      }
      expect(
        check(incident(housingId: 'otra-vivienda')),
        ConductReportFailure.notYourIncident,
      );
      expect(
        check(incident(technicianId: null)),
        ConductReportFailure.noTechnician,
      );
      expect(
        check(incident(), TestUsers.technician),
        ConductReportFailure.notResident,
      );
      expect(
        ConductReportConditions.check(incident(), resident: null),
        ConductReportFailure.notResident,
      );
      expect(
        check(incident(), TestUsers.resident(status: AccountStatus.suspended)),
        ConductReportFailure.accountNotActive,
      );

      // Solo el técnico que la atendió.
      expect(
        ConductReportConditions.checkTarget(
          incident(),
          resident: resident,
          technicianId: 'uid-tecnico',
        ),
        isNull,
      );
      expect(
        ConductReportConditions.checkTarget(
          incident(),
          resident: resident,
          technicianId: 'otro-tecnico',
        ),
        ConductReportFailure.notAttendingTechnician,
      );
    });

    test('PU-652 la transacción revisa las condiciones con los datos '
        'actuales y los reportes duplicados', () {
      void validate({
        Map<String, dynamic>? incident = const {
          'estado': 'resuelta',
          'viviendaId': 'vivienda-4b',
          'tecnicoId': 'uid-tecnico',
        },
        String role = 'residente',
        String account = 'activa',
        String? housing = 'vivienda-4b',
        String technicianId = 'uid-tecnico',
        bool alreadyReported = false,
      }) => ConductReportPlan.validate(
        incident: incident,
        reporter: {'rol': role, 'estadoCuenta': account, 'viviendaId': housing},
        technicianId: technicianId,
        alreadyReported: alreadyReported,
      );

      Matcher fails(ConductReportFailure failure) => throwsA(same(failure));

      expect(validate, returnsNormally);
      expect(
        () => validate(alreadyReported: true),
        fails(ConductReportFailure.duplicate),
      );
      expect(
        () => validate(technicianId: 'otro-tecnico'),
        fails(ConductReportFailure.notAttendingTechnician),
      );
      for (final status in ['pendiente', 'asignada', 'en_proceso']) {
        expect(
          () => validate(
            incident: {
              'estado': status,
              'viviendaId': 'vivienda-4b',
              'tecnicoId': 'uid-tecnico',
            },
          ),
          fails(ConductReportFailure.notResolved),
        );
      }
      expect(
        () => validate(
          incident: {'estado': 'resuelta', 'viviendaId': 'vivienda-4b'},
        ),
        fails(ConductReportFailure.noTechnician),
      );
      expect(
        () => validate(incident: null),
        fails(ConductReportFailure.incidentNotFound),
      );
      // El residente se cambió de vivienda después de la incidencia.
      expect(
        () => validate(housing: 'otra-vivienda'),
        fails(ConductReportFailure.notYourIncident),
      );
      expect(
        () => validate(account: 'suspendida'),
        fails(ConductReportFailure.accountNotActive),
      );
      expect(
        () => validate(role: 'tecnico'),
        fails(ConductReportFailure.notResident),
      );
      expect(
        () => ConductReportPlan.validate(
          incident: const {},
          reporter: null,
          technicianId: 'uid-tecnico',
          alreadyReported: false,
        ),
        fails(ConductReportFailure.notResident),
      );
    });
  });

  group('registro y aviso (T 7.1.7, T 7.1.8)', () {
    ConductReportModel build({Map<String, dynamic>? technician}) =>
        ConductReportPlan.build(
          id: reportId,
          folio: 12,
          incidentId: 'inc-1',
          incident: {'folio': 7, 'nombre': 'Fuga en baño'},
          reporterId: 'uid-residente',
          reporter: {'nombre': 'María López Hernández'},
          technicianId: 'uid-tecnico',
          technician: technician ?? {'nombre': 'Juan Pérez Ramírez'},
          reason: ConductReason.delay,
          description: '  $description  ',
          evidence: const ['https://x/1.jpg'],
        );

    test('PU-653 el reporte se registra Pendiente de revisión con su '
        'folio y la incidencia relacionada', () {
      final report = build();

      expect(report.id, reportId);
      expect(report.reportNumber, 'RC-0012');
      expect(report.status, ConductReportStatus.pendingReview);
      expect(report.incidentId, 'inc-1');
      expect(report.incidentNumber, 'INC-0007');
      expect(report.incidentTitle, 'Fuga en baño');
      expect(report.reporterName, 'María López Hernández');
      expect(report.reporterRole, UserRole.resident);
      expect(report.reportedId, 'uid-tecnico');
      expect(report.reportedName, 'Juan Pérez Ramírez');
      expect(report.reportedRole, UserRole.technician);
      expect(report.reason, ConductReason.delay);
      expect(report.description, description);
      expect(report.evidence, ['https://x/1.jpg']);
      expect(report.countsAsRecord, isFalse);

      // El reporte no lleva cambios para el técnico: su estado de conducta
      // y de cuenta no se tocan hasta que se valide.
      final data = report.toFirestore();
      for (final key in [
        'estadoConducta',
        'estadoCuenta',
        'reportesValidados',
      ]) {
        expect(data.containsKey(key), isFalse, reason: key);
      }

      // Si el técnico ya no existe se guarda igual.
      expect(build(technician: {}).reportedName, 'Técnico');
    });

    test('PU-654 cada administrador recibe un aviso del reporte nuevo', () {
      final notices = ConductReportPlan.notices(
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
          'Se reportó a Juan Pérez Ramírez (Técnico). Motivo: Retraso '
          '(incidencia INC-0007) Revísalo para validarlo o descartarlo.',
        );
      }
      expect(
        ConductReportPlan.notices(adminIds: const [], report: build()),
        isEmpty,
      );
    });

    test('PU-655 el caso de uso revisa al residente, la descripción y las '
        'evidencias', () async {
      final repository = FakeConductReportRepository();
      final useCase = ReportTechnician(repository);
      NewConductReport data({
        String text = '  $description ',
        int evidence = 0,
      }) => NewConductReport(
        target: target,
        reason: ConductReason.badAttitude,
        description: text,
        evidence: List.filled(evidence, photo),
      );

      await expectLater(
        useCase(resident: TestUsers.technician, data: data()),
        throwsA(same(ConductReportFailure.notResident)),
      );
      await expectLater(
        useCase(resident: null, data: data()),
        throwsA(same(ConductReportFailure.notResident)),
      );
      await expectLater(
        useCase(
          resident: TestUsers.resident(status: AccountStatus.disabled),
          data: data(),
        ),
        throwsA(same(ConductReportFailure.accountNotActive)),
      );
      await expectLater(
        useCase(
          resident: TestUsers.resident(),
          data: data(text: 'corto'),
        ),
        throwsA(isA<ConductReportIncompleteException>()),
      );
      await expectLater(
        useCase(resident: TestUsers.resident(), data: data(evidence: 6)),
        throwsA(same(ConductReportFailure.tooManyEvidence)),
      );
      expect(repository.received, isEmpty);

      final report = await useCase(
        resident: TestUsers.resident(),
        data: data(evidence: 5),
      );
      expect(report.status, ConductReportStatus.pendingReview);
      final sent = repository.received.single;
      expect(sent.reporterId, 'uid-residente');
      expect(sent.data.description, description);
      expect(sent.data.target.technicianId, 'uid-tecnico');
      expect(sent.data.evidence, hasLength(5));
    });

    test('PU-656 el repositorio revisa duplicados antes de subir las '
        'evidencias, guarda y avisa', () async {
      final remote = FakeConductReportRemoteDataSource(
        adminIds: ['uid-admin', 'uid-admin-2'],
      );
      final storage = FakeEvidenceStorage();
      final repository = ConductReportRepositoryImpl(
        remote: remote,
        storage: storage,
      );

      final report = await repository.reportTechnician(
        reporterId: 'uid-residente',
        data: const NewConductReport(
          target: target,
          reason: ConductReason.poorWork,
          description: description,
          evidence: [photo, video],
        ),
      );

      expect(remote.checked, [reportId]);
      expect(storage.conductUploads, [reportId]);
      final created = remote.created.single;
      expect(created.incidentId, 'inc-1');
      expect(created.reporterId, 'uid-residente');
      expect(created.technicianId, 'uid-tecnico');
      expect(created.reason, ConductReason.poorWork);
      expect(created.evidence, [
        'https://storage/reportes/$reportId/1.jpg',
        'https://storage/reportes/$reportId/2.mp4',
      ]);
      expect(created.adminIds, ['uid-admin', 'uid-admin-2']);
      expect(report.evidence, hasLength(2));

      // Sin evidencias también se puede reportar.
      await repository.reportTechnician(
        reporterId: 'uid-residente',
        data: const NewConductReport(
          target: target,
          reason: ConductReason.other,
          description: description,
        ),
      );
      expect(remote.created.last.evidence, isEmpty);
    });

    test('PU-657 el repositorio traduce los errores', () async {
      Future<void> report({
        Set<String> existing = const {},
        Object? createError,
        EvidenceUploadException? uploadError,
        FakeEvidenceStorage? storage,
      }) =>
          ConductReportRepositoryImpl(
            remote: FakeConductReportRemoteDataSource(
              existing: existing,
              createError: createError,
            ),
            storage: storage ?? FakeEvidenceStorage(error: uploadError),
          ).reportTechnician(
            reporterId: 'uid-residente',
            data: const NewConductReport(
              target: target,
              reason: ConductReason.delay,
              description: description,
              evidence: [photo],
            ),
          );

      // Ya existe: no se suben las evidencias.
      final storage = FakeEvidenceStorage();
      await expectLater(
        report(existing: {reportId}, storage: storage),
        throwsA(same(ConductReportFailure.duplicate)),
      );
      expect(storage.conductUploads, isEmpty);

      // Otro reporte se registró al mismo tiempo: lo detecta la transacción.
      await expectLater(
        report(createError: ConductReportFailure.duplicate),
        throwsA(same(ConductReportFailure.duplicate)),
      );
      await expectLater(
        report(createError: ConductReportFailure.notResolved),
        throwsA(same(ConductReportFailure.notResolved)),
      );
      await expectLater(
        report(uploadError: const EvidenceUploadException(network: true)),
        throwsA(same(ConductReportFailure.network)),
      );
      await expectLater(
        report(uploadError: const EvidenceUploadException()),
        throwsA(same(ConductReportFailure.evidenceUpload)),
      );
      await expectLater(
        report(
          createError: FirebaseException(plugin: 'x', code: 'unavailable'),
        ),
        throwsA(same(ConductReportFailure.network)),
      );
      await expectLater(
        report(
          createError: FirebaseException(
            plugin: 'x',
            code: 'permission-denied',
          ),
        ),
        throwsA(same(ConductReportFailure.permissionDenied)),
      );
      await expectLater(
        report(createError: StateError('x')),
        throwsA(same(ConductReportFailure.unknown)),
      );
    });

    test('PU-658 consultar el reporte propio de la incidencia', () async {
      final remote = FakeConductReportRemoteDataSource();
      final repository = ConductReportRepositoryImpl(
        remote: remote,
        storage: FakeEvidenceStorage(),
      );
      final received = <ConductReport?>[];
      final errors = <Object>[];
      final subscription = repository
          .watchOwn(incidentId: 'inc-1', reporterId: 'uid-residente')
          .listen(received.add, onError: errors.add);
      addTearDown(subscription.cancel);

      remote.changes
        ..add(null)
        ..add(sentReport())
        ..addError(FirebaseException(plugin: 'x', code: 'unavailable'))
        ..addError(const FormatException('x'));
      await pumpEventQueue();

      expect(remote.watchedIds, [reportId]);
      expect(received, [null, isA<ConductReport>()]);
      expect(errors, [
        same(ConductReportFailure.network),
        same(ConductReportFailure.loadFailed),
      ]);
    });
  });

  group('formulario (T 7.1.2 a T 7.1.4)', () {
    late FakeConductReportRepository repository;

    ReportTechnicianViewModel viewModel({
      FakeEvidencePicker? picker,
      AppUser? user,
    }) {
      final vm = ReportTechnicianViewModel(
        target: target,
        session: sessionOf(user ?? TestUsers.resident()),
        repository: repository,
        picker: picker ?? FakeEvidencePicker(),
      );
      addTearDown(vm.dispose);
      return vm;
    }

    setUp(() => repository = FakeConductReportRepository());

    test('PU-659 se pide el motivo y la descripción antes de enviar', () async {
      final vm = viewModel();
      expect(vm.reasons, ConductReason.forTechnician);
      expect(vm.reason, isNull);

      expect(await vm.submit(), isNull);
      expect(vm.reasonError, 'Elige el motivo del reporte.');
      expect(vm.errorMessage, 'Elige el motivo del reporte.');

      vm.selectReason(ConductReason.badAttitude);
      expect(vm.reasonError, isNull);
      expect(await vm.submit(), isNull);
      expect(vm.errorMessage, 'Describe lo que ocurrió');
      expect(repository.received, isEmpty);

      vm.description = description;
      final report = await vm.submit();
      expect(report?.reportNumber, 'RC-0003');
      expect(vm.errorMessage, isNull);
      final sent = repository.received.single;
      expect(sent.reporterId, 'uid-residente');
      expect(sent.data.reason, ConductReason.badAttitude);
      expect(sent.data.target.incidentId, 'inc-1');
      expect(sent.data.evidence, isEmpty);
    });

    test('PU-660 evidencias opcionales: fotos, videos o capturas con '
        'límites', () async {
      final big = EvidenceFile(
        path: '/videos/largo.mp4',
        isVideo: true,
        sizeBytes: ReportTechnicianViewModel.maxVideoBytes + 1,
      );
      final vm = viewModel(
        picker: FakeEvidencePicker(photos: List.filled(4, photo), video: big),
      );

      await vm.addPhotos(fromCamera: false);
      expect(vm.evidence, hasLength(4));
      await vm.addVideo(fromCamera: false);
      expect(vm.evidence, hasLength(4));
      expect(
        vm.evidenceMessage,
        'Las fotos pueden pesar hasta 10 MB y los videos hasta 50 MB.',
      );

      await vm.addPhotos(fromCamera: false);
      expect(vm.evidence, hasLength(5));
      expect(vm.evidenceMessage, 'Solo puedes adjuntar hasta 5 evidencias.');
      expect(vm.canAddEvidence, isFalse);

      vm.removeEvidence(vm.evidence.first);
      expect(vm.evidence, hasLength(4));
      expect(vm.evidenceMessage, isNull);

      vm
        ..selectReason(ConductReason.poorWork)
        ..description = description;
      await vm.submit();
      expect(repository.received.single.data.evidence, hasLength(4));
    });

    test('PU-661 envío en curso y errores del envío', () async {
      final gate = repository.gate = Completer<void>();
      final vm = viewModel()
        ..selectReason(ConductReason.delay)
        ..description = description;

      final first = vm.submit();
      expect(vm.isSaving, isTrue);
      expect(vm.canAddEvidence, isFalse);
      expect(await vm.submit(), isNull);
      gate.complete();
      expect(await first, isNotNull);
      expect(repository.received, hasLength(1));
      expect(vm.isSaving, isFalse);

      repository
        ..gate = null
        ..error = ConductReportFailure.duplicate;
      expect(await vm.submit(), isNull);
      expect(vm.errorMessage, ConductReportFailure.duplicate.message);

      // Sin cuenta activa no se envía.
      final suspended =
          viewModel(user: TestUsers.resident(status: AccountStatus.suspended))
            ..selectReason(ConductReason.delay)
            ..description = description;
      expect(await suspended.submit(), isNull);
      expect(
        suspended.errorMessage,
        ConductReportFailure.accountNotActive.message,
      );
    });
  });

  group('opción en el detalle (T 7.1.1)', () {
    late FakeIncidentRepository incidents;
    late FakeConductReportRepository reports;

    IncidentDetailViewModel detail({AppUser? user}) {
      final vm = IncidentDetailViewModel(
        incidentId: 'inc-1',
        session: sessionOf(user ?? TestUsers.resident()),
        incidents: incidents,
        housings: FakeHousingRepository(),
        technicians: FakeTechnicianRepository(
          technicians: {'uid-tecnico': TestUsers.technician},
        ),
        conductReports: reports,
      );
      addTearDown(vm.dispose);
      return vm;
    }

    Future<void> emit(Incident value) async {
      incidents.changes.add(value);
      await pumpEventQueue();
    }

    setUp(() {
      incidents = FakeIncidentRepository();
      reports = FakeConductReportRepository();
    });
    tearDown(() => reports.close());

    test('PU-662 solo aparece en incidencias resueltas', () async {
      final vm = detail();
      for (final status in [
        IncidentStatus.pending,
        IncidentStatus.assigned,
        IncidentStatus.inProgress,
        IncidentStatus.rejected,
      ]) {
        await emit(incident(status: status));
        expect(vm.showConductSection, isFalse, reason: status.label);
        expect(vm.canReportTechnician, isFalse, reason: status.label);
        expect(vm.reportTarget, isNull, reason: status.label);
      }
      // Mientras no esté resuelta ni siquiera se consulta.
      expect(reports.watched, isEmpty);

      await emit(incident());
      expect(vm.showConductSection, isTrue);
      expect(reports.watched, [
        (incidentId: 'inc-1', reporterId: 'uid-residente'),
      ]);
      expect(vm.isReportLoading, isTrue);
      expect(vm.canReportTechnician, isFalse);

      reports.changes.add(null);
      await pumpEventQueue();
      expect(vm.isReportLoading, isFalse);
      expect(vm.canReportTechnician, isTrue);
      final target = vm.reportTarget!;
      expect(target.incidentId, 'inc-1');
      expect(target.incidentNumber, 'INC-0007');
      expect(target.technicianId, 'uid-tecnico');
      expect(target.technicianName, 'Juan Pérez Ramírez');

      // Una resuelta sin técnico (capturada a mano) no muestra la opción.
      await emit(incident(technicianId: null));
      expect(vm.showConductSection, isFalse);
    });

    test('PU-663 si ya lo reportó, se muestra su reporte en lugar de la '
        'opción', () async {
      final vm = detail();
      await emit(incident());
      reports.changes.add(sentReport());
      await pumpEventQueue();

      expect(vm.ownReport?.reportNumber, 'RC-0003');
      expect(vm.reportBlockReason, ConductReportFailure.duplicate);
      expect(vm.canReportTechnician, isFalse);
      expect(vm.reportTarget, isNull);

      // Recién enviado, antes de que llegue de Firestore.
      final other = detail();
      await emit(incident());
      reports.changes.add(null);
      await pumpEventQueue();
      expect(other.canReportTechnician, isTrue);
      other.reportSent(sentReport(folio: 9));
      expect(other.ownReport?.reportNumber, 'RC-0009');
      expect(other.canReportTechnician, isFalse);
    });

    test('PU-664 error al consultar y cuenta no activa', () async {
      final vm = detail();
      await emit(incident());
      reports.changes.addError(ConductReportFailure.network);
      await pumpEventQueue();
      expect(vm.reportError, ConductReportFailure.network.message);
      expect(vm.canReportTechnician, isFalse);

      final suspended = detail(
        user: TestUsers.resident(status: AccountStatus.suspended),
      );
      await emit(incident());
      reports.changes.add(null);
      await pumpEventQueue();
      expect(
        suspended.reportBlockReason,
        ConductReportFailure.accountNotActive,
      );
      expect(suspended.canReportTechnician, isFalse);
    });
  });

  group('pantallas (T 7.1.1, T 7.1.2)', () {
    /// Pantalla alta de teléfono, para que la barra superior no tape los
    /// campos al tocarlos.
    void phoneScreen(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(430, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('PU-665 formulario: técnico fijo, motivo, descripción y '
        'confirmación', (tester) async {
      phoneScreen(tester);
      final repository = FakeConductReportRepository();
      final vm = ReportTechnicianViewModel(
        target: target,
        session: sessionOf(TestUsers.resident()),
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
                      builder: (_) =>
                          ReportTechnicianScreen(target: target, viewModel: vm),
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

      // Solo se puede reportar al técnico que atendió la incidencia.
      expect(find.text('Juan Pérez Ramírez'), findsOneWidget);
      expect(find.text('INC-0007 · Fuga en baño'), findsOneWidget);
      for (final reason in ConductReason.forTechnician) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(find.textContaining('Pendiente de revisión'), findsOneWidget);

      // Sin datos no se envía.
      final submit = find.byKey(const Key('reportTechnician.submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Elige el motivo del reporte.'), findsOneWidget);
      expect(find.text('Describe lo que ocurrió'), findsOneWidget);
      expect(repository.received, isEmpty);

      final reason = find.byKey(const Key('reportTechnician.reason.retraso'));
      await tester.ensureVisible(reason);
      await tester.tap(reason);
      await tester.pump();
      expect(find.text(ConductReason.delay.hint), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('reportTechnician.description')),
        description,
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.received.single.data.reason, ConductReason.delay);
      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(
        find.textContaining('RC-0003 quedó con estado "Pendiente de revisión"'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('reportTechnician.done')));
      await tester.pumpAndSettle();
      expect(result, isA<ConductReport>());
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('PU-666 formulario: si falla el envío se avisa y se conserva '
        'lo escrito', (tester) async {
      phoneScreen(tester);
      final repository = FakeConductReportRepository(
        error: ConductReportFailure.duplicate,
      );
      final vm = ReportTechnicianViewModel(
        target: target,
        session: sessionOf(TestUsers.resident()),
        repository: repository,
        picker: FakeEvidencePicker(),
      )..selectReason(ConductReason.other);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReportTechnicianScreen(target: target, viewModel: vm),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('reportTechnician.description')),
        description,
      );
      final submit = find.byKey(const Key('reportTechnician.submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text(ConductReportFailure.duplicate.message), findsWidgets);
      expect(find.text('Reporte enviado'), findsNothing);
      expect(find.text(description), findsOneWidget);
    });

    testWidgets('PU-667 detalle: "Reportar técnico" abre el formulario y, al '
        'enviarlo, se muestra el reporte', (tester) async {
      phoneScreen(tester);
      final incidents = FakeIncidentRepository();
      final reports = FakeConductReportRepository();
      final vm = IncidentDetailViewModel(
        incidentId: 'inc-1',
        session: sessionOf(TestUsers.resident()),
        incidents: incidents,
        housings: FakeHousingRepository(),
        technicians: FakeTechnicianRepository(
          technicians: {'uid-tecnico': TestUsers.technician},
        ),
        conductReports: reports,
      );
      addTearDown(vm.dispose);
      final opened = <Object?>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: IncidentDetailScreen(incidentId: 'inc-1', viewModel: vm),
          onGenerateRoute: (settings) {
            expect(settings.name, RouteNames.reportTechnician);
            opened.add(settings.arguments);
            return MaterialPageRoute<Object?>(
              settings: settings,
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.pop(context, sentReport()),
                  child: const Text('Enviar'),
                ),
              ),
            );
          },
        ),
      );

      // En proceso: no aparece la opción.
      incidents.changes.add(incident(status: IncidentStatus.inProgress));
      await tester.pumpAndSettle();
      expect(find.text('Reportar técnico'), findsNothing);

      // Mientras se consulta si ya lo reportó se muestra un indicador.
      incidents.changes.add(incident());
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      reports.changes.add(null);
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('detail.reportTechnician'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final target = opened.single as ConductReportTarget;
      expect(target.technicianName, 'Juan Pérez Ramírez');

      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Reportar técnico'), findsNothing);
      expect(find.text('Ya reportaste al técnico'), findsOneWidget);
      expect(find.text('RC-0003 · Pendiente de revisión'), findsOneWidget);
    });
  });
}
