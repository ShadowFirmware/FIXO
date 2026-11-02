import '../../../incidents/domain/entities/incident.dart';

/// Incidencia pendiente de asignación con los datos que el administrador
/// necesita ver (HU-4.8): el departamento y el nombre de quien la reportó.
class PendingIncident {
  const PendingIncident({
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
