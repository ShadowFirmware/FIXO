import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../incidents/domain/entities/incident.dart';

/// La incidencia no está asignada al técnico que quiere atenderla.
class NotAssignedToTechnicianException implements Exception {
  const NotAssignedToTechnicianException();
}

/// La atención ya había comenzado (por ejemplo, desde otro dispositivo).
class AttentionAlreadyStartedException implements Exception {
  const AttentionAlreadyStartedException();
}

/// La incidencia ya no está Asignada (se resolvió, se rechazó o volvió a
/// quedar pendiente).
class AttentionNotAvailableException implements Exception {
  const AttentionNotAvailableException();
}

/// Reglas para comenzar la atención de una incidencia (HU-3.4), aplicadas
/// sobre el documento que se lee dentro de la transacción. Son funciones
/// puras para poder probarlas sin Firestore.
abstract final class StartAttentionPlan {
  static const inProgressType = 'incidencia_en_proceso';

  /// Solo el técnico asignado puede comenzarla, y solo si está Asignada.
  static void validate({
    required Map<String, dynamic>? incident,
    required String technicianId,
  }) {
    if (incident == null || incident['tecnicoId'] != technicianId) {
      throw const NotAssignedToTechnicianException();
    }
    final status = incident['estado'];
    if (status == IncidentStatus.inProgress.value) {
      throw const AttentionAlreadyStartedException();
    }
    if (status != IncidentStatus.assigned.value) {
      throw const AttentionNotAvailableException();
    }
  }

  /// La incidencia pasa a En proceso. La hora de inicio la pone el
  /// servidor.
  static Map<String, dynamic> get incidentUpdate => {
    'estado': IncidentStatus.inProgress.value,
    'fechaInicioAtencion': FieldValue.serverTimestamp(),
  };

  /// Aviso al residente de que el técnico comenzó a atender su reporte.
  static Map<String, dynamic> residentNotice({
    required String residentId,
    required String incidentId,
    required String reportNumber,
    required String title,
    required String technicianName,
  }) => {
    'usuarioId': residentId,
    'tipo': inProgressType,
    'titulo': 'Incidencia $reportNumber en proceso',
    'mensaje': '$technicianName comenzó a atender "$title".',
    'refId': incidentId,
    'leida': false,
    'fecha': FieldValue.serverTimestamp(),
  };
}
