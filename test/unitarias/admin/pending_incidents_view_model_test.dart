import 'dart:async';

import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/admin/data/repositories/incident_admin_repository_impl.dart';
import 'package:fixo/features/admin/domain/entities/pending_incident.dart';
import 'package:fixo/features/admin/domain/repositories/incident_admin_repository.dart';
import 'package:fixo/features/admin/presentation/providers/pending_incidents_view_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident(int folio, IncidentType type, DateTime? createdAt) =>
    Incident(
      id: 'inc-$folio',
      folio: folio,
      title: 'Incidencia $folio',
      type: type,
      description: 'Detalles $folio',
      housingId: 'viv-1',
      createdBy: 'res-1',
      status: IncidentStatus.pending,
      createdAt: createdAt,
    );

PendingIncident _pending(Incident incident) => PendingIncident(
  incident: incident,
  housingLabel: 'Torre A – 4B',
  reporterName: 'Ana López',
);

class FakeIncidentAdminRepository implements IncidentAdminRepository {
  final controller = StreamController<List<PendingIncident>>.broadcast();
  Object? actionError;
  final assigned = <String>[];
  final rejected = <String, String>{};

  @override
  Stream<List<PendingIncident>> watchPending() => controller.stream;

  @override
  Future<List<AppUser>> availableTechnicians() async => const [];

  @override
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  }) async {
    if (actionError != null) throw actionError!;
    assigned.add(incidentId);
  }

  @override
  Future<void> reject({
    required String incidentId,
    required String comment,
  }) async {
    if (actionError != null) throw actionError!;
    rejected[incidentId] = comment;
  }
}

void main() {
  group('Orden por fecha de creación (CA-3)', () {
    test('las más antiguas primero; sin fecha al final', () {
      final list = [
        _incident(3, IncidentType.water, DateTime(2026, 10, 3)),
        _incident(4, IncidentType.water, null),
        _incident(1, IncidentType.water, DateTime(2026, 10, 1)),
        _incident(2, IncidentType.water, DateTime(2026, 10, 2)),
      ]..sort(IncidentAdminRepositoryImpl.compareOldestFirst);
      expect(list.map((i) => i.folio), [1, 2, 3, 4]);
    });

    test('a igual fecha se ordena por folio', () {
      final date = DateTime(2026, 10, 1);
      final list = [
        _incident(5, IncidentType.water, date),
        _incident(2, IncidentType.water, date),
      ]..sort(IncidentAdminRepositoryImpl.compareOldestFirst);
      expect(list.map((i) => i.folio), [2, 5]);
    });
  });

  group('PendingIncidentsViewModel', () {
    late FakeIncidentAdminRepository repository;
    late PendingIncidentsViewModel viewModel;

    final items = [
      _pending(_incident(1, IncidentType.water, DateTime(2026, 10, 1))),
      _pending(_incident(2, IncidentType.electricity, DateTime(2026, 10, 2))),
      _pending(_incident(3, IncidentType.water, DateTime(2026, 10, 3))),
      _pending(_incident(4, IncidentType.structure, DateTime(2026, 10, 4))),
    ];

    setUp(() {
      repository = FakeIncidentAdminRepository();
      viewModel = PendingIncidentsViewModel(repository: repository)..start();
    });

    tearDown(() => viewModel.dispose());

    test('inicia cargando y muestra lo que llega de Firestore (CA-1, CA-5)',
        () async {
      expect(viewModel.isLoading, isTrue);
      repository.controller.add(items);
      await pumpEventQueue();
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.all, hasLength(4));
    });

    test('el inicio muestra solo las 3 más antiguas', () async {
      repository.controller.add(items);
      await pumpEventQueue();
      expect(viewModel.preview.map((p) => p.incident.folio), [1, 2, 3]);
      expect(viewModel.hasMore, isTrue);
    });

    test('filtra por tipo (CA-4)', () async {
      repository.controller.add(items);
      await pumpEventQueue();
      viewModel.setTypeFilter(IncidentType.water);
      expect(viewModel.incidents.map((p) => p.incident.folio), [1, 3]);
      viewModel.setTypeFilter(null);
      expect(viewModel.incidents, hasLength(4));
    });

    test('una incidencia que deja de estar pendiente desaparece', () async {
      repository.controller.add(items);
      await pumpEventQueue();
      repository.controller.add(items.sublist(1));
      await pumpEventQueue();
      expect(viewModel.all.map((p) => p.incident.folio), [2, 3, 4]);
    });

    test('muestra el error del repositorio', () async {
      repository.controller.addError(IncidentFailure.offline);
      await pumpEventQueue();
      expect(viewModel.errorMessage, IncidentFailure.offline.message);
    });

    test('rechazar exige comentario', () async {
      final ok = await viewModel.reject(items.first, comment: '   ');
      expect(ok, isFalse);
      expect(viewModel.errorMessage, 'Escribe el motivo del rechazo');
      expect(repository.rejected, isEmpty);
    });

    test('rechazar con comentario llama al repositorio', () async {
      final ok = await viewModel.reject(items.first, comment: 'No procede');
      expect(ok, isTrue);
      expect(repository.rejected, {'inc-1': 'No procede'});
    });

    test('asignar exige técnico y hora futura', () async {
      expect(
        PendingIncidentsViewModel.validateAssignment(
          estimatedTime: DateTime(2030),
        ),
        'Selecciona un técnico',
      );
      expect(
        PendingIncidentsViewModel.validateAssignment(technicianId: 't1'),
        'Selecciona la hora estimada de llegada',
      );
      expect(
        PendingIncidentsViewModel.validateAssignment(
          technicianId: 't1',
          estimatedTime: DateTime(2026, 1, 1),
          now: DateTime(2026, 6, 1),
        ),
        'La hora estimada no puede ser en el pasado',
      );
    });

    test('asignar muestra el error si ya no está pendiente', () async {
      repository.actionError = IncidentFailure.notPending;
      final ok = await viewModel.assign(
        items.first,
        technicianId: 't1',
        estimatedTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(ok, isFalse);
      expect(viewModel.errorMessage, IncidentFailure.notPending.message);
    });
  });
}
