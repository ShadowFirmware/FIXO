import 'package:firebase_core/firebase_core.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/admin/data/datasources/history_pdf_exporter.dart';
import 'package:fixo/features/admin/data/models/history_report.dart';
import 'package:fixo/features/admin/data/repositories/incident_admin_repository_impl.dart';
import 'package:fixo/features/admin/domain/entities/admin_history_filter.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_history_fakes.dart';
import 'pending_incidents_fakes.dart';

/// HU-4.11 Consultar historial de incidencias: datos, filtros y reporte.
void main() {
  group('repositorio', () {
    late FakeIncidentAdminRemoteDataSource remote;
    late IncidentAdminRepositoryImpl repository;

    setUp(() {
      remote = FakeIncidentAdminRemoteDataSource()
        ..userNames = {'res-ana': 'Ana López', 'tec-1': 'José Pérez'}
        ..housingLabels = {'viv-4b': 'Torre A – 4B'};
      repository = IncidentAdminRepositoryImpl(remote: remote);
    });

    test('PU-462 obtiene incidencias de todos los estados, de la más '
        'reciente a la más antigua, con los nombres', () async {
      final next = repository.watchHistory().first;
      remote.allController.add([
        historyIncident(1, createdAt: DateTime(2026, 10, 1)),
        historyIncident(
          2,
          status: IncidentStatus.resolved,
          technicianId: 'tec-1',
          createdAt: DateTime(2026, 10, 3),
        ),
        historyIncident(3, status: IncidentStatus.rejected),
        historyIncident(
          4,
          status: IncidentStatus.assigned,
          technicianId: 'tec-borrado',
          createdAt: DateTime(2026, 10, 2),
        ),
        historyIncident(5, status: IncidentStatus.inProgress),
      ]);
      final list = await next;

      // Las recién creadas (sin fecha del servidor) van primero.
      expect(list.map((r) => r.incident.folio), [5, 3, 2, 4, 1]);
      expect(list.map((r) => r.incident.status).toSet(), {
        ...IncidentStatus.values,
      });
      final resolved = list[2];
      expect(resolved.housingLabel, 'Torre A – 4B');
      expect(resolved.reporterName, 'Ana López');
      expect(resolved.technicianName, 'José Pérez');
      expect(list[3].technicianName, 'Sin registrar');
      expect(list[4].technicianName, isNull);
    });

    test('PU-463 los errores de Firestore se traducen', () async {
      for (final (code, failure) in [
        ('permission-denied', IncidentFailure.adminHistoryAccessDenied),
        ('unavailable', IncidentFailure.offline),
        ('internal', IncidentFailure.historyLoadFailed),
      ]) {
        final error = repository.watchHistory().first;
        remote.allController.addError(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        await expectLater(error, throwsA(failure));
      }
    });
  });

  group('filtros', () {
    final water = historyRecord(
      historyIncident(
        1,
        status: IncidentStatus.resolved,
        technicianId: 'tec-1',
        createdAt: DateTime(2026, 10, 1, 8),
      ),
    );
    final light = historyRecord(
      historyIncident(
        2,
        type: IncidentType.electricity,
        technicianId: 'tec-2',
        housingId: 'viv-1a',
        createdAt: DateTime(2026, 10, 15, 23, 59),
      ),
    );
    final noDate = historyRecord(historyIncident(3));
    final all = [water, light, noDate];

    List<int> folios(AdminHistoryFilter filter) =>
        filter.apply(all).map((r) => r.incident.folio).toList();

    test('PU-464 filtra por estado, tipo, técnico y departamento, y se '
        'pueden combinar y quitar', () {
      expect(folios(AdminHistoryFilter.none), [1, 2, 3]);
      expect(
        folios(const AdminHistoryFilter(status: IncidentStatus.resolved)),
        [1],
      );
      expect(folios(const AdminHistoryFilter(type: IncidentType.electricity)), [
        2,
      ]);
      expect(folios(const AdminHistoryFilter(technicianId: 'tec-1')), [1]);
      expect(folios(const AdminHistoryFilter(housingId: 'viv-1a')), [2]);

      const combined = AdminHistoryFilter(
        type: IncidentType.water,
        housingId: 'viv-4b',
      );
      expect(folios(combined), [1, 3]);
      expect(combined.activeCount, 2);
      expect(folios(combined.copyWith(status: () => IncidentStatus.pending)), [
        3,
      ]);
      expect(combined.copyWith(type: () => null).type, isNull);
      expect(combined.copyWith(type: () => null).housingId, 'viv-4b');
    });

    test('PU-465 el rango de fechas incluye ambos días completos', () {
      expect(
        folios(
          AdminHistoryFilter(
            from: DateTime(2026, 10, 1),
            to: DateTime(2026, 10, 15),
          ),
        ),
        [1, 2],
      );
      expect(folios(AdminHistoryFilter(from: DateTime(2026, 10, 2))), [2]);
      expect(folios(AdminHistoryFilter(to: DateTime(2026, 10, 14))), [1]);
      // Sin fecha de creación no entra en ningún rango.
      expect(folios(AdminHistoryFilter(from: DateTime(2020))), [1, 2]);
      expect(AdminHistoryFilter(from: DateTime(2026)).activeCount, 1);

      expect(
        AdminHistoryFilter.validateDateRange(
          DateTime(2026, 10, 2),
          DateTime(2026, 10, 1),
        ),
        'La fecha final no puede ser anterior a la inicial',
      );
      expect(
        AdminHistoryFilter.validateDateRange(
          DateTime(2026, 10, 1, 18),
          DateTime(2026, 10, 1),
        ),
        isNull,
      );
    });
  });

  group('reporte PDF', () {
    final resolved = historyRecord(
      historyIncident(
        7,
        status: IncidentStatus.resolved,
        createdAt: DateTime(2026, 10, 1),
        resolvedAt: DateTime(2026, 10, 3),
        before: const ['a.jpg', 'b.jpg'],
        after: const ['c.jpg'],
      ),
      technicianName: 'José Pérez',
    );

    test('PU-466 cada fila tiene todos los datos de la incidencia', () {
      expect(HistoryReport.headers, hasLength(11));
      expect(HistoryReport.row(resolved), [
        'INC-0007',
        'Incidencia 7',
        'Agua',
        'Resuelta',
        'Detalles de la incidencia 7',
        'Antes: 2 · Después: 1',
        'Torre A – 4B',
        'Ana López',
        'José Pérez',
        '1 oct 2026',
        '3 oct 2026',
      ]);

      final pending = HistoryReport.row(
        historyRecord(historyIncident(8, description: 'x' * 300)),
      );
      expect(pending[4], hasLength(HistoryReport.maxDetails));
      expect(pending[4], endsWith('…'));
      expect(pending[8], 'Sin asignar');
      expect(pending[9], '-');
    });

    test('PU-467 el reporte indica los filtros, la fecha y el nombre del '
        'archivo', () {
      expect(HistoryReport.filterLines(AdminHistoryFilter.none), [
        'Filtros: ninguno (todas las incidencias)',
      ]);
      expect(
        HistoryReport.filterLines(
          AdminHistoryFilter(
            status: IncidentStatus.resolved,
            type: IncidentType.water,
            technicianId: 'tec-1',
            housingId: 'viv-4b',
            from: DateTime(2026, 10, 1),
          ),
          technicianName: 'José Pérez',
          housingLabel: 'Torre A – 4B',
        ),
        [
          'Estado: Resuelta',
          'Tipo: Agua',
          'Técnico: José Pérez',
          'Departamento: Torre A – 4B',
          'Fecha de creación: 1 oct 2026 – hoy',
        ],
      );
      expect(
        HistoryReport.generatedLine(DateTime(2026, 11, 2, 16, 5), 1),
        'Generado el 2 de noviembre de 2026, 4:05 p. m. · 1 incidencia',
      );
      expect(
        HistoryReport.fileName(DateTime(2026, 11, 2)),
        'historial-incidencias-2026-11-02.pdf',
      );
    });

    test('PU-468 genera un PDF válido aunque el texto tenga caracteres '
        'especiales', () async {
      expect(
        HistoryReport.pdfSafe('Torre A – 4B “ñ” … 🚿'),
        'Torre A - 4B "ñ" ... ?',
      );

      final bytes = await const HistoryPdfExporter().build(
        records: [resolved],
        filterLines: HistoryReport.filterLines(AdminHistoryFilter.none),
        generatedAt: DateTime(2026, 11, 2),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
