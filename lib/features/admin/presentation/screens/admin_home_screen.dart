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
    final name = AuthSession.instance.currentUser?.name;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: FixoAppBar(
        title: 'Administrador',
        subtitle: name,
        actions: [_AdminMenuButton(name: name)],
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

class _AdminMenuButton extends StatelessWidget {
  const _AdminMenuButton({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdminMenuAction>(
      tooltip: 'Menú',
      icon: const Icon(Icons.menu_rounded, color: AppColors.white),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 56),
      onSelected: (action) {
        switch (action) {
          case _AdminMenuAction.profile:
            Navigator.pushNamed(context, RouteNames.adminProfile);
            break;
          case _AdminMenuAction.logout:
            signOutAndGoToLogin(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_AdminMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name ?? 'Administrador',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Administrador',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_AdminMenuAction>(
          value: _AdminMenuAction.profile,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded),
              SizedBox(width: 12),
              Text('Ver perfil'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_AdminMenuAction>(
          value: _AdminMenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error),
              SizedBox(width: 12),
              Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AdminMenuAction { profile, logout }
