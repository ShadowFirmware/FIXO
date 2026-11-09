import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../housing/data/models/housing_model.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../incidents/data/models/incident_model.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../notifications/data/datasources/notification_remote_data_source.dart';
import '../models/finalize_plan.dart';
import '../models/solution_plan.dart';
import '../models/start_attention_plan.dart';

/// Acceso a Firestore para las incidencias asignadas al técnico (HU-3.3).
class AssignedIncidentRemoteDataSource {
  AssignedIncidentRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestoreCollections.incidents);

  /// Escucha las incidencias asignadas al técnico [technicianId], en
  /// cualquier estado. El estado se filtra en la app para no necesitar un
  /// índice compuesto en Firestore.
  Stream<List<IncidentModel>> watchByTechnician(String technicianId) {
    return _incidents
        .where('tecnicoId', isEqualTo: technicianId)
        .snapshots()
        .map((query) => [for (final doc in query.docs) ?_tryParse(doc)]);
  }

  /// Escucha el documento `incidencias/{id}`: emite cada cambio, o `null`
  /// si no existe.
  Stream<IncidentModel?> watchById(String id) {
    return _incidents
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? IncidentModel.fromFirestore(doc) : null);
  }

  /// Un documento con un tipo o estado que no existe (por ejemplo,
  /// capturado a mano) se omite para no dejar vacía la lista del técnico.
  static IncidentModel? _tryParse(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return IncidentModel.fromFirestore(doc);
    } on FormatException {
      return null;
    }
  }

  /// Vivienda [id], o `null` si no existe.
  Future<Housing?> housing(String id) async {
    final doc = await _firestore
        .collection(FirestoreCollections.housings)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    try {
      return HousingModel.fromFirestore(doc);
    } on FormatException {
      return null;
    }
  }

  /// Nombre, teléfono y correo del usuario [uid], o `null` si no existe.
  Future<({String? name, String? phone, String? email})?> contact(
    String uid,
  ) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null) return null;
    return (
      name: data['nombre'] as String?,
      phone: data['telefono'] as String?,
      email: data['correo'] as String?,
    );
  }

  /// UIDs de los administradores activos, para avisarles (HU-3.5).
  Future<List<String>> activeAdminIds() =>
      NotificationRemoteDataSource(firestore: _firestoreOverride)
          .activeAdminIds();

  /// Pasa la incidencia de Asignada a En proceso y avisa al residente y a
  /// los administradores [adminIds], en una sola transacción. Lanza las
  /// excepciones de [StartAttentionPlan] si la incidencia no se puede
  /// comenzar.
  Future<void> startAttention({
    required String incidentId,
    required String technicianId,
    List<String> adminIds = const [],
  }) {
    return _firestore.runTransaction((transaction) async {
      final incidentRef = _incidents.doc(incidentId);
      final incidentDoc = await transaction.get(incidentRef);
      final technicianDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.users).doc(technicianId),
      );
      final incident = incidentDoc.data();
      StartAttentionPlan.validate(
        incident: incident,
        technician: technicianDoc.data(),
        technicianId: technicianId,
        now: DateTime.now(),
      );

      transaction.update(incidentRef, StartAttentionPlan.incidentUpdate);

      final residentId = incident!['creadaPor'] as String? ?? '';
      final notifications = _firestore.collection(
        FirestoreCollections.notifications,
      );
      for (final userId in {
        if (residentId.isNotEmpty) residentId,
        ...adminIds,
      }) {
        transaction.set(
          notifications.doc(),
          StartAttentionPlan.notice(
            userId: userId,
            incidentId: incidentId,
            reportNumber: Incident.formatReportNumber(
              (incident['folio'] as num?)?.toInt() ?? 0,
            ),
            title: incident['nombre'] as String? ?? '',
            technicianName:
                technicianDoc.data()?['nombre'] as String? ?? 'El técnico',
          ),
        );
      }
    });
  }

  /// Registra la solución (HU-3.6) con las URLs de las evidencias, en una
  /// transacción que antes revisa las reglas de [SolutionPlan]. La
  /// incidencia sigue En proceso hasta que el técnico la finaliza (HU-3.7).
  Future<void> registerSolution({
    required String incidentId,
    required String technicianId,
    required String solution,
    required List<String> evidenceUrls,
  }) {
    return _firestore.runTransaction((transaction) async {
      final incidentRef = _incidents.doc(incidentId);
      final incidentDoc = await transaction.get(incidentRef);
      final technicianDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.users).doc(technicianId),
      );
      SolutionPlan.validate(
        incident: incidentDoc.data(),
        technician: technicianDoc.data(),
        technicianId: technicianId,
        now: DateTime.now(),
      );

      transaction.update(
        incidentRef,
        SolutionPlan.incidentUpdate(
          solution: solution,
          evidenceUrls: evidenceUrls,
        ),
      );
    });
  }

  /// Finaliza la incidencia como resuelta (HU-3.7), en una transacción que
  /// antes revisa las reglas de [FinalizePlan].
  Future<void> finalize({
    required String incidentId,
    required String technicianId,
  }) {
    return _firestore.runTransaction((transaction) async {
      final incidentRef = _incidents.doc(incidentId);
      final incidentDoc = await transaction.get(incidentRef);
      final technicianDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.users).doc(technicianId),
      );
      FinalizePlan.validate(
        incident: incidentDoc.data(),
        technician: technicianDoc.data(),
        technicianId: technicianId,
        now: DateTime.now(),
      );

      transaction.update(incidentRef, FinalizePlan.incidentUpdate);
    });
  }
}
