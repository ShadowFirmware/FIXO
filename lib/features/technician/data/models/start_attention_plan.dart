import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';

/// La incidencia no está asignada al técnico que quiere atenderla.
class NotAssignedToTechnicianException implements Exception {
  const NotAssignedToTechnicianException();
}

/// La cuenta del técnico no está activa o está suspendida.
class TechnicianCannotAttendException implements Exception {
  const TechnicianCannotAttendException();
}

/// La atención ya había comenzado (por ejemplo, desde otro dispositivo).
class AttentionAlreadyStartedException implements Exception {
  const AttentionAlreadyStartedException();
}

/// La incidencia ya no está Asignada (se resolvió, se rechazó o volvió a
/// quedar pendiente).
class AttentionNotAvailableException implements Exception {
  const AttentionNotAvailableException(this.status);

  /// Estado en que se encuentra, o `null` si no es válido.
  final IncidentStatus? status;
}

/// Reglas para comenzar la atención de una incidencia (HU-3.4 y HU-3.5),
/// aplicadas sobre los documentos que se leen dentro de la transacción.
/// Son funciones puras para poder probarlas sin Firestore.
abstract final class StartAttentionPlan {
  static const inProgressType = 'incidencia_en_proceso';

  /// Solo el técnico asignado, con su cuenta activa, puede comenzarla, y
  /// solo si está Asignada.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? technician,
    required String technicianId,
    required DateTime now,
  }) {
    if (incident == null || incident['tecnicoId'] != technicianId) {
      throw const NotAssignedToTechnicianException();
    }
    if (!canAttend(technician, now: now)) {
      throw const TechnicianCannotAttendException();
    }
    final status = incident['estado'];
    if (status == IncidentStatus.inProgress.value) {
      throw const AttentionAlreadyStartedException();
    }
    if (status != IncidentStatus.assigned.value) {
      throw AttentionNotAvailableException(
        IncidentStatus.fromValue(status as String?),
      );
    }
  }

  /// Un técnico con cuenta activa y sin suspensión vigente. A diferencia de
  /// la asignación, no importa si está Disponible: al asignarle la
  /// incidencia dejó de estarlo.
  static bool canAttend(
    Map<String, dynamic>? technician, {
    required DateTime now,
  }) {
    if (technician == null) return false;
    if (technician['rol'] != UserRole.technician.value) return false;
    if (technician['estadoCuenta'] != AccountStatus.active.value) return false;
    final suspendedUntil = technician['suspendidaHasta'];
    return !(suspendedUntil is Timestamp &&
        suspendedUntil.toDate().isAfter(now));
  }

  /// La incidencia pasa a En proceso. La hora de inicio la pone el
  /// servidor.
  static Map<String, dynamic> get incidentUpdate => {
    'estado': IncidentStatus.inProgress.value,
    'fechaInicioAtencion': FieldValue.serverTimestamp(),
  };

  /// Aviso de que el técnico comenzó a atender el reporte, para el
  /// residente y para cada administrador (HU-3.5).
  static Map<String, dynamic> notice({
    required String userId,
    required String incidentId,
    required String reportNumber,
    required String title,
    required String technicianName,
  }) => {
    'usuarioId': userId,
    'tipo': inProgressType,
    'titulo': 'Incidencia $reportNumber en proceso',
    'mensaje': '$technicianName comenzó a atender "$title".',
    'refId': incidentId,
    'leida': false,
    'fecha': FieldValue.serverTimestamp(),
  };
}
