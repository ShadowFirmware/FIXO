import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Encabezado del perfil: avatar con iniciales, nombre, rol y correo.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
  });

  final String initials;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Anillo con degradado alrededor del avatar.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.orange],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.surfaceAlt,
              child: Text(
                initials,
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_work_outlined,
                size: 16,
                color: AppColors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Residente',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
