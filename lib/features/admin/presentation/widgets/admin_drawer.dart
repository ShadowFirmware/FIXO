import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// Menú de hamburguesa del administrador en el teléfono. [currentRoute]
/// marca la opción de la pantalla abierta; al tocarla solo se cierra.
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: AdminNavigationPanel(currentRoute: currentRoute, inDrawer: true),
      ),
    );
  }
}

/// Datos del administrador, secciones y Cerrar sesión. Se usa dentro del
/// menú de hamburguesa (teléfono) y como barra lateral fija (web).
class AdminNavigationPanel extends StatelessWidget {
  const AdminNavigationPanel({
    super.key,
    required this.currentRoute,
    this.inDrawer = false,
  });

  final String? currentRoute;

  /// Dentro del menú de hamburguesa, que se cierra al elegir una opción.
  final bool inDrawer;

  void _open(BuildContext context, String route) {
    if (inDrawer) Navigator.pop(context);
    if (route == currentRoute) return;
    // Cada sección se abre sobre Inicio, sin apilar las anteriores: el botón
    // Atrás siempre regresa a Inicio.
    if (route == RouteNames.adminHome) {
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final displayName = user?.name ?? 'Administrador';
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials(displayName),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Administrador',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Las secciones se desplazan si no caben; Cerrar sesión queda fijo.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final section in AdminSection.all)
                ListTile(
                  key: Key('adminNav.${section.route}'),
                  leading: Icon(section.icon),
                  title: Text(section.label),
                  selected: currentRoute == section.route,
                  selectedColor: AppColors.primary,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  onTap: () => _open(context, section.route),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: AppColors.error),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(color: AppColors.error),
          ),
          onTap: () {
            if (inDrawer) Navigator.pop(context);
            signOutAndGoToLogin(context);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final letters = words.map((word) => word[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

/// Sección del panel del administrador, con su ícono y su ruta.
class AdminSection {
  const AdminSection(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;

  /// Todas las secciones, en el orden en que aparecen en el menú.
  static const all = [
    AdminSection(Icons.home_outlined, 'Inicio', RouteNames.adminHome),
    AdminSection(
      Icons.assignment_outlined,
      'Reportes pendientes',
      RouteNames.adminPendingIncidents,
    ),
    AdminSection(
      Icons.history_rounded,
      'Historial de incidencias',
      RouteNames.adminIncidentHistory,
    ),
    AdminSection(
      Icons.bar_chart_rounded,
      'Estadísticas',
      RouteNames.adminStatistics,
    ),
    AdminSection(Icons.group_outlined, 'Usuarios', RouteNames.adminUsers),
    AdminSection(
      Icons.apartment_outlined,
      'Residencias',
      RouteNames.adminHousings,
    ),
    AdminSection(
      Icons.person_outline_rounded,
      'Ver perfil',
      RouteNames.adminProfile,
    ),
  ];
}
