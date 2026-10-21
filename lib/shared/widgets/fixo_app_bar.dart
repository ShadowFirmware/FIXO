import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'bars_visibility.dart';

/// Barra superior flotante de FIXO: tarjeta con degradado azul, esquinas
/// redondeadas y círculos decorativos, separada de los bordes de la pantalla.
/// Hace juego con `FloatingBottomBar`.
///
/// El botón de regreso solo aparece cuando existe una pantalla anterior.
class FixoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FixoAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  static const Duration _hideDuration = Duration(milliseconds: 250);
  static const double _radius = 24;
  static const double _horizontalMargin = 16;
  static const double _verticalMargin = 8;

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  double get _barHeight => subtitle == null ? 64 : 76;

  @override
  Size get preferredSize => Size.fromHeight(_barHeight + _verticalMargin * 2);

  @override
  Widget build(BuildContext context) {
    final visible = BarsVisibilityScope.of(context);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final background =
        context.findAncestorWidgetOfExactType<Scaffold>()?.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;

    // La barra ya no cubre la barra de estado, así que sus íconos van oscuros
    // sobre el fondo claro de la pantalla.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedSlide(
                duration: _hideDuration,
                curve: Curves.easeOutCubic,
                offset: visible ? Offset.zero : const Offset(0, -1.3),
                child: AnimatedOpacity(
                  duration: _hideDuration,
                  opacity: visible ? 1 : 0,
                  child: _buildBar(context),
                ),
              ),
            ),
          ),
          // Franja detrás de la barra de estado: el contenido que pasa por
          // debajo no se mezcla con la hora y los íconos del sistema, y la
          // barra se esconde detrás de ella al ocultarse.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBarHeight,
            child: ColoredBox(color: background),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalMargin,
        vertical: _verticalMargin,
      ),
      child: Container(
        height: _barHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: _circle(110, AppColors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -36,
              right: 80,
              child: _circle(64, AppColors.white.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: EdgeInsets.only(left: canPop ? 10 : 20, right: 10),
              child: Row(
                children: [
                  if (canPop) ...[
                    FixoAppBarAction(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Regresar',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: 8),
                    action,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Botón cuadrado redondeado con fondo translúcido, para usar dentro de
/// [FixoAppBar] (regresar o acciones).
class FixoAppBarAction extends StatelessWidget {
  const FixoAppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
