import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// Pantalla de inicio del administrador.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final name = user?.name;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: _AdminDrawer(name: name),
      appBar: FixoAppBar(
        title: 'Administrador',
        subtitle: name,
        leading: Builder(
          builder: (context) => FixoAppBarAction(
            icon: Icons.menu_rounded,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay reportes por el momento',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final displayName = name ?? user?.name ?? 'Administrador';
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
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
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteNames.adminProfile);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                signOutAndGoToLogin(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final letters = words.map((word) => word[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}
