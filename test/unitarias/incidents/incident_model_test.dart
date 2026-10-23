import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-2.3.2 Estructura de datos de una incidencia.
void main() {
  test('PU-61 lee una incidencia de la colección incidencias', () {
    final incident = IncidentModel.fromMap('inc-1', {
      'folio': 7,
      'nombre': 'Fuga en baño',
      'tipo': 'agua',
      'detalles': 'Gotea la llave del lavabo',
      'viviendaId': 'vivienda-4b',
      'creadaPor': 'uid-residente',
      'estado': 'pendiente',
      'tecnicoId': null,
      'evidenciasAntes': ['https://foto.jpg'],
      'fechaCreacion': Timestamp.fromDate(DateTime(2026, 10, 20)),
    });

    expect(incident.folio, 7);
    expect(incident.reportNumber, 'INC-0007');
    expect(incident.type, IncidentType.water);
    expect(incident.status, IncidentStatus.pending);
    expect(incident.housingId, 'vivienda-4b');
    expect(incident.evidenceBefore, ['https://foto.jpg']);
    expect(incident.createdAt, DateTime(2026, 10, 20));
  });

  test('PU-62 una incidencia nueva se guarda pendiente y sin técnico', () {
    const incident = IncidentModel(
      id: 'inc-1',
      folio: 1,
      title: 'Sin luz',
      type: IncidentType.electricity,
      description: 'No hay luz en la cocina',
      housingId: 'vivienda-4b',
      createdBy: 'uid-residente',
      status: IncidentStatus.pending,
    );

    final data = incident.toFirestore();

    expect(data['estado'], 'pendiente');
    expect(data['tipo'], 'luz');
    expect(data['tecnicoId'], isNull);
    expect(data['horaEstimada'], isNull);
    // La fecha la pone el servidor, no el reloj del teléfono.
    expect(data['fechaCreacion'], isA<FieldValue>());
  });

  test('PU-63 rechaza tipos o estados que no existen', () {
    final base = {'tipo': 'agua', 'estado': 'pendiente'};

    expect(
      () => IncidentModel.fromMap('x', {...base, 'tipo': 'gas'}),
      throwsFormatException,
    );
    expect(
      () => IncidentModel.fromMap('x', {...base, 'estado': 'abierta'}),
      throwsFormatException,
    );
  });
}
