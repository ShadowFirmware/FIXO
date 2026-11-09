import '../../../housing/domain/entities/housing.dart';
import '../../../incidents/domain/entities/incident.dart';

/// Incidencia asignada al técnico (HU-3.3), con el lugar y el residente
/// que la reportó, para que sepa a dónde ir y a quién contactar.
class AssignedIncident {
  const AssignedIncident({
    required this.incident,
    required this.housingLabel,
    required this.residentName,
    this.housing,
    this.residentPhone,
    this.residentEmail,
  });

  final Incident incident;

  /// Departamento o lugar, por ejemplo "Torre A – 4B".
  final String housingLabel;

  /// Vivienda donde se reportó la incidencia (HU-3.4), o `null` si ya no
  /// existe.
  final Housing? housing;

  /// Nombre del residente que registró la incidencia.
  final String residentName;

  /// Teléfono y correo del residente, o `null` si no los tiene registrados.
  final String? residentPhone;
  final String? residentEmail;

  String get id => incident.id;
  IncidentStatus get status => incident.status;
}
