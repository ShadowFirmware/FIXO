import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Elemento de [FloatingBottomBar].
class FloatingBottomBarItem {
  const FloatingBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Etiqueta corta (idealmente una palabra de 6 a 9 letras).
  final String label;
}

/// Barra de navegación inferior flotante con indicador animado.
///
/// Usar junto con `Scaffold(extendBody: true)` para que el contenido se vea
/// detrás de la barra. Las pantallas con scroll deben dejar al final un
/// espacio de [FloatingBottomBar.reservedHeight].
class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double _barHeight = 68;
  static const double _margin = 16;
  static const double _innerPadding = 8;

  /// Cuántas veces más ancha es la pestaña activa que una inactiva.
  static const int _selectedFlex = 2;

  /// Espacio que ocupa la barra (sin contar el área segura del dispositivo).
  static const double reservedHeight = _barHeight + _margin * 2;

  final List<FloatingBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(_margin, 0, _margin, _margin),
      child: Container(
        height: _barHeight,
        padding: const EdgeInsets.symmetric(horizontal: _innerPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_barHeight / 2),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.16),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Se reparte el ancho en partes iguales; la pestaña activa ocupa
            // [_selectedFlex] partes, así su tamaño no depende del texto.
            final unit =
                constraints.maxWidth / (items.length - 1 + _selectedFlex);
            return Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  _FloatingBottomBarButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    width: i == selectedIndex ? unit * _selectedFlex : unit,
                    onTap: () {
                      if (i == selectedIndex) return;
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FloatingBottomBarButton extends StatelessWidget {
  const _FloatingBottomBarButton({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;
  static const double _gap = 2;

  final FloatingBottomBarItem item;
  final bool selected;

  /// Ancho total del espacio asignado, incluyendo la separación lateral.
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          width: width - _gap * 2,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: _gap),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.navy],
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  size: 24,
                  color: selected
                      ? AppColors.white
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: _duration,
                  curve: _curve,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
