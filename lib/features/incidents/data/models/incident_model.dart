import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/incident.dart';

/// Convierte los documentos de la colección `incidencias` en [Incident].
class IncidentModel extends Incident {
  const IncidentModel({
    required super.id,
    required super.folio,
    required super.title,
    required super.type,
    required super.description,
    required super.housingId,
    required super.createdBy,
    required super.status,
    super.technicianId,
    super.estimatedTime,
    super.rejectionComment,
    super.evidenceBefore,
    super.evidenceAfter,
    super.createdAt,
    super.resolvedAt,
  });

  factory IncidentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('La incidencia ${doc.id} no existe');
    }
    return IncidentModel.fromMap(doc.id, data);
  }

  /// Lanza [FormatException] si el tipo o el estado no son válidos.
  factory IncidentModel.fromMap(String id, Map<String, dynamic> data) {
    final type = IncidentType.fromValue(data['tipo'] as String?);
    if (type == null) {
      throw FormatException('Tipo de incidencia no válido: ${data['tipo']}');
    }
    final status = IncidentStatus.fromValue(data['estado'] as String?);
    if (status == null) {
      throw FormatException('Estado no válido: ${data['estado']}');
    }

    return IncidentModel(
      id: id,
      folio: (data['folio'] as num?)?.toInt() ?? 0,
      title: data['nombre'] as String? ?? '',
      type: type,
      description: data['detalles'] as String? ?? '',
      housingId: data['viviendaId'] as String? ?? '',
      createdBy: data['creadaPor'] as String? ?? '',
      status: status,
      technicianId: data['tecnicoId'] as String?,
      estimatedTime: _date(data['horaEstimada']),
      rejectionComment: data['comentarioRechazo'] as String?,
      evidenceBefore: _urls(data['evidenciasAntes']),
      evidenceAfter: _urls(data['evidenciasDespues']),
      createdAt: _date(data['fechaCreacion']),
      resolvedAt: _date(data['fechaResolucion']),
    );
  }

  /// Campos del documento. `fechaCreacion` la pone el servidor al guardar.
  Map<String, dynamic> toFirestore() {
    return {
      'folio': folio,
      'nombre': title,
      'tipo': type.value,
      'detalles': description,
      'viviendaId': housingId,
      'creadaPor': createdBy,
      'tecnicoId': technicianId,
      'horaEstimada': _timestamp(estimatedTime),
      'estado': status.value,
      'comentarioRechazo': rejectionComment,
      'evidenciasAntes': evidenceBefore,
      'evidenciasDespues': evidenceAfter,
      'fechaCreacion': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'fechaResolucion': _timestamp(resolvedAt),
    };
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static Timestamp? _timestamp(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);

  static List<String> _urls(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
