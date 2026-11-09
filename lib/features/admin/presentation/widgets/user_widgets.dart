import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/admin_users_view_model.dart';

/// Textos para mostrar los estados de la cuenta y de conducta.
extension AccountStatusLabel on AccountStatus {
  String get label => switch (this) {
    AccountStatus.active => 'Activa',
    AccountStatus.suspended => 'Suspendida',
    AccountStatus.disabled => 'Deshabilitada',
    AccountStatus.removed => 'Dada de baja',
  };

  Color get color => switch (this) {
    AccountStatus.active => AppColors.success,
    AccountStatus.suspended => AppColors.orange,
    AccountStatus.disabled || AccountStatus.removed => AppColors.error,
  };
}

extension ConductStatusLabel on ConductStatus {
  String get label => switch (this) {
    ConductStatus.good => 'Bueno',
    ConductStatus.medium => 'Medio',
    ConductStatus.bad => 'Malo',
  };
}

extension ManagedRoleStyle on ManagedRole {
  IconData get icon => switch (this) {
    ManagedRole.resident => Icons.home_outlined,
    ManagedRole.technician => Icons.build_outlined,
  };
}

/// Etiqueta pequeña de color, por ejemplo el rol o el estado de la cuenta.
class UserTag extends StatelessWidget {
  const UserTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Datos de un residente o técnico, para el detalle.
class UserDetails extends StatelessWidget {
  const UserDetails({super.key, required this.user, required this.housing});

  final AppUser user;

  /// Vivienda del residente ya con formato.
  final String housing;

  @override
  Widget build(BuildContext context) {
    final role = ManagedRole.of(user);
    final rows = <(IconData, String, String)>[
      (Icons.badge_outlined, 'Rol', role?.label ?? 'Administrador'),
      (Icons.email_outlined, 'Correo electrónico', user.email),
      (Icons.phone_outlined, 'Teléfono', user.phone),
      if (role == ManagedRole.resident)
        (Icons.apartment_rounded, 'Vivienda', housing),
      if (role == ManagedRole.technician) ...[
        (
          Icons.handyman_outlined,
          'Especialidad',
          user.specialty?.trim().isNotEmpty ?? false
              ? user.specialty!
              : 'Sin registrar',
        ),
        (
          Icons.event_available_outlined,
          'Disponibilidad',
          user.available == true ? 'Disponible' : 'No disponible',
        ),
      ],
      (Icons.verified_user_outlined, 'Cuenta', user.accountStatus.label),
      (
        Icons.thumbs_up_down_outlined,
        'Conducta',
        user.conductStatus?.label ?? 'Sin registrar',
      ),
    ];
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initialsOf(user.name),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                user.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final (icon, label, value) in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: AppColors.primary),
            title: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            subtitle: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Iniciales para el avatar, por ejemplo "LP" para "Luis Pablo".
String initialsOf(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  final letters = words.map((word) => word[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
