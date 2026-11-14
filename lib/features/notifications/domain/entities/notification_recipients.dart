import '../../../auth/domain/entities/app_user.dart';

/// Quién recibe los avisos (HU-6.1). Son funciones puras para poder
/// probarlas sin Firestore.
abstract final class NotificationRecipients {
  /// Residentes a los que se avisa de los cambios de una incidencia: el que
  /// la registró y el residente activo de la vivienda, que pueden ser
  /// distintos si la vivienda cambió de residente. Sin repetidos ni vacíos.
  static List<String> residents({
    required String? createdBy,
    required String? activeResidentId,
  }) => _unique([createdBy, activeResidentId]);

  /// Si el usuario con los datos [user] puede recibir avisos: debe existir
  /// y no estar dado de baja. Las cuentas suspendidas o deshabilitadas sí
  /// los reciben, porque justo entonces se les avisa de su cuenta.
  static bool canReceive(Map<String, dynamic>? user) =>
      user != null && user['estadoCuenta'] != AccountStatus.removed.value;

  static List<String> _unique(Iterable<String?> ids) => [
    ...{
      for (final id in ids)
        if (id != null && id.trim().isNotEmpty) id,
    },
  ];
}
