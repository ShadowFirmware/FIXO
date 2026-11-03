import 'dart:async';

import 'package:fixo/features/admin/data/datasources/incident_admin_remote_data_source.dart';
import 'package:fixo/features/admin/domain/entities/history_incident.dart';
import 'package:fixo/features/admin/domain/entities/pending_incident.dart';
import 'package:fixo/features/admin/domain/repositories/incident_admin_repository.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';

/// Incidencia pendiente de prueba.
IncidentModel pendingIncident(
  int folio, {
  IncidentType type = IncidentType.water,
  DateTime? createdAt,
  String housingId = 'viv-4b',
  String createdBy = 'res-ana',
  List<String> evidence = const [],
}) => IncidentModel(
  id: 'inc-$folio',
  folio: folio,
  title: 'Incidencia $folio',
  type: type,
  description: 'Detalles de la incidencia $folio',
  housingId: housingId,
  createdBy: createdBy,
  status: IncidentStatus.pending,
  evidenceBefore: evidence,
  createdAt: createdAt,
);

PendingIncident withNames(Incident incident) => PendingIncident(
  incident: incident,
  housingLabel: 'Torre A – 4B',
  reporterName: 'Ana López',
);

/// Simula el repositorio: [controller] hace de Firestore en tiempo real.
class FakeIncidentAdminRepository implements IncidentAdminRepository {
  final controller = StreamController<List<PendingIncident>>.broadcast();
  Object? actionError;
  List<AppUser> technicians = const [];
  final assigned = <String, String>{};
  final rejected = <String, String>{};

  @override
  Stream<List<PendingIncident>> watchPending() => controller.stream;

  /// Hace de Firestore en tiempo real para el historial (HU-4.11).
  final historyController = StreamController<List<HistoryIncident>>.broadcast();

  @override
  Stream<List<HistoryIncident>> watchHistory() => historyController.stream;

  /// Hace de Firestore para las estadísticas (HU-4.12); guarda los
  /// periodos que se pidieron.
  final periodController = StreamController<List<HistoryIncident>>.broadcast();
  final requestedPeriods = <(DateTime, DateTime)>[];

  @override
  Stream<List<HistoryIncident>> watchPeriod(DateTime start, DateTime end) {
    requestedPeriods.add((start, end));
    return periodController.stream;
  }

  /// Si no es `null`, [availableTechnicians] falla con este error una vez.
  Object? techniciansError;
  int technicianLoads = 0;

  @override
  Future<List<AppUser>> availableTechnicians() async {
    technicianLoads++;
    final error = techniciansError;
    techniciansError = null;
    if (error != null) throw error;
    return technicians;
  }

  @override
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  }) async {
    if (actionError != null) throw actionError!;
    assigned[incidentId] = technicianId;
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

/// Simula la fuente de datos de Firestore.
class FakeIncidentAdminRemoteDataSource
    implements IncidentAdminRemoteDataSource {
  final controller = StreamController<List<IncidentModel>>.broadcast();
  Map<String, String> userNames = {};
  Map<String, String> housingLabels = {};
  final userReads = <String>[];
  Object? actionError;
  String? lastComment;

  @override
  Stream<List<IncidentModel>> watchPending() => controller.stream;

  /// Todas las incidencias, para el historial (HU-4.11).
  final allController = StreamController<List<IncidentModel>>.broadcast();

  @override
  Stream<List<IncidentModel>> watchAll() => allController.stream;

  /// Incidencias de un periodo, para las estadísticas (HU-4.12).
  final periodController = StreamController<List<IncidentModel>>.broadcast();

  @override
  Stream<List<IncidentModel>> watchCreatedBetween(
    DateTime start,
    DateTime end,
  ) => periodController.stream;

  @override
  Future<String?> userName(String uid) async {
    userReads.add(uid);
    return userNames[uid];
  }

  @override
  Future<String?> housingLabel(String id) async => housingLabels[id];

  @override
  Future<List<UserModel>> availableTechnicians() async => const [];

  @override
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  }) async {
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> reject({
    required String incidentId,
    required String comment,
  }) async {
    if (actionError != null) throw actionError!;
    lastComment = comment;
  }
}
