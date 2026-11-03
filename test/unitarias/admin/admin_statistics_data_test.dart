import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/admin/data/repositories/incident_admin_repository_impl.dart';
import 'package:fixo/features/admin/domain/entities/incident_stats.dart';
import 'package:fixo/features/admin/domain/entities/stats_period.dart';
import 'package:fixo/features/admin/presentation/widgets/stats_charts.dart';
import 'package:fixo/features/admin/presentation/widgets/stats_widgets.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_history_fakes.dart';
import 'pending_incidents_fakes.dart';

/// HU-4.12 Consultar estadísticas de incidencias por periodo: periodos,
/// datos y cálculos.
void main() {
  group('periodos', () {
    test('PU-476 la semana va de lunes a domingo', () {
      // Miércoles 4 de noviembre de 2026.
      final week = StatsPeriod.week(DateTime(2026, 11, 4, 10));
      expect(week.kind, StatsPeriodKind.week);
      expect(week.start, DateTime(2026, 11, 2));
      expect(week.end, DateTime(2026, 11, 9));
      expect(week.label, '2 nov 2026 – 8 nov 2026');

      // Un domingo pertenece a la semana que empezó el lunes anterior, aunque
      // cruce de mes.
      final sunday = StatsPeriod.week(DateTime(2026, 11, 1, 23, 59));
      expect(sunday.start, DateTime(2026, 10, 26));
      expect(sunday.lastDay, DateTime(2026, 11, 1));
    });

    test('PU-477 el mes va del día 1 al último día', () {
      final month = StatsPeriod.month(DateTime(2026, 11, 4));
      expect(month.start, DateTime(2026, 11));
      expect(month.end, DateTime(2026, 12));
      expect(month.label, 'Noviembre 2026');

      final december = StatsPeriod.month(DateTime(2026, 12, 31));
      expect(december.end, DateTime(2027));
      expect(december.lastDay, DateTime(2026, 12, 31));
    });

    test('PU-478 el rango personalizado incluye ambos días y se valida', () {
      final custom = StatsPeriod.custom(
        DateTime(2026, 10, 5, 18),
        DateTime(2026, 10, 20, 8),
      );
      expect(custom.start, DateTime(2026, 10, 5));
      expect(custom.end, DateTime(2026, 10, 21));
      expect(custom.contains(DateTime(2026, 10, 5)), isTrue);
      expect(custom.contains(DateTime(2026, 10, 20, 23, 59)), isTrue);
      expect(custom.contains(DateTime(2026, 10, 21)), isFalse);
      expect(custom.contains(DateTime(2026, 10, 4, 23, 59)), isFalse);
      expect(custom.label, '5 oct 2026 – 20 oct 2026');

      expect(
        StatsPeriod.validateCustom(
          DateTime(2026, 10, 2),
          DateTime(2026, 10, 1),
        ),
        'La fecha final no puede ser anterior a la inicial',
      );
      expect(
        StatsPeriod.validateCustom(DateTime(2025, 1, 1), DateTime(2026, 1, 2)),
        'El rango no puede ser mayor a 366 días',
      );
      expect(
        StatsPeriod.validateCustom(DateTime(2026, 1, 1), DateTime(2026, 1, 1)),
        isNull,
      );
      expect(
        () => StatsPeriod.custom(DateTime(2026, 2), DateTime(2026, 1)),
        throwsArgumentError,
      );
    });

    test('PU-479 se recorre al periodo anterior o siguiente', () {
      final week = StatsPeriod.week(DateTime(2026, 11, 4));
      expect(week.shift(-1).start, DateTime(2026, 10, 26));
      expect(week.shift(1).start, DateTime(2026, 11, 9));

      final month = StatsPeriod.month(DateTime(2026, 1, 15));
      expect(month.shift(-1).label, 'Diciembre 2025');
      expect(month.shift(1).label, 'Febrero 2026');

      // Un rango de 3 días se recorre 3 días.
      final custom = StatsPeriod.custom(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 3),
      );
      expect(custom.shift(1).start, DateTime(2026, 10, 4));
      expect(custom.shift(1).lastDay, DateTime(2026, 10, 6));

      expect(week.reaches(DateTime(2026, 11, 4)), isTrue);
      expect(week.shift(-1).reaches(DateTime(2026, 11, 4)), isFalse);
    });
  });

  group('repositorio', () {
    late FakeIncidentAdminRemoteDataSource remote;
    late IncidentAdminRepositoryImpl repository;

    setUp(() {
      remote = FakeIncidentAdminRemoteDataSource()
        ..userNames = {'res-ana': 'Ana López', 'tec-1': 'José Pérez'}
        ..housingLabels = {'viv-4b': 'Torre A – 4B'};
      repository = IncidentAdminRepositoryImpl(remote: remote);
    });

    test('PU-480 obtiene las incidencias del periodo con los nombres y '
        'traduce los errores', () async {
      final next = repository
          .watchPeriod(DateTime(2026, 11, 2), DateTime(2026, 11, 9))
          .first;
      remote.periodController.add([
        historyIncident(1, technicianId: 'tec-1'),
        historyIncident(2),
      ]);
      final list = await next;
      expect(list.map((r) => r.technicianName), ['José Pérez', null]);
      expect(list.first.reporterName, 'Ana López');

      for (final (code, failure) in [
        ('permission-denied', IncidentFailure.statsAccessDenied),
        ('unavailable', IncidentFailure.offline),
        ('internal', IncidentFailure.statsLoadFailed),
      ]) {
        final error = repository
            .watchPeriod(DateTime(2026), DateTime(2027))
            .first;
        remote.periodController.addError(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        await expectLater(error, throwsA(failure));
      }
    });
  });

  group('cálculos', () {
    final records = [
      historyRecord(
        historyIncident(
          1,
          status: IncidentStatus.resolved,
          technicianId: 'tec-1',
        ),
        technicianName: 'José Pérez',
      ),
      historyRecord(
        historyIncident(
          2,
          type: IncidentType.electricity,
          status: IncidentStatus.inProgress,
          technicianId: 'tec-1',
        ),
        technicianName: 'José Pérez',
      ),
      historyRecord(
        historyIncident(
          3,
          type: IncidentType.electricity,
          status: IncidentStatus.assigned,
          technicianId: 'tec-2',
        ),
        technicianName: 'Ana Ruiz',
      ),
      historyRecord(historyIncident(4, type: IncidentType.electricity)),
      historyRecord(historyIncident(5, status: IncidentStatus.rejected)),
    ];
    final stats = IncidentStats.from(records);

    test('PU-481 cuenta las incidencias por tipo, incluidos los tipos sin '
        'incidencias', () {
      expect(stats.total, 5);
      expect(stats.byType, {
        IncidentType.electricity: 3,
        IncidentType.water: 2,
        IncidentType.structure: 0,
        IncidentType.other: 0,
      });
      expect(IncidentStats.from(const []).isEmpty, isTrue);
    });

    test('PU-482 cuenta las incidencias por estado', () {
      expect(stats.byStatus, {
        IncidentStatus.pending: 1,
        IncidentStatus.assigned: 1,
        IncidentStatus.inProgress: 1,
        IncidentStatus.resolved: 1,
        IncidentStatus.rejected: 1,
      });
      expect(
        stats.byStatus.values.fold(0, (sum, count) => sum + count),
        stats.total,
      );
    });

    test('PU-483 cuenta las asignadas por técnico, de más a menos, con las '
        'resueltas', () {
      expect(stats.byTechnician.map((l) => (l.name, l.assigned, l.resolved)), [
        ('José Pérez', 2, 1),
        ('Ana Ruiz', 1, 0),
      ]);
      // Las pendientes y rechazadas no tienen técnico.
      expect(stats.assignedCount, 3);

      final tie = IncidentStats.from([
        historyRecord(
          historyIncident(1, technicianId: 'b'),
          technicianName: 'Zoe',
        ),
        historyRecord(historyIncident(2, technicianId: 'a')),
      ]);
      expect(tie.byTechnician.map((l) => l.name), ['Sin registrar', 'Zoe']);
    });

    test('PU-484 porcentajes y medidas de las gráficas', () {
      expect(formatPercent(1, 4), '25 %');
      expect(formatPercent(1, 3), '33.3 %');
      expect(formatPercent(0, 0), '0 %');

      expect(StatsBarChart.barFactor(3, 3), 1);
      expect(StatsBarChart.barFactor(1, 4), 0.25);
      expect(StatsBarChart.barFactor(0, 0), 0);

      final sweeps = StatsDonutPainter.sweeps([1, 1, 2, 0]);
      expect(sweeps[2], closeTo(math.pi, 1e-9));
      expect(sweeps.fold(0.0, (a, b) => a + b), closeTo(2 * math.pi, 1e-9));
      expect(StatsDonutPainter.sweeps([0, 0]), [0, 0]);
    });
  });
}
