import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/conduct_report_failure.dart';
import 'package:fixo/features/admin/data/models/conduct_review_plan.dart';
import 'package:fixo/features/admin/data/repositories/conduct_review_repository_impl.dart';
import 'package:fixo/features/admin/presentation/providers/conduct_review_view_model.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_model.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:flutter_test/flutter_test.dart';

import 'conduct_review_fakes.dart';

/// HU-7.3 Revisar y validar reportes de conducta: datos, reglas y
/// ViewModel.
void main() {
  const admin = {'rol': 'admin', 'estadoCuenta': 'activa', 'nombre': 'Ana'};
  const pendingDoc = {'estado': 'pendiente_revision'};

  group('estructura de datos', () {
    test('PU-687 los estados de revisión y sus etiquetas', () {
      expect(
        ConductReportStatus.values.map((s) => (s.value, s.label)),
        [
          ('pendiente_revision', 'Pendiente de revisión'),
          ('validado', 'Validado'),
          ('rechazado', 'Rechazado'),
        ],
      );
      expect(conductReport().isPendingReview, isTrue);
      expect(
        conductReport(status: ConductReportStatus.validated).isPendingReview,
        isFalse,
      );
    });

    test('PU-688 lee los datos de la revisión del documento', () {
      Map<String, dynamic> doc(Map<String, dynamic> extra) => {
        'folio': 4,
        'incidenciaId': 'inc-7',
        'incidenciaFolio': 7,
        'incidenciaTitulo': 'Fuga en baño',
        'reportanteId': 'uid-residente',
        'reportanteNombre': 'María López',
        'reportanteRol': 'residente',
        'reportadoId': 'uid-tec',
        'reportadoNombre': 'Juan Pérez',
        'reportadoRol': 'tecnico',
        'motivo': 'mala_actitud',
        'descripcion': 'Fue grosero.',
        'evidencias': ['https://x/a.jpg'],
        'fechaCreacion': Timestamp.fromDate(DateTime(2026, 11, 20)),
        ...extra,
      };

      final reviewed = ConductReportModel.fromMap(
        'rep-4',
        doc({
          'estado': 'validado',
          'fechaRevision': Timestamp.fromDate(DateTime(2026, 11, 21, 10)),
          'revisadoPorId': 'uid-admin',
          'revisadoPorNombre': 'Ana Admin',
        }),
      );
      expect(reviewed.status, ConductReportStatus.validated);
      expect(reviewed.reportNumber, 'RC-0004');
      expect(reviewed.incidentNumber, 'INC-0007');
      expect(reviewed.reviewedAt, DateTime(2026, 11, 21, 10));
      expect(reviewed.reviewerId, 'uid-admin');
      expect(reviewed.reviewerName, 'Ana Admin');

      // Los reportes de la HU 7.1 y 7.2 aún no tienen revisión.
      final pending = ConductReportModel.fromMap(
        'rep-5',
        doc({'estado': 'pendiente_revision'}),
      );
      expect(pending.reviewedAt, isNull);
      expect(pending.reviewerName, isNull);
      expect(
        () => ConductReportModel.fromMap('x', doc({'estado': 'Validado'})),
        throwsFormatException,
      );
    });
  });

  group('reglas de la revisión', () {
    test('PU-689 un administrador activo valida o rechaza un reporte '
        'pendiente', () {
      for (final decision in [
        ConductReportStatus.validated,
        ConductReportStatus.rejected,
      ]) {
        expect(
          () => ConductReviewPlan.validate(
            report: pendingDoc,
            reviewer: admin,
            decision: decision,
          ),
          returnsNormally,
        );
      }
    });

    test('PU-690 no se revisa sin un administrador activo, sin reporte, '
        'si ya se revisó o con otra decisión', () {
      void expectFailure(
        ConductReportFailure failure, {
        Map<String, dynamic>? report = pendingDoc,
        Map<String, dynamic>? reviewer = admin,
        ConductReportStatus decision = ConductReportStatus.validated,
      }) {
        expect(
          () => ConductReviewPlan.validate(
            report: report,
            reviewer: reviewer,
            decision: decision,
          ),
          throwsA(failure),
        );
      }

      expectFailure(
        ConductReportFailure.invalidDecision,
        decision: ConductReportStatus.pendingReview,
      );
      expectFailure(ConductReportFailure.notAdmin, reviewer: null);
      expectFailure(
        ConductReportFailure.notAdmin,
        reviewer: {'rol': 'residente', 'estadoCuenta': 'activa'},
      );
      expectFailure(
        ConductReportFailure.notAdmin,
        reviewer: {'rol': 'admin', 'estadoCuenta': 'suspendida'},
      );
      expectFailure(ConductReportFailure.reportNotFound, report: null);
      expectFailure(
        ConductReportFailure.alreadyReviewed,
        report: {'estado': 'validado'},
      );
      expectFailure(
        ConductReportFailure.alreadyReviewed,
        report: {'estado': 'rechazado'},
        decision: ConductReportStatus.validated,
      );
    });

    test('PU-691 cambios guardados: estado, fecha y quién revisó, sin '
        'tocar al usuario reportado', () {
      final update = ConductReviewPlan.reportUpdate(
        decision: ConductReportStatus.rejected,
        reviewerId: 'uid-admin',
        reviewerName: 'Ana Admin',
      );

      expect(update['estado'], 'rechazado');
      expect(update['fechaRevision'], isA<FieldValue>());
      expect(update['revisadoPorId'], 'uid-admin');
      expect(update['revisadoPorNombre'], 'Ana Admin');
      // El contador, la conducta y las sanciones son de la HU 7.4.
      expect(update.keys, {
        'estado',
        'fechaRevision',
        'revisadoPorId',
        'revisadoPorNombre',
      });
    });
  });

  group('repositorio', () {
    test('PU-692 entrega los reportes y traduce los errores al cargar', () {
      final remote = FakeConductReviewRemoteDataSource();
      final repository = ConductReviewRepositoryImpl(remote: remote);
      final report = conductReport();

      expect(
        repository.watchAll(),
        emitsInOrder([
          [report],
          emitsError(ConductReportFailure.reportsLoadFailed),
          emitsError(ConductReportFailure.notAdmin),
        ]),
      );
      remote.controller
        ..add([report])
        ..addError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        )
        ..addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
    });

    test('PU-693 guarda la decisión y traduce los errores al revisar', () async {
      final remote = FakeConductReviewRemoteDataSource();
      final repository = ConductReviewRepositoryImpl(remote: remote);

      await repository.review(
        reportId: 'rep-1',
        reviewerId: 'uid-admin',
        decision: ConductReportStatus.validated,
      );
      expect(remote.reviews.single, (
        reportId: 'rep-1',
        reviewerId: 'uid-admin',
        decision: ConductReportStatus.validated,
      ));

      Future<void> failWith(Object error, ConductReportFailure failure) async {
        remote.reviewError = error;
        await expectLater(
          repository.review(
            reportId: 'rep-1',
            reviewerId: 'uid-admin',
            decision: ConductReportStatus.rejected,
          ),
          throwsA(failure),
        );
      }

      await failWith(
        ConductReportFailure.alreadyReviewed,
        ConductReportFailure.alreadyReviewed,
      );
      await failWith(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ConductReportFailure.reviewNetwork,
      );
      await failWith(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        ConductReportFailure.reportNotFound,
      );
      await failWith(Exception('otro'), ConductReportFailure.reviewFailed);
    });
  });

  group('ViewModel', () {
    late FakeConductReviewRepository repository;
    late ConductReviewViewModel viewModel;

    setUp(() {
      repository = FakeConductReviewRepository();
      viewModel = ConductReviewViewModel(
        repository: repository,
        currentUserId: () => 'uid-admin',
      );
    });

    tearDown(() => viewModel.dispose());

    Future<void> load() async {
      viewModel.start();
      repository.emit();
      await pumpEventQueue();
    }

    test('PU-694 consulta todos los reportes, los cuenta y filtra por '
        'estado', () async {
      expect(viewModel.isLoading, isTrue);
      await load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.all.map((r) => r.reportNumber), [
        'RC-0001',
        'RC-0002',
        'RC-0003',
      ]);
      expect(viewModel.countOf(null), 3);
      expect(viewModel.countOf(ConductReportStatus.pendingReview), 1);
      expect(viewModel.countOf(ConductReportStatus.validated), 1);
      expect(viewModel.countOf(ConductReportStatus.rejected), 1);

      viewModel.setStatusFilter(ConductReportStatus.validated);
      expect(viewModel.reports.single.reportNumber, 'RC-0002');
      viewModel.setStatusFilter(null);
      expect(viewModel.reports, hasLength(3));
      expect(viewModel.findById('inc-9_uid-residente')!.folio, 3);
    });

    test('PU-695 muestra el error si no se pueden cargar', () async {
      viewModel.start();
      repository.controller.addError(ConductReportFailure.reportsLoadFailed);
      await pumpEventQueue();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.all, isEmpty);
      expect(
        viewModel.errorMessage,
        ConductReportFailure.reportsLoadFailed.message,
      );
    });

    test('PU-696 marca un reporte pendiente como Validado', () async {
      await load();

      final ok = await viewModel.validate(viewModel.all.first);
      await pumpEventQueue();

      expect(ok, isTrue);
      expect(repository.reviews.single, (
        reportId: 'inc-7_uid-residente',
        reviewerId: 'uid-admin',
        decision: ConductReportStatus.validated,
      ));
      expect(viewModel.successMessage, 'Reporte RC-0001 marcado como Validado.');
      expect(viewModel.all.first.status, ConductReportStatus.validated);
      expect(viewModel.isSaving, isFalse);
    });

    test('PU-697 marca un reporte pendiente como Rechazado', () async {
      await load();

      final ok = await viewModel.reject(viewModel.all.first);
      await pumpEventQueue();

      expect(ok, isTrue);
      expect(repository.reviews.single.decision, ConductReportStatus.rejected);
      expect(
        viewModel.successMessage,
        'Reporte RC-0001 marcado como Rechazado.',
      );
      expect(viewModel.all.first.status, ConductReportStatus.rejected);
    });

    test('PU-698 un reporte ya revisado no se vuelve a revisar', () async {
      await load();

      final ok = await viewModel.reject(viewModel.all[1]);

      expect(ok, isFalse);
      expect(repository.reviews, isEmpty);
      expect(
        viewModel.errorMessage,
        ConductReportFailure.alreadyReviewed.message,
      );
    });

    test('PU-699 si otro administrador lo revisó antes, se avisa', () async {
      await load();
      final stale = viewModel.all.first;
      // Otro administrador lo valida; a esta sesión aún no le llega.
      repository.reports = [
        conductReport(status: ConductReportStatus.validated),
        ...repository.reports.skip(1),
      ];
      expect(viewModel.all.first.isPendingReview, isTrue);

      final ok = await viewModel.reject(stale);

      expect(ok, isFalse);
      expect(repository.reviews, isEmpty);
      expect(
        viewModel.errorMessage,
        ConductReportFailure.alreadyReviewed.message,
      );
    });

    test('PU-700 sin conexión o sin sesión no se guarda la revisión', () async {
      await load();
      repository.reviewError = ConductReportFailure.reviewNetwork;

      expect(await viewModel.validate(viewModel.all.first), isFalse);
      expect(viewModel.errorMessage, ConductReportFailure.reviewNetwork.message);
      expect(viewModel.all.first.isPendingReview, isTrue);
      expect(viewModel.isSaving, isFalse);

      final noSession = ConductReviewViewModel(
        repository: FakeConductReviewRepository(),
        currentUserId: () => null,
      );
      addTearDown(noSession.dispose);
      expect(await noSession.validate(conductReport()), isFalse);
      expect(noSession.errorMessage, ConductReportFailure.notAdmin.message);
    });
  });
}
