/// Tipo de aviso. El valor es el que se guarda en Firestore.
enum NotificationType {
  /// Al administrador: una incidencia nueva espera asignación (HU-2.3).
  newIncident('nueva_incidencia'),

  /// Al residente y al técnico: se asignó la incidencia (HU-4.9).
  incidentAssigned('incidencia_asignada'),

  /// Al residente y al administrador: comenzó la atención (HU-3.5).
  incidentInProgress('incidencia_en_proceso'),

  /// Al residente y al administrador: se resolvió (HU-3.7).
  incidentResolved('incidencia_resuelta'),

  /// Al residente: se rechazó, con el motivo (HU-4.10).
  incidentRejected('incidencia_rechazada'),

  /// Al administrador: se levantó un reporte de conducta.
  conductReport('reporte_conducta'),

  /// Al usuario reportado: se validó un reporte en su contra.
  conductWarning('advertencia_conducta'),

  /// Al usuario: su cuenta se suspendió por un tiempo.
  accountSuspended('cuenta_suspendida'),

  /// Al usuario: su cuenta volvió a estar activa.
  accountReactivated('cuenta_reactivada'),

  /// Al usuario: su cuenta se deshabilitó sin fecha de término.
  accountDisabled('cuenta_deshabilitada');

  const NotificationType(this.value);

  final String value;

  /// Los avisos de incidencias apuntan a una incidencia en `refId`.
  bool get isIncident => switch (this) {
    newIncident ||
    incidentAssigned ||
    incidentInProgress ||
    incidentResolved ||
    incidentRejected => true,
    _ => false,
  };

  static NotificationType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Aviso para un usuario (HU-6.1).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.refId,
    this.read = false,
    this.date,
  });

  final String id;

  /// UID de quien lo recibe.
  final String userId;

  /// `null` si el tipo no se reconoce (por ejemplo, de una versión más
  /// nueva de la app); el aviso se muestra igual.
  final NotificationType? type;
  final String title;
  final String message;

  /// Documento al que se refiere, como la incidencia.
  final String? refId;
  final bool read;

  /// Hora del servidor, o `null` mientras no llega a Firestore.
  final DateTime? date;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    message: message,
    refId: refId,
    read: read ?? this.read,
    date: date,
  );

  /// ID de la incidencia a la que lleva el aviso, o `null` si no lleva a
  /// una.
  String? get incidentId {
    final ref = refId;
    return type?.isIncident == true && ref != null && ref.isNotEmpty
        ? ref
        : null;
  }
}
