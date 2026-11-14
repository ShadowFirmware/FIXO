import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Estado de un permiso del teléfono.
enum PermissionState {
  /// Se puede usar.
  granted,

  /// No se ha concedido, pero se puede volver a pedir.
  denied,

  /// Se negó de forma que el sistema ya no vuelve a preguntar: solo se
  /// puede activar desde los ajustes del teléfono.
  permanentlyDenied,

  /// La plataforma no pide este permiso (por ejemplo, en la web).
  notRequired,
}

/// Permisos que pide FIXO la primera vez que necesita la función, como
/// cualquier otra app.
abstract interface class AppPermissions {
  /// Estado del permiso de notificaciones, sin preguntar.
  Future<PermissionState> notificationStatus();

  /// Pide el permiso de notificaciones (el sistema muestra su diálogo).
  Future<PermissionState> requestNotifications();

  /// Pide el permiso de la cámara antes de usarla.
  Future<PermissionState> requestCamera();

  /// Abre los ajustes de la app en el teléfono. `false` si no se pudo.
  Future<bool> openSettings();
}

/// Permisos reales del dispositivo.
///
/// * Android: `permission_handler`, que distingue si el permiso se negó
///   para siempre y puede abrir los ajustes.
/// * iOS: el sistema pregunta al usar la cámara (con los textos de
///   `Info.plist`) y las notificaciones se piden con
///   `flutter_local_notifications`.
/// * Web y escritorio: no se pide nada.
class DeviceAppPermissions implements AppPermissions {
  const DeviceAppPermissions();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<PermissionState> notificationStatus() async {
    if (_isAndroid) return _from(await Permission.notification.status);
    if (_isIOS) {
      final options = await _iosNotifications?.checkPermissions();
      return options?.isEnabled == true
          ? PermissionState.granted
          : PermissionState.denied;
    }
    return PermissionState.notRequired;
  }

  @override
  Future<PermissionState> requestNotifications() async {
    if (_isAndroid) return _from(await Permission.notification.request());
    if (_isIOS) {
      final granted = await _iosNotifications?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted == true
          ? PermissionState.granted
          : PermissionState.permanentlyDenied;
    }
    return PermissionState.notRequired;
  }

  @override
  Future<PermissionState> requestCamera() async {
    if (_isAndroid) return _from(await Permission.camera.request());
    // En iOS pregunta el propio sistema al abrir la cámara.
    return PermissionState.notRequired;
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  static IOSFlutterLocalNotificationsPlugin? get _iosNotifications =>
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

  static PermissionState _from(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => PermissionState.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => PermissionState.permanentlyDenied,
    PermissionStatus.denied => PermissionState.denied,
  };
}
