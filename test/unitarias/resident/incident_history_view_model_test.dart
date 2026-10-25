import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/providers/incident_history_view_model.dart';
import 'package:fixo/features/resident/presentation/widgets/incident_history_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';

/// HU-2.5 Consultar historial de incidencias.
void main() {
  Incident incident(
    int folio, {
    String title = 'Fuga en baño',
    IncidentType type = IncidentType.water,
    IncidentStatus status = IncidentStatus.pending,
    String housingId = 'vivienda-4b',
    String createdBy = 'uid-residente',
    DateTime? createdAt,
    DateTime? estimatedTime,
    String? solution,
    DateTime? resolvedAt,
    String? rejectionComment,
    DateTime? rejectedAt,
  }) => Incident(
    id: 'inc-$folio',
    folio: folio,
    title: title,
    type: type,
    description: 'Descripción',
    housingId: housingId,
    createdBy: createdBy,
    status: status,
    estimatedTime: estimatedTime,
    solution: solution,
    resolvedAt: resolvedAt,
    rejectionComment: rejectionComment,
    rejectedAt: rejectedAt,
    createdAt: createdAt ?? DateTime(2026, 10, folio),
  );

  /// Una incidencia por estado, del 1 al 5 de octubre. La primera la
  /// reportó un residente anterior del mismo departamento.
  final history = [
    incident(
      1,
      title: 'Sin luz en la cocina',
      type: IncidentType.electricity,
      createdBy: 'uid-residente-anterior',
      status: IncidentStatus.resolved,
    ),
    incident(2, title: 'Grieta en la pared', type: IncidentType.structure),
    incident(3, status: IncidentStatus.assigned),
    incident(
      4,
      title: 'Apagador eléctrico dañado',
      type: IncidentType.electricity,
      status: IncidentStatus.inProgress,
    ),
    incident(
      5,
      title: 'Puerta del elevador',
      type: IncidentType.other,
      status: IncidentStatus.rejected,
    ),
  ];

  late AuthSession session;
  late FakeIncidentRepository incidents;

  IncidentHistoryViewModel createViewModel() {
    final vm = IncidentHistoryViewModel(
      session: session,
      incidents: incidents,
      housings: FakeHousingRepository(),
    );
    addTearDown(vm.dispose);
    return vm;
  }

  /// Simula que Firestore emite las incidencias del departamento.
  Future<void> emit(List<Incident> value) async {
    incidents.housingChanges.add(value);
    await pumpEventQueue();
  }

  List<int> folios(IncidentHistoryViewModel vm) => [
    for (final incident in vm.results) incident.folio,
  ];

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.resident());
    incidents = FakeIncidentRepository();
  });

  test('PU-90 solo muestra las incidencias del departamento, también las de '
      'residentes anteriores, de la más reciente a la más antigua', () async {
    final vm = createViewModel();
    expect(vm.state, IncidentHistoryState.loading);

    await emit([
      ...history,
      incident(9, housingId: 'vivienda-7c', title: 'De otro departamento'),
    ]);

    expect(incidents.watchedHousingIds, ['vivienda-4b']);
    expect(vm.state, IncidentHistoryState.loaded);
    expect(folios(vm), [5, 4, 3, 2, 1]);
    expect(vm.results.last.createdBy, 'uid-residente-anterior');
    expect(vm.housing, 'Torre A – 4B');
  });

  test('PU-91 incluye incidencias en todos los estados', () async {
    final vm = createViewModel();
    await emit(history);

    expect({
      for (final incident in vm.results) incident.status,
    }, IncidentStatus.values.toSet());
  });

  test('PU-92 filtra por estado', () async {
    final vm = createViewModel();
    await emit(history);

    vm.setStatus(IncidentStatus.rejected);
    expect(folios(vm), [5]);

    vm.setStatus(null);
    expect(folios(vm), hasLength(5));
  });

  test('PU-93 filtra por tipo y por rango de fechas, incluyendo ambos '
      'días completos', () async {
    final vm = createViewModel();
    await emit([
      ...history,
      incident(6, createdAt: DateTime(2026, 10, 4, 23, 59)),
    ]);

    vm.setType(IncidentType.electricity);
    expect(folios(vm), [4, 1]);

    vm
      ..setType(null)
      ..setDateRange(from: DateTime(2026, 10, 2), to: DateTime(2026, 10, 4));
    expect(folios(vm), [6, 4, 3, 2]);
    expect(vm.filter.panelCount, 1);
  });

  test('PU-94 busca por nombre sin importar mayúsculas ni acentos, y por '
      'número de reporte', () async {
    final vm = createViewModel();
    await emit(history);

    vm.setQuery('ELECTRICO');
    expect(folios(vm), [4]);

    vm.setQuery('INC-0002');
    expect(folios(vm), [2]);

    vm.setQuery('3');
    expect(folios(vm), [3]);
  });

  test('PU-95 combina filtros y los limpia', () async {
    final vm = createViewModel();
    await emit(history);

    vm
      ..setType(IncidentType.electricity)
      ..setStatus(IncidentStatus.resolved);
    expect(folios(vm), [1]);

    vm.clearFilters();
    expect(vm.filter.isEmpty, isTrue);
    expect(folios(vm), hasLength(5));
  });

  test('PU-96 avisa cuando no hay incidencias o ningún resultado coincide '
      'con los filtros', () async {
    final vm = createViewModel();

    await emit(const []);
    expect(vm.emptyMessage, IncidentHistoryViewModel.noIncidentsMessage);

    await emit(history);
    expect(vm.emptyMessage, isNull);

    vm
      ..setType(IncidentType.water)
      ..setStatus(IncidentStatus.rejected);
    expect(vm.results, isEmpty);
    expect(vm.emptyMessage, IncidentHistoryViewModel.noResultsMessage);
  });

  test('PU-97 solo un residente con vivienda puede consultar el '
      'historial', () async {
    session.start(TestUsers.technician);
    final technicianVm = createViewModel();

    session.start(
      UserModel.fromMap('uid-sin-vivienda', {
        'nombre': 'Sin Vivienda',
        'correo': 'sin@correo.com',
        'rol': 'residente',
        'estadoCuenta': 'activa',
      }),
    );
    final noHousingVm = createViewModel();
    await pumpEventQueue();

    expect(technicianVm.state, IncidentHistoryState.error);
    expect(
      technicianVm.errorMessage,
      IncidentFailure.historyAccessDenied.message,
    );
    expect(noHousingVm.errorMessage, IncidentFailure.historyNoHousing.message);
    expect(incidents.watchedHousingIds, isEmpty);
  });

  test('PU-98 se actualiza cuando se registra o cambia una incidencia, y '
      'avisa si falla la carga', () async {
    final vm = createViewModel();
    await emit([history[1]]);
    expect(folios(vm), [2]);

    await emit([
      history[1],
      incident(7, title: 'Nueva fuga', createdAt: DateTime(2026, 10, 20)),
    ]);
    expect(folios(vm), [7, 2]);

    incidents.housingChanges.addError(IncidentFailure.offline);
    await pumpEventQueue();
    expect(vm.state, IncidentHistoryState.error);
    expect(vm.errorMessage, IncidentFailure.offline.message);
  });

  test('PU-99 muestra la información adicional de cada estado', () {
    expect(IncidentHistoryCard.noteFor(incident(1)), isNull);
    expect(
      IncidentHistoryCard.noteFor(
        incident(
          2,
          status: IncidentStatus.assigned,
          estimatedTime: DateTime(2026, 10, 21, 16),
        ),
      ),
      'Llegada estimada: 21 de octubre de 2026, 4:00 p. m.',
    );
    expect(
      IncidentHistoryCard.noteFor(
        incident(
          3,
          status: IncidentStatus.resolved,
          solution: 'Se cambió el empaque',
        ),
      ),
      'Solución: Se cambió el empaque',
    );
    expect(
      IncidentHistoryCard.noteFor(
        incident(
          4,
          status: IncidentStatus.resolved,
          resolvedAt: DateTime(2026, 10, 22),
        ),
      ),
      'Resuelta el 22 de octubre de 2026',
    );
    expect(
      IncidentHistoryCard.noteFor(
        incident(
          5,
          status: IncidentStatus.rejected,
          rejectionComment: 'Es del área común',
        ),
      ),
      'Motivo del rechazo: Es del área común',
    );
  });
}
