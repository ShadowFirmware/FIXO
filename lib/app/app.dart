import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/presentation/providers/notification_alerts.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class FixoApp extends StatefulWidget {
  const FixoApp({super.key});

  @override
  State<FixoApp> createState() => _FixoAppState();
}

class _FixoAppState extends State<FixoApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// Notificaciones del teléfono con los avisos nuevos (HU-6.1).
  late final _alerts = NotificationAlerts(navigatorKey: _navigatorKey);

  @override
  void initState() {
    super.initState();
    _alerts.attach();
  }

  @override
  void dispose() {
    _alerts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FIXO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Textos del sistema (calendario, copiar y pegar) en español.
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: RouteNames.splash,
      // Evita que Flutter apile una ruta '/' inexistente debajo del arranque,
      // lo que provocaba una flecha de regreso sin destino.
      onGenerateInitialRoutes: (initialRoute) => [
        AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
