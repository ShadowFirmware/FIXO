import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class FixoApp extends StatelessWidget {
  const FixoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIXO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
