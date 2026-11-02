import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../incidents/domain/entities/incident.dart';
import '../datasources/incident_admin_remote_data_source.dart';

/// Reglas y datos del rechazo de una incidencia (HU-4.10), aplicados sobre
/// el documento que se lee dentro de la transacción. Son funciones puras
/// para poder probarlas sin Firestore.
abstract final class RejectionPlan {
  /// Lanza [IncidentNotPendingException] si la incidencia ya no está
  /// pendiente: solo se rechaza lo que aún no se ha asignado.
  static void validate(Map<String, dynamic>? incident) {
    if (incident == null ||
        incident['estado'] != IncidentStatus.pending.value) {
      throw const IncidentNotPendingException();
    }
  }

  /// Cambios en la incidencia: pasa de Pendiente a Rechazada con el motivo
  /// y la fecha. Una incidencia rechazada nunca tiene técnico ni hora
  /// estimada.
  static Map<String, dynamic> incidentUpdate({required String comment}) => {
    'estado': IncidentStatus.rejected.value,
    'comentarioRechazo': comment,
    'fechaRechazo': FieldValue.serverTimestamp(),
    'tecnicoId': null,
    'horaEstimada': null,
  };
}
