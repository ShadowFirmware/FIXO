import 'dart:typed_data';

import 'package:fixo/features/admin/data/datasources/history_pdf_exporter.dart';
import 'package:fixo/features/admin/domain/entities/history_incident.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';

/// Incidencia de prueba para el historial (HU-4.11).
IncidentModel historyIncident(
  int folio, {
  IncidentStatus status = IncidentStatus.pending,
  IncidentType type = IncidentType.water,
  DateTime? createdAt,
  DateTime? resolvedAt,
  String housingId = 'viv-4b',
  String createdBy = 'res-ana',
  String? technicianId,
  String? solution,
  String? rejectionComment,
  String? description,
  List<String> before = const [],
  List<String> after = const [],
}) => IncidentModel(
  id: 'inc-$folio',
  folio: folio,
  title: 'Incidencia $folio',
  type: type,
  description: description ?? 'Detalles de la incidencia $folio',
  housingId: housingId,
  createdBy: createdBy,
  status: status,
  technicianId: technicianId,
  solution: solution,
  rejectionComment: rejectionComment,
  evidenceBefore: before,
  evidenceAfter: after,
  createdAt: createdAt,
  resolvedAt: resolvedAt,
);

/// La incidencia con los nombres que pondría el repositorio.
HistoryIncident historyRecord(
  Incident incident, {
  String housingLabel = 'Torre A – 4B',
  String reporterName = 'Ana López',
  String? technicianName,
}) => HistoryIncident(
  incident: incident,
  housingLabel: housingLabel,
  reporterName: reporterName,
  technicianName: technicianName,
);

/// Guarda lo que se exportaría en lugar de generar y compartir el PDF.
class FakeHistoryPdfExporter implements HistoryPdfExporter {
  List<HistoryIncident>? records;
  List<String>? filterLines;
  DateTime? generatedAt;
  String? sharedFileName;
  Object? error;

  @override
  Future<Uint8List> build({
    required List<HistoryIncident> records,
    required List<String> filterLines,
    required DateTime generatedAt,
  }) async {
    if (error != null) throw error!;
    this.records = records;
    this.filterLines = filterLines;
    this.generatedAt = generatedAt;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> share(Uint8List bytes, {required String fileName}) async {
    sharedFileName = fileName;
  }
}
