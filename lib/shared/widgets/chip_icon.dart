import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ícono de un filtro: negro sobre el fondo claro y blanco sobre el fondo
/// azul cuando el filtro está seleccionado. El chip no cambia solo el color
/// de su ícono, por eso se indica aquí.
class ChipIcon extends StatelessWidget {
  const ChipIcon(this.icon, {super.key, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 18,
      color: selected ? AppColors.white : AppColors.textPrimary,
    );
  }
}
