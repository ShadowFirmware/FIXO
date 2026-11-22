import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../notifications/data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/conduct_report.dart';
import '../models/conduct_report_model.dart';
import '../models/conduct_report_plan.dart';
import '../models/resident_report_plan.dart';

/// Acceso a la colección `reportesConducta` (HU-7.1 y HU-7.2).
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

  // HU-7.2 Reportar la conducta de un residente.

  /// Escucha los reportes que [reporterId] levantó en la incidencia
  /// [incidentId]. Dos filtros de igualdad no necesitan índice compuesto.
  Stream<List<ConductReportModel>> watchByReporter({
    required String incidentId,
    required String reporterId,
  }) => _reports
      .where('incidenciaId', isEqualTo: incidentId)
      .where('reportanteId', isEqualTo: reporterId)
      .snapshots()
      .map(
        (query) => [
          for (final doc in query.docs) ?_tryParse(doc.id, doc.data()),
        ],
      );

  /// Un reporte con datos inválidos no oculta los demás.
  static ConductReportModel? _tryParse(String id, Map<String, dynamic> data) {
    try {
      return ConductReportModel.fromMap(id, data);
    } on FormatException {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> _messages(String incidentId) =>
      _firestore
          .collection(FirestoreCollections.incidents)
          .doc(incidentId)
          .collection(FirestoreCollections.messages);

  /// Residentes que escribieron en el chat de la incidencia (HU-5.1), con el
  /// nombre que tenían en su último mensaje (UID → nombre).
  Future<Map<String, String>> residentChatAuthors(String incidentId) async {
    final messages = await _messages(incidentId)
        .where('autorRol', isEqualTo: UserRole.resident.value)
        .get();
    return {
      for (final doc in messages.docs)
        if ((doc.data()['autorId'] as String?)?.isNotEmpty ?? false)
          doc.data()['autorId'] as String:
              (doc.data()['autorNombre'] as String?) ?? '',
    };
  }

  /// `true` si el residente [residentId] envió mensajes en el chat de la
  /// incidencia. Los mensajes no se editan ni se borran, así que se puede
  /// revisar antes de la transacción.
  Future<bool> wroteInChat({
    required String incidentId,
    required String residentId,
  }) async {
    final messages = await _messages(incidentId)
        .where('autorId', isEqualTo: residentId)
        .limit(1)
        .get();
    return messages.docs.isNotEmpty;
  }

  /// Nombre del usuario [uid], o `null` si no existe.
  Future<String?> userName(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    return doc.data()?['nombre'] as String?;
  }

  /// Registra el reporte del técnico [reporterId] contra el residente
  /// [residentId] en una sola transacción: revisa las reglas de
  /// [ResidentReportPlan], reserva el folio, guarda el reporte Pendiente de
  /// revisión y avisa a los administradores [adminIds].
  ///
  /// No toca el perfil del residente: su estado de conducta y su cuenta
  /// solo cambian cuando el administrador valida el reporte (HU-7.3 y
  /// HU-7.4).
  Future<ConductReportModel> createResidentReport({
    required String incidentId,
    required String reporterId,
    required String residentId,
    required bool wroteInChat,
    required ConductReason reason,
    required String description,
    required List<String> evidence,
    List<String> adminIds = const [],
  }) {
    final id = ConductReport.docIdFor(
      incidentId: incidentId,
      reporterId: reporterId,
      reportedId: residentId,
    );
    final users = _firestore.collection(FirestoreCollections.users);

    return _firestore.runTransaction((transaction) async {
      final reportRef = _reports.doc(id);
      final incidentDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.incidents).doc(incidentId),
      );
      final reporterDoc = await transaction.get(users.doc(reporterId));
      final residentDoc = await transaction.get(users.doc(residentId));
      final existing = await transaction.get(reportRef);
      final counter = await transaction.get(_counter);
      final incident = incidentDoc.data();
      final reporter = reporterDoc.data();
      final resident = residentDoc.data();
      ResidentReportPlan.validate(
        incident: incident,
        reporter: reporter,
        reporterId: reporterId,
        resident: resident,
        residentId: residentId,
        wroteInChat: wroteInChat,
        alreadyReported: existing.exists,
      );

      final folio =
          ((counter.data()?['ultimoFolio'] as num?)?.toInt() ?? 0) + 1;
      final report = ResidentReportPlan.build(
        id: id,
        folio: folio,
        incidentId: incidentId,
        incident: incident!,
        reporterId: reporterId,
        reporter: reporter!,
        residentId: residentId,
        resident: resident!,
        reason: reason,
        description: description,
        evidence: evidence,
      );

      transaction
        ..set(_counter, {'ultimoFolio': folio})
        ..set(reportRef, report.toFirestore());
      _notifications.addNotices(
        transaction,
        ResidentReportPlan.notices(adminIds: adminIds, report: report),
      );
      return report;
    });
  }
}
