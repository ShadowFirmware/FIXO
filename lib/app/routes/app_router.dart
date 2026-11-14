import 'package:flutter/material.dart';

import '../../features/admin/presentation/providers/admin_users_view_model.dart';
import '../../features/admin/presentation/screens/admin_edit_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_housings_screen.dart';
import '../../features/admin/presentation/screens/admin_incident_history_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_pending_incidents_screen.dart';
import '../../features/admin/presentation/screens/admin_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_statistics_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_session.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/communication/presentation/screens/incident_chat_screen.dart';

import '../../features/resident/presentation/screens/edit_profile_screen.dart';
import '../../features/resident/presentation/screens/incident_detail_screen.dart';
import '../../features/resident/presentation/screens/register_incident_screen.dart';
import '../../features/resident/presentation/screens/resident_shell_screen.dart';
import '../../features/technician/domain/entities/assigned_incident.dart';
import '../../features/technician/presentation/screens/register_solution_screen.dart';
import '../../features/technician/presentation/screens/technician_edit_profile_screen.dart';
import '../../features/technician/presentation/screens/technician_incident_detail_screen.dart';
import '../../features/technician/presentation/screens/technician_shell_screen.dart';
import 'route_names.dart';

abstract final class AppRouter {
  /// Rutas que no requieren sesión.
  static const _publicRoutes = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.forgotPassword,
  };

  /// Roles que pueden abrir cada ruta protegida.
  static const _allowedRoles = <String, Set<UserRole>>{
    RouteNames.residentShell: {UserRole.resident},
    RouteNames.registerIncident: {UserRole.resident},
    RouteNames.incidentDetail: {UserRole.resident},
    // HU-2.2: el residente modifica su nombre y su teléfono.
    RouteNames.editProfile: {UserRole.resident},
    RouteNames.technicianHome: {UserRole.technician},
    RouteNames.technicianEditProfile: {UserRole.technician},
    RouteNames.technicianIncidentDetail: {UserRole.technician},
    RouteNames.technicianRegisterSolution: {UserRole.technician},
    RouteNames.adminHome: {UserRole.admin},
    RouteNames.adminProfile: {UserRole.admin},
    RouteNames.adminEditProfile: {UserRole.admin},
    RouteNames.adminUsers: {UserRole.admin},
    RouteNames.adminResidents: {UserRole.admin},
    RouteNames.adminTechnicians: {UserRole.admin},
    RouteNames.adminHousings: {UserRole.admin},
    RouteNames.adminPendingIncidents: {UserRole.admin},
    RouteNames.adminIncidentHistory: {UserRole.admin},
    RouteNames.adminStatistics: {UserRole.admin},
    RouteNames.adminNotifications: {UserRole.admin},
    RouteNames.incidentChat: {UserRole.resident, UserRole.technician},
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final redirect = _redirectFor(settings.name);
    if (redirect != null) {
      return onGenerateRoute(RouteSettings(name: redirect));
    }

    switch (settings.name) {
      case RouteNames.splash:
        return _page(const SplashScreen(), settings);
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
      case RouteNames.technicianHome:
        return _page(const TechnicianShellScreen(), settings);
      case RouteNames.technicianEditProfile:
        return _page(const TechnicianEditProfileScreen(), settings);
      case RouteNames.technicianIncidentDetail:
        // Desde la lista llega la incidencia completa; desde un aviso,
        // solo su ID.
        final arguments = settings.arguments;
        return _page(
          arguments is AssignedIncident
              ? TechnicianIncidentDetailScreen(
                  incidentId: arguments.id,
                  initial: arguments,
                )
              : TechnicianIncidentDetailScreen(
                  incidentId: arguments! as String,
                ),
          settings,
        );
      case RouteNames.technicianRegisterSolution:
        return _page(
          RegisterSolutionScreen(item: settings.arguments! as AssignedIncident),
          settings,
        );
      case RouteNames.adminHome:
        return _page(const AdminHomeScreen(), settings);
      case RouteNames.adminProfile:
        return _page(const AdminProfileScreen(), settings);
      case RouteNames.adminEditProfile:
        return _page(const AdminEditProfileScreen(), settings);
      case RouteNames.adminUsers:
        return _page(const AdminUsersScreen(), settings);
      // Residentes y técnicos ahora están juntos en Usuarios.
      case RouteNames.adminResidents:
        return _page(
          const AdminUsersScreen(initialRole: ManagedRole.resident),
          settings,
        );
      case RouteNames.adminTechnicians:
        return _page(
          const AdminUsersScreen(initialRole: ManagedRole.technician),
          settings,
        );
      case RouteNames.adminHousings:
        return _page(const AdminHousingsScreen(), settings);
      case RouteNames.adminPendingIncidents:
        return _page(const AdminPendingIncidentsScreen(), settings);
      case RouteNames.adminIncidentHistory:
        return _page(const AdminIncidentHistoryScreen(), settings);
      case RouteNames.adminStatistics:
        return _page(const AdminStatisticsScreen(), settings);
      case RouteNames.adminNotifications:
        return _page(const AdminNotificationsScreen(), settings);
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

  /// Sin sesión se va al login; con un rol que no corresponde, a su propio
  /// inicio. Devuelve `null` si puede abrir la ruta.
  static String? _redirectFor(String? route) {
    if (_publicRoutes.contains(route)) return null;
    final allowed = _allowedRoles[route];
    if (allowed == null) return null;

    final user = AuthSession.instance.currentUser;
    if (user == null) return RouteNames.login;
    if (!allowed.contains(user.role)) return RouteNames.homeFor(user.role);
    return null;
  }

  static MaterialPageRoute<dynamic> _page(
    Widget screen,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}
