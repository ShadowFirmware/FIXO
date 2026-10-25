/// Tipo de incidencia (HU-2.3).
enum IncidentType {
  electricity('luz', 'Luz'),
  water('agua', 'Agua'),
  structure('estructura', 'Estructura'),
  other('otros', 'Otros');

  const IncidentType(this.value, this.label);

  /// Valor guardado en Firestore.
  final String value;

  /// Texto que se muestra al usuario.
  final String label;

  static IncidentType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Estado de una incidencia a lo largo de su atención.
enum IncidentStatus {
  pending('pendiente', 'Pendiente'),
  assigned('asignada', 'Asignada'),
  inProgress('en_proceso', 'En proceso'),
  resolved('resuelta', 'Resuelta'),
  rejected('rechazada', 'Rechazada');

  const IncidentStatus(this.value, this.label);

  final String value;
  final String label;

  static IncidentStatus? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Incidencia reportada por un residente.
class Incident {
  const Incident({
    required this.id,
    required this.folio,
    required this.title,
    required this.type,
    required this.description,
    required this.housingId,
    required this.createdBy,
    required this.status,
    this.technicianId,
    this.estimatedTime,
    this.rejectionComment,
    this.rejectedAt,
    this.solution,
    this.evidenceBefore = const [],
    this.evidenceAfter = const [],
    this.createdAt,
    this.resolvedAt,
  });

  final String id;

  /// Número único y consecutivo del reporte.
  final int folio;

  final String title;
  final IncidentType type;
  final String description;

  /// Vivienda del residente al momento de reportar. Queda fija aunque el
  /// residente cambie de vivienda después.
  final String housingId;

  /// UID del residente que la registró.
  final String createdBy;

  final IncidentStatus status;
  final String? technicianId;

  /// Cuándo va a llegar el técnico.
  final DateTime? estimatedTime;

  /// Motivo y fecha del rechazo, registrados por el administrador.
  final String? rejectionComment;
  final DateTime? rejectedAt;

  /// Descripción de la solución aplicada, registrada por el técnico.
  final String? solution;

  /// URLs de las fotos y videos del problema (al registrar) y de la
  /// solución (al resolver).
  final List<String> evidenceBefore;
  final List<String> evidenceAfter;

  final DateTime? createdAt;
  final DateTime? resolvedAt;

  /// Número de reporte para mostrar, por ejemplo "INC-0007".
  String get reportNumber => formatReportNumber(folio);

  static String formatReportNumber(int folio) =>
      'INC-${folio.toString().padLeft(4, '0')}';
}
