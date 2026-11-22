import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../notifications/data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/conduct_report.dart';
import '../models/conduct_report_model.dart';
import '../models/conduct_report_plan.dart';

/// Acceso a la colección `reportesConducta` (HU-7.1).
class ConductReportRemoteDataSource {
  ConductReportRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(FirestoreCollections.conductReports);

  /// Documento `contadores/reportesConducta` con el último folio usado.
  DocumentReference<Map<String, dynamic>> get _counter => _firestore
      .collection(FirestoreCollections.counters)
      .doc(FirestoreCollections.conductReports);

  NotificationRemoteDataSource get _notifications =>
      NotificationRemoteDataSource(firestore: _firestoreOverride);

  /// Escucha el reporte [id]: emite cada cambio, o `null` si no existe.
  Stream<ConductReportModel?> watchById(String id) => _reports
      .doc(id)
      .snapshots()
      .map(
        (doc) =>
            doc.exists ? ConductReportModel.fromMap(doc.id, doc.data()!) : null,
      );

  /// `true` si ya existe el reporte [id]. Se revisa antes de subir las
  /// evidencias para no subirlas en vano; la transacción lo revisa de nuevo.
  Future<bool> exists(String id) async => (await _reports.doc(id).get()).exists;

  /// UIDs de los administradores activos, para avisarles (T 7.1.8).
  Future<List<String>> activeAdminIds() => _notifications.activeAdminIds();

  /// Registra el reporte del residente [reporterId] contra el técnico
  /// [technicianId] en una sola transacción: revisa las reglas de
  /// [ConductReportPlan], reserva el folio, guarda el reporte Pendiente de
  /// revisión y avisa a los administradores [adminIds].
  ///
  /// No toca el perfil del técnico: su estado de conducta y de cuenta solo
  /// cambian cuando el administrador valida el reporte (HU-7.3 y HU-7.4).
  Future<ConductReportModel> createTechnicianReport({
    required String incidentId,
    required String reporterId,
    required String technicianId,
    required ConductReason reason,
    required String description,
    required List<String> evidence,
    List<String> adminIds = const [],
  }) {
    final id = ConductReport.docIdFor(
      incidentId: incidentId,
      reporterId: reporterId,
    );
    final users = _firestore.collection(FirestoreCollections.users);

    return _firestore.runTransaction((transaction) async {
      final reportRef = _reports.doc(id);
      final incidentDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.incidents).doc(incidentId),
      );
      final reporterDoc = await transaction.get(users.doc(reporterId));
      final existing = await transaction.get(reportRef);
      final incident = incidentDoc.data();
      final reporter = reporterDoc.data();
      ConductReportPlan.validate(
        incident: incident,
        reporter: reporter,
        technicianId: technicianId,
        alreadyReported: existing.exists,
      );

      // Las lecturas van antes de cualquier escritura de la transacción.
      final technicianDoc = await transaction.get(users.doc(technicianId));
      final counter = await transaction.get(_counter);
      final folio =
          ((counter.data()?['ultimoFolio'] as num?)?.toInt() ?? 0) + 1;

      final report = ConductReportPlan.build(
        id: id,
        folio: folio,
        incidentId: incidentId,
        incident: incident!,
        reporterId: reporterId,
        reporter: reporter!,
        technicianId: technicianId,
        technician: technicianDoc.data(),
        reason: reason,
        description: description,
        evidence: evidence,
      );

      transaction
        ..set(_counter, {'ultimoFolio': folio})
        ..set(reportRef, report.toFirestore());
      _notifications.addNotices(
        transaction,
        ConductReportPlan.notices(adminIds: adminIds, report: report),
      );
      return report;
    });
  }
}
