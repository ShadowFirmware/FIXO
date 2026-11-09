import '../../../incidents/domain/entities/incident.dart';

/// Incidencia asignada al técnico (HU-3.3), con el lugar y el residente
/// que la reportó, para que sepa a dónde ir y a quién contactar.
class AssignedIncident {
  const AssignedIncident({
    required this.incident,
    required this.housingLabel,
    required this.residentName,
    this.residentPhone,
  });

  final Incident incident;

  /// Departamento o lugar, por ejemplo "Torre A – 4B".
  final String housingLabel;

  /// Nombre del residente que registró la incidencia.
  final String residentName;

  /// Teléfono del residente, o `null` si no lo tiene registrado.
  final String? residentPhone;

  String get id => incident.id;
  IncidentStatus get status => incident.status;
}
