import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../datasources/incident_admin_remote_data_source.dart';

/// Reglas de la asignación de un técnico (HU-4.9), aplicadas sobre los
/// documentos que se leen dentro de la transacción. Son funciones puras
/// para poder probarlas sin Firestore.
abstract final class AssignmentPlan {
  /// Lanza [IncidentNotPendingException] si la incidencia ya no está
  /// pendiente, o [TechnicianUnavailableException] si el técnico no puede
  /// recibirla.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? technician,
    required DateTime now,
  }) {
    if (incident == null ||
        incident['estado'] != IncidentStatus.pending.value) {
      throw const IncidentNotPendingException();
    }
    if (!canReceiveAssignment(technician, now: now)) {
      throw const TechnicianUnavailableException();
    }
  }

  /// Cambios en la incidencia: pasa de Pendiente a Asignada con el técnico
  /// y la hora estimada. La fecha de asignación la pone el servidor.
  static Map<String, dynamic> incidentUpdate({
    required String technicianId,
    required DateTime estimatedTime,
  }) => {
    'estado': IncidentStatus.assigned.value,
    'tecnicoId': technicianId,
    'horaEstimada': Timestamp.fromDate(estimatedTime),
    'fechaAsignacion': FieldValue.serverTimestamp(),
  };

  /// Un técnico con cuenta activa y estado Disponible. Nunca uno
  /// suspendido, desactivado, dado de baja o con otro rol.
  static bool canReceiveAssignment(
    Map<String, dynamic>? technician, {
    required DateTime now,
  }) {
    if (technician == null) return false;
    if (technician['rol'] != UserRole.technician.value) return false;
    if (technician['estadoCuenta'] != AccountStatus.active.value) return false;
    if (technician['disponible'] != true) return false;
    final suspendedUntil = technician['suspendidaHasta'];
    if (suspendedUntil is Timestamp && suspendedUntil.toDate().isAfter(now)) {
      return false;
    }
    return true;
  }
}
