import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';

/// Motivo de un reporte de conducta (HU-7.1). El valor es el que se guarda
/// en Firestore.
enum ConductReason {
  delay(
    'retraso',
    'Retraso',
    'Llegó tarde o no se presentó a la hora acordada',
  ),
  badAttitude('mala_actitud', 'Mala actitud', 'Trato grosero o irrespetuoso'),
  poorWork(
    'trabajo_mal_realizado',
    'Trabajo mal realizado',
    'El problema no quedó resuelto o se causaron daños',
  ),
  inappropriateLanguage(
    'lenguaje_inapropiado',
    'Lenguaje inapropiado',
    'Insultos, groserías o comentarios ofensivos',
  ),
  other(
    'otro',
    'Otro motivo',
    'Otra situación inapropiada durante la atención',
  );

  const ConductReason(this.value, this.label, this.hint);

  /// Valor guardado en Firestore.
  final String value;

  /// Texto que se muestra al usuario.
  final String label;

  /// Explicación breve para elegir el motivo correcto.
  final String hint;

  /// Motivos con los que el residente reporta al técnico (T 7.1.3).
  static const forTechnician = values;

  static ConductReason? fromValue(String? value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return null;
  }
}

/// Estado de revisión de un reporte de conducta. Todo reporte empieza
/// Pendiente de revisión; el administrador lo valida o lo rechaza (HU-7.3).
enum ConductReportStatus {
  pendingReview('pendiente_revision', 'Pendiente de revisión'),
  validated('validado', 'Validado'),
  rejected('rechazado', 'Rechazado');

  const ConductReportStatus(this.value, this.label);

  final String value;
  final String label;

  static ConductReportStatus? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Reporte de conducta que un usuario levanta contra la contraparte de una
/// incidencia resuelta (HU-7.1).
class ConductReport {
  const ConductReport({
    required this.id,
    required this.folio,
    required this.incidentId,
    required this.incidentFolio,
    required this.incidentTitle,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    required this.reportedId,
    required this.reportedName,
    required this.reportedRole,
    required this.reason,
    required this.description,
    required this.status,
    this.evidence = const [],
    this.createdAt,
  });

  /// ID del documento: uno por usuario e incidencia (ver [docIdFor]).
  final String id;

  /// Número único y consecutivo del reporte.
  final int folio;

  /// Incidencia resuelta a la que pertenece el reporte.
  final String incidentId;
  final int incidentFolio;
  final String incidentTitle;

  /// Quién levantó el reporte.
  final String reporterId;
  final String reporterName;
  final UserRole reporterRole;

  /// Contra quién es el reporte.
  final String reportedId;
  final String reportedName;
  final UserRole reportedRole;

  final ConductReason reason;
  final String description;

  /// URLs de las fotos, videos o capturas del chat.
  final List<String> evidence;

  final ConductReportStatus status;

  /// Hora del servidor, o `null` mientras no llega a Firestore.
  final DateTime? createdAt;

  /// Número de reporte para mostrar, por ejemplo "RC-0003".
  String get reportNumber => formatReportNumber(folio);

  /// Folio de la incidencia relacionada, por ejemplo "INC-0007".
  String get incidentNumber => Incident.formatReportNumber(incidentFolio);

  /// Solo un reporte validado cuenta como antecedente de conducta.
  bool get countsAsRecord => status == ConductReportStatus.validated;

  static String formatReportNumber(int folio) =>
      'RC-${folio.toString().padLeft(4, '0')}';

  /// Cada usuario puede levantar como máximo un reporte por incidencia
  /// (T 7.1.6), así que el ID del documento se arma con ambos: si ya
  /// existe, el reporte está duplicado.
  static String docIdFor({
    required String incidentId,
    required String reporterId,
  }) => '${incidentId}_$reporterId';
}

/// Datos que captura el residente en el formulario del reporte.
class NewConductReport {
  const NewConductReport({
    required this.target,
    required this.reason,
    required this.description,
    this.evidence = const [],
  });

  final ConductReportTarget target;
  final ConductReason reason;
  final String description;

  /// Archivos del dispositivo, antes de subirse.
  final List<EvidenceFile> evidence;
}

/// Incidencia resuelta y técnico al que se reporta, tal como los ve el
/// residente en el detalle. La transacción vuelve a revisar los datos.
class ConductReportTarget {
  const ConductReportTarget({
    required this.incidentId,
    required this.incidentNumber,
    required this.incidentTitle,
    required this.technicianId,
    required this.technicianName,
  });

  final String incidentId;
  final String incidentNumber;
  final String incidentTitle;
  final String technicianId;
  final String technicianName;
}
