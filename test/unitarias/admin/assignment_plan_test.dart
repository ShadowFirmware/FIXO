import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/features/admin/data/datasources/incident_admin_remote_data_source.dart';
import 'package:fixo/features/admin/data/models/assignment_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-4.9 Asignar un técnico y establecer hora estimada: reglas y datos que
/// se guardan en Firestore.
void main() {
  final now = DateTime(2026, 11, 2, 10);
  final arrival = DateTime(2026, 11, 2, 16, 30);

  const pending = {'estado': 'pendiente', 'folio': 7, 'nombre': 'Fuga'};

  Map<String, dynamic> technician({
    String role = 'tecnico',
    String account = 'activa',
    Object? available = true,
    DateTime? suspendedUntil,
  }) => {
    'rol': role,
    'estadoCuenta': account,
    'disponible': ?available,
    if (suspendedUntil != null)
      'suspendidaHasta': Timestamp.fromDate(suspendedUntil),
  };

  test('PU-439 solo se asigna una incidencia que sigue pendiente', () {
    for (final incident in [
      null,
      {'estado': 'asignada'},
    ]) {
      expect(
        () => AssignmentPlan.validate(
          incident: incident,
          technician: technician(),
          now: now,
        ),
        throwsA(isA<IncidentNotPendingException>()),
      );
    }
    AssignmentPlan.validate(
      incident: pending,
      technician: technician(),
      now: now,
    );
  });

  test('PU-440 no se asignan técnicos suspendidos, deshabilitados, dados de '
      'baja, no disponibles o con otro rol', () {
    final invalid = {
      'no existe': null,
      'suspendido': technician(account: 'suspendida'),
      'deshabilitado': technician(account: 'deshabilitada'),
      'dado de baja': technician(account: 'baja'),
      'no disponible': technician(available: false),
      'sin estado de disponibilidad': technician(available: null),
      'residente': technician(role: 'residente'),
      'suspensión vigente': technician(
        suspendedUntil: now.add(const Duration(days: 3)),
      ),
    };

    for (final MapEntry(:key, :value) in invalid.entries) {
      expect(
        AssignmentPlan.canReceiveAssignment(value, now: now),
        isFalse,
        reason: key,
      );
      expect(
        () => AssignmentPlan.validate(
          incident: pending,
          technician: value,
          now: now,
        ),
        throwsA(isA<TechnicianUnavailableException>()),
        reason: key,
      );
    }

    expect(
      AssignmentPlan.canReceiveAssignment(
        technician(suspendedUntil: now.subtract(const Duration(days: 1))),
        now: now,
      ),
      isTrue,
    );
  });

  test('PU-441 la incidencia pasa de Pendiente a Asignada con el técnico y '
      'la hora estimada', () {
    final update = AssignmentPlan.incidentUpdate(
      technicianId: 'tec-1',
      estimatedTime: arrival,
    );

    expect(update['estado'], 'asignada');
    expect(update['tecnicoId'], 'tec-1');
    expect(update['horaEstimada'], Timestamp.fromDate(arrival));
    expect(update['fechaAsignacion'], isA<FieldValue>());
  });

  test('PU-442 el técnico queda No disponible', () {
    expect(AssignmentPlan.technicianUpdate, {'disponible': false});
  });

  test('PU-443 el residente recibe el nombre del técnico y la hora '
      'estimada', () {
    final notice = AssignmentPlan.residentNotice(
      residentId: 'res-ana',
      incidentId: 'inc-7',
      reportNumber: 'INC-0007',
      title: 'Fuga en baño',
      technicianName: 'Juan Pérez',
      estimatedTime: arrival,
    );

    expect(notice['usuarioId'], 'res-ana');
    expect(notice['tipo'], IncidentAdminRemoteDataSource.assignedType);
    expect(notice['refId'], 'inc-7');
    expect(notice['leida'], isFalse);
    expect(notice['titulo'], 'Incidencia INC-0007 asignada');
    expect(
      notice['mensaje'],
      'Juan Pérez atenderá "Fuga en baño". Hora estimada de llegada: '
      '2 de noviembre de 2026, 4:30 p. m.',
    );
  });

  test('PU-444 el técnico recibe los detalles de la incidencia', () {
    final notice = AssignmentPlan.technicianNotice(
      technicianId: 'tec-1',
      incidentId: 'inc-7',
      reportNumber: 'INC-0007',
      title: 'Fuga en baño',
      typeLabel: 'Agua',
      housingLabel: 'Torre A – 4B',
      description: 'Gotea la llave ${'muy ' * 60}seguido',
      estimatedTime: arrival,
    );
    final message = notice['mensaje'] as String;

    expect(notice['usuarioId'], 'tec-1');
    expect(notice['titulo'], 'Nueva asignación INC-0007');
    expect(
      message,
      startsWith(
        'Se te asignó "Fuga en baño" (Agua) en '
        'Torre A – 4B. Detalles: Gotea la llave muy',
      ),
    );
    // La descripción larga se recorta.
    expect(message, contains('…'));
    expect(message, isNot(contains('seguido')));
    expect(
      message,
      endsWith('Hora estimada de llegada: 2 de noviembre de 2026, 4:30 p. m.'),
    );
  });
}
