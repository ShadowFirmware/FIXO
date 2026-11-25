import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/conduct_report.dart';

/// Convierte los documentos de la colección `reportesConducta` en
/// [ConductReport] (T 7.1.7).
class ConductReportModel extends ConductReport {
  const ConductReportModel({
    required super.id,
    required super.folio,
    required super.incidentId,
    required super.incidentFolio,
    required super.incidentTitle,
    required super.reporterId,
    required super.reporterName,
    required super.reporterRole,
    required super.reportedId,
    required super.reportedName,
    required super.reportedRole,
    required super.reason,
    required super.description,
    required super.status,
    super.evidence,
    super.createdAt,
    super.reviewedAt,
    super.reviewerId,
    super.reviewerName,
  });

  /// Lanza [FormatException] si el motivo, el estado o algún rol no son
  /// válidos.
  factory ConductReportModel.fromMap(String id, Map<String, dynamic> data) {
    final reason = ConductReason.fromValue(data['motivo'] as String?);
    if (reason == null) {
      throw FormatException('Motivo no válido: ${data['motivo']}');
    }
    final status = ConductReportStatus.fromValue(data['estado'] as String?);
    if (status == null) {
      throw FormatException('Estado no válido: ${data['estado']}');
    }
    final reporterRole = UserRole.fromValue(data['reportanteRol'] as String?);
    final reportedRole = UserRole.fromValue(data['reportadoRol'] as String?);
    if (reporterRole == null || reportedRole == null) {
      throw const FormatException('Rol no válido en el reporte');
    }

    return ConductReportModel(
      id: id,
      folio: (data['folio'] as num?)?.toInt() ?? 0,
      incidentId: data['incidenciaId'] as String? ?? '',
      incidentFolio: (data['incidenciaFolio'] as num?)?.toInt() ?? 0,
      incidentTitle: data['incidenciaTitulo'] as String? ?? '',
      reporterId: data['reportanteId'] as String? ?? '',
      reporterName: data['reportanteNombre'] as String? ?? '',
      reporterRole: reporterRole,
      reportedId: data['reportadoId'] as String? ?? '',
      reportedName: data['reportadoNombre'] as String? ?? '',
      reportedRole: reportedRole,
      reason: reason,
      description: data['descripcion'] as String? ?? '',
      status: status,
      evidence: data['evidencias'] is List
          ? (data['evidencias'] as List).whereType<String>().toList()
          : const [],
      createdAt: (data['fechaCreacion'] as Timestamp?)?.toDate(),
      reviewedAt: (data['fechaRevision'] as Timestamp?)?.toDate(),
      reviewerId: data['revisadoPorId'] as String?,
      reviewerName: data['revisadoPorNombre'] as String?,
    );
  }

  /// Campos del documento al registrarlo (HU-7.1 y HU-7.2). `fechaCreacion`
  /// la pone el servidor al guardar. Los datos de la revisión los agrega el
  /// administrador después (HU-7.3, `ConductReviewPlan`).
  Map<String, dynamic> toFirestore() => {
    'folio': folio,
    'incidenciaId': incidentId,
    'incidenciaFolio': incidentFolio,
    'incidenciaTitulo': incidentTitle,
    'reportanteId': reporterId,
    'reportanteNombre': reporterName,
    'reportanteRol': reporterRole.value,
    'reportadoId': reportedId,
    'reportadoNombre': reportedName,
    'reportadoRol': reportedRole.value,
    'motivo': reason.value,
    'descripcion': description,
    'evidencias': evidence,
    'estado': status.value,
    'fechaCreacion': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };
}
