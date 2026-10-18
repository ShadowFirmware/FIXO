import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/communication/presentation/screens/incident_chat_screen.dart';
import '../../features/resident/presentation/screens/edit_profile_screen.dart';
import '../../features/resident/presentation/screens/incident_detail_screen.dart';
import '../../features/resident/presentation/screens/register_incident_screen.dart';
import '../../features/resident/presentation/screens/resident_shell_screen.dart';
import 'route_names.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return _page(const LoginScreen(), settings);
      case RouteNames.forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);
      case RouteNames.residentShell:
        return _page(const ResidentShellScreen(), settings);
      case RouteNames.registerIncident:
        return _page(const RegisterIncidentScreen(), settings);
      case RouteNames.incidentDetail:
        return _page(
          IncidentDetailScreen(incidentId: settings.arguments! as String),
          settings,
        );
      case RouteNames.editProfile:
        return _page(const EditProfileScreen(), settings);
      case RouteNames.incidentChat:
        return _page(
          IncidentChatScreen(incidentId: settings.arguments! as String),
          settings,
        );
      default:
        return _page(
          Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget screen,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}
