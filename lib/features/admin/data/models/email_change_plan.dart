import 'package:cloud_firestore/cloud_firestore.dart';

/// Cambio de correo de otro usuario hecho por el administrador (HU-4.5).
///
/// Sin un servidor (plan Spark) la app no puede cambiar el correo con el que
/// otra persona inicia sesión en Firebase Authentication. Por eso el correo
/// nuevo queda pendiente: la próxima vez que el usuario inicie sesión se le
/// envía el enlace de verificación, y al abrirlo cambia su correo de acceso.
abstract final class EmailChangePlan {
  /// Campo con el correo nuevo que aún no se confirma.
  static const pendingField = 'correoPendiente';

  /// `true` cuando ya se envió el enlace de verificación al correo pendiente.
  static const linkSentField = 'enlaceCorreoEnviado';

  /// Campos que se guardan para el correo [newEmail] de un usuario cuyo
  /// correo actual es [currentEmail].
  static Map<String, dynamic> update({
    required String? currentEmail,
    required String newEmail,
  }) {
    final email = newEmail.trim().toLowerCase();
    if (email == currentEmail?.trim().toLowerCase()) {
      // Sin cambio (o se regresó al correo actual): no queda nada pendiente.
      return {
        pendingField: FieldValue.delete(),
        linkSentField: FieldValue.delete(),
      };
    }
    return {pendingField: email, linkSentField: false};
  }
}
