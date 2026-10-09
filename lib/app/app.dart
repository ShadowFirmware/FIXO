import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'theme/app_theme.dart';

class FixoApp extends StatelessWidget {
  const FixoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIXO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
