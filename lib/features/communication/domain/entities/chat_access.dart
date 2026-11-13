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
  const ChatAccess._({required this.canRead, this.reason});

  const ChatAccess.allowed() : this._(canRead: true);
  const ChatAccess.denied(String reason)
    : this._(canRead: false, reason: reason);

  /// Puede ver los mensajes.
  final bool canRead;

  /// Por qué no puede ver el chat, o `null` si puede.
  final String? reason;

  static const notAssignedTechnician =
      'Solo el técnico asignado a la incidencia puede usar este chat.';
  static const notActiveResident =
      'Solo el residente activo de la vivienda puede usar este chat.';
  static const notAllowed =
      'El chat solo está disponible para el residente y el técnico de la '
      'incidencia.';

  /// Pueden usar el chat el técnico asignado actualmente y el residente
  /// activo de la vivienda, siempre que su cuenta esté activa. No depende de
  /// quién registró la incidencia: si cambia el residente de la vivienda, el
  /// nuevo continúa el seguimiento.
  static ChatAccess of(AppUser? user, ChatContext context) {
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
