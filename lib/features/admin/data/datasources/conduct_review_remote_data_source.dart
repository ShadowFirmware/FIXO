import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../conduct_reports/data/models/conduct_report_model.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../notifications/data/models/notification_model.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../models/conduct_review_plan.dart';
import '../models/conduct_sanction_plan.dart';

/// Acceso a la colección `reportesConducta` para que el administrador
/// consulte y revise los reportes (HU-7.3).
class ConductReviewRemoteDataSource {
  ConductReviewRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(FirestoreCollections.conductReports);

  /// Escucha todos los reportes registrados, del más reciente al más
  /// antiguo. Un solo `orderBy` no necesita índice compuesto.
  Stream<List<ConductReportModel>> watchAll() => _reports
      .orderBy('fechaCreacion', descending: true)
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

  /// Marca el reporte [reportId] como [decision] en una sola transacción:
  /// revisa las reglas de [ConductReviewPlan] con los datos actuales, guarda
  /// el estado, la fecha y quién lo revisó, y, si se valida, aplica las
  /// sanciones progresivas del usuario reportado (HU-7.4).
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  }) async {
    final reportRef = _reports.doc(reportId);
    final users = _firestore.collection(FirestoreCollections.users);
    final reviewerRef = users.doc(reviewerId);
    final incidents = _firestore.collection(FirestoreCollections.incidents);
    final notifications =
        _firestore.collection(FirestoreCollections.notifications);

    // Lecturas previas fuera de la transacción para poder consultar
    // incidencias activas y administradores.
    final preReport = await reportRef.get();
    final preReportData = preReport.data();
    final reportedId = preReportData?['reportadoId'] as String?;
    final reportedRole = preReportData?['reportadoRol'] as String?;
    final preReportedUser = reportedId == null || reportedId.isEmpty
        ? null
        : (await users.doc(reportedId).get()).data();

    bool hasActiveIncidents = false;
    List<String> adminIds = const [];
    if (decision == ConductReportStatus.validated &&
        reportedRole == UserRole.technician.value &&
        reportedId != null &&
        reportedId.isNotEmpty) {
      final activeQuery = await incidents
          .where('tecnicoId', isEqualTo: reportedId)
          .where(
            'estado',
            whereIn: [
              IncidentStatus.assigned.value,
              IncidentStatus.inProgress.value,
            ],
          )
          .get();
      hasActiveIncidents = activeQuery.docs.isNotEmpty;
      final currentValidated =
          (preReportedUser?['reportesValidados'] as num?)?.toInt() ?? 0;
      final nextValidated = currentValidated + 1;
      if (ConductSanctionPlan.suspendsAccount(nextValidated) &&
          hasActiveIncidents) {
        final admins = await users
            .where('rol', isEqualTo: UserRole.admin.value)
            .get();
        adminIds = admins.docs.map((d) => d.id).toList();
      }
    }

    await _firestore.runTransaction((transaction) async {
      final reportDoc = await transaction.get(reportRef);
      final reviewerDoc = await transaction.get(reviewerRef);
      final reviewer = reviewerDoc.data();
      ConductReviewPlan.validate(
        report: reportDoc.data(),
        reviewer: reviewer,
        decision: decision,
      );
      transaction.update(
        reportRef,
        ConductReviewPlan.reportUpdate(
          decision: decision,
          reviewerId: reviewerId,
          reviewerName: (reviewer!['nombre'] as String?) ?? '',
        ),
      );

      if (decision != ConductReportStatus.validated) return;

      final reportData = reportDoc.data()!;
      final reportedIdTx = reportData['reportadoId'] as String?;
      if (reportedIdTx == null || reportedIdTx.isEmpty) return;

      final reportedRef = users.doc(reportedIdTx);
      final reportedDoc = await transaction.get(reportedRef);
      final reportedUser = reportedDoc.data();

      final now = DateTime.now();
      final userChanges = ConductSanctionPlan.userUpdate(
        user: reportedUser,
        decision: decision,
        now: now,
        hasActiveIncidents: hasActiveIncidents,
      );
      if (userChanges.isNotEmpty) {
        transaction.update(reportedRef, userChanges);
      }

      final currentValidated =
          (reportedUser?['reportesValidados'] as num?)?.toInt() ?? 0;
      final nextValidated = currentValidated + 1;
      final suspendedUntilDate = ConductSanctionPlan.suspendedUntil(
        validatedReports: nextValidated,
        now: now,
      );

      final reason = reportData['motivo'] as String? ?? '';
      final notices = ConductSanctionPlan.notices(
        userId: reportedIdTx,
        reportId: reportId,
        validatedReports: nextValidated,
        reason: reason,
        now: now,
        suspendedUntil: suspendedUntilDate,
      );
      for (final notice in notices) {
        transaction.set(notifications.doc(), notice);
      }

      if (ConductSanctionPlan.suspendsAccount(nextValidated) &&
          hasActiveIncidents &&
          reportedRole == UserRole.technician.value) {
        for (final adminId in adminIds) {
          transaction.set(
            notifications.doc(),
            NotificationModel.newNotice(
              userId: adminId,
              type: NotificationType.conductReport,
              title: 'Técnico con incidencias activas',
              message:
                  'El técnico ${reportedUser?['nombre'] ?? ''} tiene '
                  'incidencias pendientes de atención; se bloquearon nuevas '
                  'asignaciones hasta reasignarlas.',
              refId: reportedIdTx,
            ),
          );
        }
      }
    });
  }
}