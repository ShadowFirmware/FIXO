import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/date_formats.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../datasources/incident_admin_remote_data_source.dart';

/// Reglas de la asignación de un técnico (HU-4.9), aplicadas sobre los
/// documentos que se leen dentro de la transacción. Son funciones puras
/// para poder probarlas sin Firestore.
abstract final class AssignmentPlan {
  /// Lanza [IncidentRejectedException] si la incidencia fue rechazada,
  /// [IncidentNotPendingException] si ya no está pendiente por otra razón,
  /// o [TechnicianUnavailableException] si el técnico no puede recibirla.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? technician,
    required DateTime now,
  }) {
    if (incident?['estado'] == IncidentStatus.rejected.value) {
      throw const IncidentRejectedException();
    }
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

  /// Cambios en el técnico: queda No disponible hasta que complete el
  /// reporte de la incidencia, así no se le asigna otra mientras tanto.
  static const technicianUpdate = <String, dynamic>{'disponible': false};

  /// Aviso al residente con el nombre del técnico y la hora estimada.
  static Map<String, dynamic> residentNotice({
    required String residentId,
    required String incidentId,
    required String reportNumber,
    required String title,
    required String technicianName,
    required DateTime estimatedTime,
  }) => _notice(
    userId: residentId,
    incidentId: incidentId,
    title: 'Incidencia $reportNumber asignada',
    message:
        '$technicianName atenderá "$title". Hora estimada de llegada: '
        '${DateFormats.dateTime(estimatedTime)}',
  );

  /// Aviso al técnico con los detalles de la incidencia asignada.
  static Map<String, dynamic> technicianNotice({
    required String technicianId,
    required String incidentId,
    required String reportNumber,
    required String title,
    required String typeLabel,
    required String housingLabel,
    required String description,
    required DateTime estimatedTime,
  }) {
    final details = description.trim();
    return _notice(
      userId: technicianId,
      incidentId: incidentId,
      title: 'Nueva asignación $reportNumber',
      message: [
        'Se te asignó "$title" ($typeLabel) en $housingLabel.',
        if (details.isNotEmpty) 'Detalles: ${_shorten(details)}',
        'Hora estimada de llegada: ${DateFormats.dateTime(estimatedTime)}',
      ].join(' '),
    );
  }

  static const _maxDetails = 200;

  static String _shorten(String text) => text.length <= _maxDetails
      ? text
      : '${text.substring(0, _maxDetails).trimRight()}…';

  static Map<String, dynamic> _notice({
    required String userId,
    required String incidentId,
    required String title,
    required String message,
  }) => {
    'usuarioId': userId,
    'tipo': IncidentAdminRemoteDataSource.assignedType,
    'titulo': title,
    'mensaje': message,
    'refId': incidentId,
    'leida': false,
    'fecha': FieldValue.serverTimestamp(),
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
