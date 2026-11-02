import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/features/admin/data/datasources/incident_admin_remote_data_source.dart';
import 'package:fixo/features/admin/data/models/rejection_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-4.10 Rechazar reporte: reglas y datos que se guardan en Firestore.
void main() {
  test('PU-451 solo se rechaza una incidencia que sigue pendiente', () {
    for (final incident in [
      null,
      {'estado': 'asignada'},
      {'estado': 'rechazada'},
    ]) {
      expect(
        () => RejectionPlan.validate(incident),
        throwsA(isA<IncidentNotPendingException>()),
      );
    }
    RejectionPlan.validate({'estado': 'pendiente'});
  });

  test('PU-452 pasa a Rechazada con el motivo y la fecha, sin técnico ni '
      'hora estimada', () {
    final update = RejectionPlan.incidentUpdate(comment: 'Es del área común');

    expect(update['estado'], 'rechazada');
    expect(update['comentarioRechazo'], 'Es del área común');
    expect(update['fechaRechazo'], isA<FieldValue>());
    expect(update.containsKey('tecnicoId'), isTrue);
    expect(update['tecnicoId'], isNull);
    expect(update['horaEstimada'], isNull);
    // Rechazar no crea ningún chat de atención.
    expect(update.keys.where((key) => key.contains('chat')), isEmpty);
  });

  test('PU-453 el residente recibe el motivo del rechazo', () {
    final notice = RejectionPlan.residentNotice(
      residentId: 'res-ana',
      incidentId: 'inc-7',
      reportNumber: 'INC-0007',
      title: 'Puerta del elevador',
      comment: 'Es del área común',
    );

    expect(notice['usuarioId'], 'res-ana');
    expect(notice['tipo'], IncidentAdminRemoteDataSource.rejectedType);
    expect(notice['refId'], 'inc-7');
    expect(notice['leida'], isFalse);
    expect(notice['titulo'], 'Incidencia INC-0007 rechazada');
    expect(
      notice['mensaje'],
      'Tu reporte "Puerta del elevador" fue rechazado. '
      'Motivo: Es del área común',
    );
  });
}
