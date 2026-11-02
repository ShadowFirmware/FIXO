import '../../../incidents/domain/entities/incident.dart';

/// Incidencia del historial del administrador (HU-4.11), con los nombres
/// que se muestran en lugar de los identificadores.
class HistoryIncident {
  const HistoryIncident({
    required this.incident,
    required this.housingLabel,
    required this.reporterName,
  });

  final Incident incident;

  /// Departamento o lugar, por ejemplo "Torre A – 4B".
  final String housingLabel;

  /// Nombre del residente que registró la incidencia.
  final String reporterName;

  String get id => incident.id;
}
