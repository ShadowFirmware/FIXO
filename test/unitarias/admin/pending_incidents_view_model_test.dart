import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/admin/presentation/providers/pending_incidents_view_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pending_incidents_fakes.dart';

/// HU-4.8 Consultar incidencias pendientes de asignación: ViewModel.
void main() {
  late FakeIncidentAdminRepository repository;
  late PendingIncidentsViewModel viewModel;

  final items = [
    withNames(pendingIncident(1, createdAt: DateTime(2026, 10, 1))),
    withNames(
      pendingIncident(
        2,
        type: IncidentType.electricity,
        createdAt: DateTime(2026, 10, 2),
      ),
    ),
    withNames(pendingIncident(3, createdAt: DateTime(2026, 10, 3))),
    withNames(
      pendingIncident(
        4,
        type: IncidentType.structure,
        createdAt: DateTime(2026, 10, 4),
      ),
    ),
  ];

  setUp(() {
    repository = FakeIncidentAdminRepository();
    viewModel = PendingIncidentsViewModel(repository: repository)..start();
  });

  tearDown(() => viewModel.dispose());

  test('PU-416 inicia cargando y muestra lo que llega de Firestore', () async {
    expect(viewModel.isLoading, isTrue);
    repository.controller.add(items);
    await pumpEventQueue();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.all.map((p) => p.incident.folio), [1, 2, 3, 4]);
  });

  test('PU-417 el inicio muestra solo las 3 más antiguas', () async {
    repository.controller.add(items);
    await pumpEventQueue();
    expect(viewModel.preview.map((p) => p.incident.folio), [1, 2, 3]);
    expect(viewModel.hasMore, isTrue);
  });

  test('PU-418 filtra por tipo y al quitar el filtro vuelven todas', () async {
    repository.controller.add(items);
    await pumpEventQueue();
    viewModel.setTypeFilter(IncidentType.water);
    expect(viewModel.incidents.map((p) => p.incident.folio), [1, 3]);
    viewModel.setTypeFilter(IncidentType.other);
    expect(viewModel.incidents, isEmpty);
    viewModel.setTypeFilter(null);
    expect(viewModel.incidents, hasLength(4));
  });

  test('PU-419 la que deja de estar pendiente desaparece sin recargar',
      () async {
    repository.controller.add(items);
    await pumpEventQueue();
    repository.controller.add(items.sublist(1));
    await pumpEventQueue();
    expect(viewModel.all.map((p) => p.incident.folio), [2, 3, 4]);
  });

  test('PU-420 muestra el mensaje de error del repositorio', () async {
    repository.controller.addError(IncidentFailure.offline);
    await pumpEventQueue();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, IncidentFailure.offline.message);
  });

  test('PU-421 rechazar sin comentario no llama al repositorio', () async {
    final ok = await viewModel.reject(items.first, comment: '   ');
    expect(ok, isFalse);
    expect(viewModel.errorMessage, 'Escribe el motivo del rechazo');
    expect(repository.rejected, isEmpty);
  });

  test('PU-422 rechazar con comentario llama al repositorio', () async {
    final ok = await viewModel.reject(items.first, comment: 'No procede');
    expect(ok, isTrue);
    expect(repository.rejected, {'inc-1': 'No procede'});
    expect(viewModel.successMessage, 'Incidencia INC-0001 rechazada.');
  });

  test('PU-423 asignar exige técnico y hora estimada futura', () {
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

  test('PU-424 asignar con datos válidos llama al repositorio', () async {
    final ok = await viewModel.assign(
      items.first,
      technicianId: 'tec-1',
      estimatedTime: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(ok, isTrue);
    expect(repository.assigned, {'inc-1': 'tec-1'});
    expect(viewModel.successMessage, 'Incidencia INC-0001 asignada.');
  });

  test('PU-425 si ya no está pendiente se muestra el aviso', () async {
    repository.actionError = IncidentFailure.notPending;
    final ok = await viewModel.assign(
      items.first,
      technicianId: 'tec-1',
      estimatedTime: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(ok, isFalse);
    expect(viewModel.errorMessage, IncidentFailure.notPending.message);
  });
}
