import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/data/models/start_attention_plan.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/usecases/start_attention.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/widgets/assigned_detail_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.4 Consultar detalles y evidencias de una incidencia: reglas para
/// comenzar la atención, datos y textos calculados.
void main() {
  group('comenzar atención', () {
    test('PU-528 solo el técnico asignado comienza una incidencia '
        'Asignada', () {
      Map<String, dynamic> incident(String status, {String? technician}) => {
        'estado': status,
        'tecnicoId': technician ?? technicianId,
      };
      void validate(Map<String, dynamic>? data) => StartAttentionPlan.validate(
        incident: data,
        technician: const {'rol': 'tecnico', 'estadoCuenta': 'activa'},
        technicianId: technicianId,
        now: DateTime(2026, 11, 9),
      );

      expect(() => validate(incident('asignada')), returnsNormally);
      expect(
        () => validate(incident('asignada', technician: 'otro-tecnico')),
        throwsA(isA<NotAssignedToTechnicianException>()),
      );
      expect(
        () => validate(null),
        throwsA(isA<NotAssignedToTechnicianException>()),
      );
      expect(
        () => validate(incident('en_proceso')),
        throwsA(isA<AttentionAlreadyStartedException>()),
      );
      for (final status in ['pendiente', 'resuelta', 'rechazada']) {
        expect(
          () => validate(incident(status)),
          throwsA(isA<AttentionNotAvailableException>()),
        );
      }

      final update = StartAttentionPlan.incidentUpdate;
      expect(update['estado'], 'en_proceso');
      expect(update['fechaInicioAtencion'], isA<FieldValue>());

      final notice = StartAttentionPlan.residentNotice(
        residentId: 'res-ana',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga 1',
        technicianName: 'Juan Pérez',
      );
      expect(notice['usuarioId'], 'res-ana');
      expect(notice['tipo'], StartAttentionPlan.inProgressType);
      expect(notice['titulo'], 'Incidencia INC-0001 en proceso');
      expect(notice['mensaje'], 'Juan Pérez comenzó a atender "Fuga 1".');
      expect(notice['refId'], 'inc-1');
      expect(notice['leida'], isFalse);
    });

    test('PU-529 el repositorio guarda el inicio y traduce los '
        'errores', () async {
      final remote = FakeAssignedIncidentRemoteDataSource();
      final repository = AssignedIncidentRepositoryImpl(remote: remote);

      await repository.startAttention(
        incidentId: 'inc-1',
        technicianId: technicianId,
      );
      expect(remote.started, [
        (incidentId: 'inc-1', technicianId: technicianId),
      ]);

      for (final (error, failure) in <(Object, IncidentFailure)>[
        (
          const NotAssignedToTechnicianException(),
          IncidentFailure.notAssignedToYou,
        ),
        (
          const AttentionAlreadyStartedException(),
          IncidentFailure.attentionAlreadyStarted,
        ),
        (
          const AttentionNotAvailableException(IncidentStatus.pending),
          IncidentFailure.attentionNotAvailable,
        ),
        (
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
          IncidentFailure.offline,
        ),
        (
          FirebaseException(plugin: 'cloud_firestore', code: 'aborted'),
          IncidentFailure.actionFailed,
        ),
      ]) {
        remote.startError = error;
        await expectLater(
          repository.startAttention(
            incidentId: 'inc-1',
            technicianId: technicianId,
          ),
          throwsA(failure),
        );
      }
    });

    test('PU-530 solo un técnico puede comenzar la atención', () async {
      final repository = FakeAssignedIncidentRepository();
      final start = StartAttention(repository);

      await expectLater(
        start(technician: TestUsers.resident(), incidentId: 'inc-1'),
        throwsA(IncidentFailure.assignedAccessDenied),
      );
      expect(repository.started, isEmpty);

      await start(technician: TestUsers.technician, incidentId: 'inc-1');
      expect(repository.started, [
        (incidentId: 'inc-1', technicianId: technicianId),
      ]);
    });
  });

  test('PU-531 cuenta el tiempo para la llegada y resume las '
      'evidencias', () {
    final now = DateTime(2026, 11, 9, 9);
    String countdown(Duration offset) =>
        AssignedIncidentDetailViewModel.countdown(now.add(offset), now);

    expect(countdown(const Duration(minutes: 45)), 'Faltan 45 min');
    expect(
      countdown(const Duration(hours: 2, minutes: 15)),
      'Faltan 2 h 15 min',
    );
    expect(countdown(const Duration(hours: 3)), 'Faltan 3 h');
    expect(countdown(const Duration(days: 1, hours: 3)), 'Faltan 1 d 3 h');
    expect(
      countdown(const Duration(minutes: -30)),
      'La hora estimada pasó hace 30 min',
    );
    expect(countdown(Duration.zero), 'Es la hora estimada de llegada');

    const photo = 'https://res.cloudinary.com/fixo/image/upload/a.jpg';
    const video = 'https://res.cloudinary.com/fixo/video/upload/b.mp4';
    expect(AssignedEvidenceSection.summaryOf(const []), isNull);
    expect(AssignedEvidenceSection.summaryOf(const [photo]), '1 foto');
    expect(
      AssignedEvidenceSection.summaryOf(const [photo, photo, video]),
      '2 fotos · 1 video',
    );
    expect(AssignedEvidenceSection.summaryOf(const [video, video]), '2 videos');
  });
}
