import 'evidence_file.dart';
import 'incident.dart';

/// Datos que captura el residente para registrar una incidencia.
class NewIncident {
  const NewIncident({
    required this.title,
    required this.type,
    required this.description,
    this.evidence = const [],
  });

  final String title;
  final IncidentType type;
  final String description;
  final List<EvidenceFile> evidence;
}
