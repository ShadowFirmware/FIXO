import 'dart:async';

import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/data/datasources/assigned_incident_remote_data_source.dart';
import 'package:fixo/features/technician/domain/entities/assigned_incident.dart';
import 'package:fixo/features/technician/domain/repositories/assigned_incident_repository.dart';

/// UID del técnico de `TestUsers.technician`.
const technicianId = 'uid-tecnico';

/// Incidencia de prueba con el folio [folio], asignada por defecto al
/// técnico de prueba.
IncidentModel assignedIncident(
  int folio, {
  IncidentStatus status = IncidentStatus.assigned,
  String? technician = technicianId,
  IncidentType type = IncidentType.water,
  DateTime? estimatedTime,
  String housingId = 'viv-4b',
  String createdBy = 'res-ana',
}) => IncidentModel(
  id: 'inc-$folio',
  folio: folio,
  title: 'Fuga $folio',
  type: type,
  description: 'Gotea la tubería del baño.',
  housingId: housingId,
  createdBy: createdBy,
  status: status,
  technicianId: technician,
  estimatedTime: estimatedTime,
  createdAt: DateTime(2026, 11, folio),
);

AssignedIncident assignedItem(
  Incident incident, {
  String housingLabel = 'Torre A – 4B',
  String residentName = 'Ana López',
  String? residentPhone = '7771112233',
  String? residentEmail = 'ana@correo.com',
  Housing? housing = towerA4B,
}) => AssignedIncident(
  incident: incident,
  housingLabel: housingLabel,
  residentName: residentName,
  residentPhone: residentPhone,
  residentEmail: residentEmail,
  housing: housing,
);

/// Departamento 4B de la Torre A.
const towerA4B = Housing(
  id: 'viv-4b',
  type: HousingType.apartment,
  number: '4B',
  building: 'Torre A',
);

/// Simula el repositorio: las pruebas emiten las incidencias a mano.
class FakeAssignedIncidentRepository implements AssignedIncidentRepository {
  final listController = StreamController<List<AssignedIncident>>.broadcast();
  final detailController = StreamController<AssignedIncident?>.broadcast();

  /// Técnicos e incidencias que se consultaron.
  final requestedTechnicians = <String>[];
  final requestedIds = <String>[];

  @override
  Stream<List<AssignedIncident>> watchByTechnician(String technicianId) {
    requestedTechnicians.add(technicianId);
    return listController.stream;
  }

  @override
  Stream<AssignedIncident?> watchById(String id) {
    requestedIds.add(id);
    return detailController.stream;
  }

  /// Error que lanza [startAttention], por ejemplo sin conexión.
  Object? startError;

  /// Si no es `null`, [startAttention] espera a que se complete.
  Completer<void>? startGate;

  /// Incidencias cuya atención se comenzó, con el técnico.
  final started = <({String incidentId, String technicianId})>[];

  @override
  Future<void> startAttention({
    required String incidentId,
    required String technicianId,
  }) async {
    await startGate?.future;
    if (startError != null) throw startError!;
    started.add((incidentId: incidentId, technicianId: technicianId));
  }
}

/// Simula Firestore para probar el repositorio real.
class FakeAssignedIncidentRemoteDataSource
    implements AssignedIncidentRemoteDataSource {
  final listController = StreamController<List<IncidentModel>>.broadcast();
  final detailController = StreamController<IncidentModel?>.broadcast();

  Map<String, Housing> housings = {};
  Map<String, ({String? name, String? phone, String? email})> contacts = {};

  /// Cuántas veces se consultó cada vivienda y cada usuario.
  final lookups = <String, int>{};

  @override
  Stream<List<IncidentModel>> watchByTechnician(String technicianId) =>
      listController.stream;

  @override
  Stream<IncidentModel?> watchById(String id) => detailController.stream;

  @override
  Future<Housing?> housing(String id) async {
    lookups.update(id, (n) => n + 1, ifAbsent: () => 1);
    return housings[id];
  }

  @override
  Future<({String? name, String? phone, String? email})?> contact(
    String uid,
  ) async {
    lookups.update(uid, (n) => n + 1, ifAbsent: () => 1);
    return contacts[uid];
  }

  /// Error que lanza [startAttention], por ejemplo una excepción de
  /// [StartAttentionPlan] o de Firestore.
  Object? startError;

  final started = <({String incidentId, String technicianId})>[];

  @override
  Future<void> startAttention({
    required String incidentId,
    required String technicianId,
  }) async {
    if (startError != null) throw startError!;
    started.add((incidentId: incidentId, technicianId: technicianId));
  }
}
