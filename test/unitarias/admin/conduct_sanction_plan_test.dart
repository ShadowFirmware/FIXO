import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/features/admin/data/models/conduct_sanction_plan.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 25, 10);

  group('ConductSanctionPlan', () {
    test('estado de conducta según reportes validados', () {
      expect(ConductSanctionPlan.conductStatusFor(1).value, 'bueno');
      expect(ConductSanctionPlan.conductStatusFor(2).value, 'medio');
      expect(ConductSanctionPlan.conductStatusFor(3).value, 'medio');
      expect(ConductSanctionPlan.conductStatusFor(4).value, 'malo');
      expect(ConductSanctionPlan.conductStatusFor(5).value, 'malo');
    });

    test('días de suspensión progresiva', () {
      expect(ConductSanctionPlan.suspensionDaysFor(1), 0);
      expect(ConductSanctionPlan.suspensionDaysFor(2), 5);
      expect(ConductSanctionPlan.suspensionDaysFor(3), 10);
      expect(ConductSanctionPlan.suspensionDaysFor(4), 20);
      expect(ConductSanctionPlan.suspensionDaysFor(5), 0);
    });

    test('deshabilita a partir del quinto reporte', () {
      expect(ConductSanctionPlan.disablesAccount(4), isFalse);
      expect(ConductSanctionPlan.disablesAccount(5), isTrue);
      expect(ConductSanctionPlan.disablesAccount(6), isTrue);
    });

    test('userUpdate con primer reporte solo advierte', () {
      final update = ConductSanctionPlan.userUpdate(
        user: {'rol': 'residente', 'reportesValidados': 0, 'estadoCuenta': 'activa'},
        decision: ConductReportStatus.validated,
        now: now,
      );
      expect(update['reportesValidados'], 1);
      expect(update['estadoConducta'], 'bueno');
      expect(update.containsKey('estadoCuenta'), isFalse);
    });

    test('userUpdate con segundo reporte suspende 5 días', () {
      final update = ConductSanctionPlan.userUpdate(
        user: {'rol': 'residente', 'reportesValidados': 1, 'estadoCuenta': 'activa'},
        decision: ConductReportStatus.validated,
        now: now,
      );
      expect(update['reportesValidados'], 2);
      expect(update['estadoConducta'], 'medio');
      expect(update['estadoCuenta'], 'suspendida');
      expect(update['suspendidaHasta'], isA<Timestamp>());
    });

    test('userUpdate con quinto reporte deshabilita', () {
      final update = ConductSanctionPlan.userUpdate(
        user: {'rol': 'residente', 'reportesValidados': 4, 'estadoCuenta': 'activa'},
        decision: ConductReportStatus.validated,
        now: now,
      );
      expect(update['reportesValidados'], 5);
      expect(update['estadoConducta'], 'malo');
      expect(update['estadoCuenta'], 'deshabilitada');
    });

    test('técnico con incidencias activas difiere la suspensión', () {
      final update = ConductSanctionPlan.userUpdate(
        user: {'rol': 'tecnico', 'reportesValidados': 1, 'estadoCuenta': 'activa', 'disponible': true},
        decision: ConductReportStatus.validated,
        now: now,
        hasActiveIncidents: true,
      );
      expect(update['estadoCuenta'], 'activa');
      expect(update['disponible'], isFalse);
      expect(update['suspensionPendiente'], isTrue);
      expect(update['diasSuspensionPendiente'], 5);
    });

    test('applyPendingSuspension aplica la suspensión diferida', () {
      final changes = ConductSanctionPlan.applyPendingSuspension(
        {'suspensionPendiente': true, 'diasSuspensionPendiente': 5},
        now: now,
      );
      expect(changes['estadoCuenta'], 'suspendida');
      expect(changes['suspendidaHasta'], isA<Timestamp>());
      expect(changes['suspensionPendiente'], isFalse);
    });

    test('applyPendingSuspension vacío si no hay pendiente', () {
      final changes = ConductSanctionPlan.applyPendingSuspension(
        {'suspensionPendiente': false},
        now: now,
      );
      expect(changes, isEmpty);
    });

    test('rejected no cambia al usuario', () {
      final update = ConductSanctionPlan.userUpdate(
        user: {'rol': 'residente', 'reportesValidados': 1, 'estadoCuenta': 'activa'},
        decision: ConductReportStatus.rejected,
        now: now,
      );
      expect(update, isEmpty);
    });

    test('notices genera advertencia y suspensión', () {
      final until = now.add(const Duration(days: 5));
      final list = ConductSanctionPlan.notices(
        userId: 'u1',
        reportId: 'r1',
        validatedReports: 2,
        reason: 'insultos',
        now: now,
        suspendedUntil: until,
      );
      expect(list, hasLength(2));
      expect(list.first['tipo'], 'advertencia_conducta');
      expect(list.last['tipo'], 'cuenta_suspendida');
    });

    test('notices genera deshabilitación en el quinto', () {
      final list = ConductSanctionPlan.notices(
        userId: 'u1',
        reportId: 'r1',
        validatedReports: 5,
        reason: '',
        now: now,
        suspendedUntil: null,
      );
      expect(list, hasLength(2));
      expect(list.last['tipo'], 'cuenta_deshabilitada');
    });
  });
}