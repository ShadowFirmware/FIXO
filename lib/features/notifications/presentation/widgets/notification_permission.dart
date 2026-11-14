import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_permissions.dart';
import '../../../../core/theme/app_colors.dart';

/// Recuerda en el teléfono si ya se pidió el permiso de notificaciones,
/// para no insistir.
abstract interface class NotificationPromptStore {
  Future<bool> wasAsked();
  Future<void> markAsked();
}

class SharedPrefsPromptStore implements NotificationPromptStore {
  const SharedPrefsPromptStore();

  static const _key = 'avisos.permisoPedido';

  @override
  Future<bool> wasAsked() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> markAsked() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}

/// Cuándo pedir el permiso de notificaciones (HU-6.1).
abstract final class NotificationPermissionPolicy {
  /// Solo la primera vez y si todavía se puede preguntar: si ya está
  /// concedido, se negó para siempre o la plataforma no lo pide, no.
  static bool shouldAsk({
    required bool alreadyAsked,
    required PermissionState state,
  }) => !alreadyAsked && state == PermissionState.denied;

  /// Si se muestra el aviso para activarlas en la pestaña Avisos.
  static bool showBanner(PermissionState state) =>
      state == PermissionState.denied ||
      state == PermissionState.permanentlyDenied;
}

/// La primera vez que el usuario entra, explica para qué sirven las
/// notificaciones y pide el permiso, como cualquier otra app. Si lo niega
/// no se vuelve a insistir; puede activarlas después desde Avisos.
Future<void> askNotificationsOnce(
  BuildContext context, {
  AppPermissions permissions = const DeviceAppPermissions(),
  NotificationPromptStore store = const SharedPrefsPromptStore(),
}) async {
  try {
    final state = await permissions.notificationStatus();
    final asked = await store.wasAsked();
    if (!NotificationPermissionPolicy.shouldAsk(
      alreadyAsked: asked,
      state: state,
    )) {
      return;
    }
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => const NotificationPermissionDialog(),
    );
    await store.markAsked();
    if (accepted == true) await permissions.requestNotifications();
  } catch (_) {
    // Si el teléfono no permite consultar el permiso, la app sigue igual y
    // los avisos se ven en la pestaña Avisos.
  }
}

/// Explicación previa al diálogo del sistema.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('notifications.permissionDialog'),
      icon: const Icon(
        Icons.notifications_active_outlined,
        color: AppColors.primary,
        size: 36,
      ),
      title: const Text('Activa las notificaciones'),
      content: const Text(
        'FIXO te avisará en el teléfono cuando cambie el estado de tus '
        'incidencias y cuando haya novedades sobre tu cuenta.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          key: const Key('notifications.permissionLater'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          key: const Key('notifications.permissionAllow'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Activar'),
        ),
      ],
    );
  }
}

/// Aviso en la pestaña Avisos cuando las notificaciones del teléfono están
/// desactivadas, con la opción de activarlas. Si el sistema ya no vuelve a
/// preguntar, abre los ajustes de la app.
class NotificationsPermissionBanner extends StatefulWidget {
  const NotificationsPermissionBanner({
    super.key,
    this.permissions = const DeviceAppPermissions(),
  });

  final AppPermissions permissions;

  @override
  State<NotificationsPermissionBanner> createState() =>
      _NotificationsPermissionBannerState();
}

class _NotificationsPermissionBannerState
    extends State<NotificationsPermissionBanner>
    with WidgetsBindingObserver {
  PermissionState _state = PermissionState.notRequired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didUpdateWidget(NotificationsPermissionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permissions != widget.permissions) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes del teléfono se revisa otra vez.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    PermissionState state;
    try {
      state = await widget.permissions.notificationStatus();
    } catch (_) {
      state = PermissionState.notRequired;
    }
    if (mounted) setState(() => _state = state);
  }

  Future<void> _enable() async {
    try {
      var state = _state;
      if (state == PermissionState.denied) {
        state = await widget.permissions.requestNotifications();
      }
      if (state == PermissionState.permanentlyDenied) {
        await widget.permissions.openSettings();
      }
    } catch (_) {
      // Se queda como estaba.
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!NotificationPermissionPolicy.showBanner(_state)) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const Key('notifications.permissionBanner'),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Las notificaciones del teléfono están desactivadas. Actívalas '
              'para enterarte al momento.',
              style: textTheme.bodySmall,
            ),
          ),
          TextButton(
            key: const Key('notifications.enable'),
            onPressed: _enable,
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }
}
