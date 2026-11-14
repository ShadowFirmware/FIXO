import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';

/// Datos que deciden quién puede usar el chat de una incidencia.
class ChatContext {
  const ChatContext({required this.incident, this.housingResidentId});

  final Incident incident;

  /// Residente activo de la vivienda de la incidencia, o `null` si no
  /// tiene (por ejemplo, porque se dio de baja al anterior).
  final String? housingResidentId;
}

/// Qué puede hacer un usuario en el chat de una incidencia (HU-5.1).
class ChatAccess {
  const ChatAccess._({
    required this.canRead,
    required this.canWrite,
    this.reason,
  });

  const ChatAccess.allowed() : this._(canRead: true, canWrite: true);
  const ChatAccess.readOnly(String reason)
    : this._(canRead: true, canWrite: false, reason: reason);
  const ChatAccess.denied(String reason)
    : this._(canRead: false, canWrite: false, reason: reason);

  /// Puede ver los mensajes.
  final bool canRead;

  /// Puede enviar mensajes.
  final bool canWrite;

  /// Por qué no puede ver el chat o, si solo puede leerlo, por qué no puede
  /// escribir. `null` si puede hacer ambas cosas.
  final String? reason;

  static const notAssignedTechnician =
      'Solo el técnico asignado a la incidencia puede usar este chat.';
  static const notActiveResident =
      'Solo el residente activo de la vivienda puede usar este chat.';
  static const notAllowed =
      'El chat solo está disponible para el residente y el técnico de la '
      'incidencia.';

  static const resolvedReadOnly =
      'La incidencia ya se resolvió. Puedes consultar los mensajes, pero ya '
      'no se pueden enviar nuevos.';
  static const rejectedReadOnly =
      'La incidencia fue rechazada. Puedes consultar los mensajes, pero ya '
      'no se pueden enviar nuevos.';
  static const waitingTechnician =
      'Podrás enviar mensajes cuando se asigne un técnico a la incidencia.';

  /// Pueden usar el chat el técnico asignado actualmente y el residente
  /// activo de la vivienda, siempre que su cuenta esté activa. No depende de
  /// quién registró la incidencia: si cambia el residente de la vivienda, el
  /// nuevo continúa el seguimiento.
  static ChatAccess of(AppUser? user, ChatContext context) {
    final read = _readAccess(user, context);
    if (!read.canRead) return read;
    return switch (readOnlyReason(context.incident)) {
      final reason? => ChatAccess.readOnly(reason),
      null => read,
    };
  }

  /// Por qué el chat de [incident] es de solo lectura, o `null` si se puede
  /// escribir: cuando la incidencia terminó (resuelta o rechazada), el chat
  /// queda como historial; antes de asignar un técnico, no hay con quién
  /// hablar.
  static String? readOnlyReason(Incident incident) {
    if (incident.chatClosed || incident.status == IncidentStatus.resolved) {
      return resolvedReadOnly;
    }
    if (incident.status == IncidentStatus.rejected) return rejectedReadOnly;
    if (incident.technicianId?.isNotEmpty != true) return waitingTechnician;
    return null;
  }

  static ChatAccess _readAccess(AppUser? user, ChatContext context) {
    if (user == null || user.accountStatus != AccountStatus.active) {
      return const ChatAccess.denied(notAllowed);
    }
    return switch (user.role) {
      UserRole.technician =>
        context.incident.technicianId == user.uid
            ? const ChatAccess.allowed()
            : const ChatAccess.denied(notAssignedTechnician),
      UserRole.resident =>
        context.housingResidentId == user.uid
            ? const ChatAccess.allowed()
            : const ChatAccess.denied(notActiveResident),
      UserRole.admin => const ChatAccess.denied(notAllowed),
    };
  }
}
