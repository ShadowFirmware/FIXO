import '../../features/auth/domain/entities/app_user.dart';

abstract final class RouteNames {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Residente
  static const String residentShell = '/resident';
  static const String registerIncident = '/resident/incidents/new';
  static const String incidentDetail = '/resident/incidents/detail';
  static const String editProfile = '/resident/profile/edit';

  // Técnico
  static const String technicianHome = '/technician';

  // Administrador
  static const String adminHome = '/admin';
  static const String adminProfile = '/admin/profile';
  static const String adminEditProfile = '/admin/profile/edit';
  static const String registerResident = '/admin/residents/new';

  // Comunicación
  static const String incidentChat = '/incidents/chat';

  /// Pantalla principal que corresponde a cada rol (HU-1.1).
  static String homeFor(UserRole role) => switch (role) {
    UserRole.resident => residentShell,
    UserRole.technician => technicianHome,
    UserRole.admin => adminHome,
  };
}
