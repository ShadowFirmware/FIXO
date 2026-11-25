import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../conduct_reports/data/models/conduct_report_model.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../models/conduct_review_plan.dart';

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
  /// revisa las reglas de [ConductReviewPlan] con los datos actuales y
  /// guarda el estado, la fecha y quién lo revisó.
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  }) {
    final reportRef = _reports.doc(reportId);
    final reviewerRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(reviewerId);

    return _firestore.runTransaction((transaction) async {
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
    });
  }
}
