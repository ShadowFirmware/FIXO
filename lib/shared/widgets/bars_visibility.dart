import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Indica a [FixoAppBar] y a las pantallas de una sección si las barras de
/// navegación deben mostrarse. Sin este widget, las barras siempre se ven.
class BarsVisibilityScope extends InheritedWidget {
  const BarsVisibilityScope({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BarsVisibilityScope>()
          ?.visible ??
      true;

  @override
  bool updateShouldNotify(BarsVisibilityScope oldWidget) =>
      visible != oldWidget.visible;
}

/// Escucha el scroll vertical de [child] y avisa cuándo ocultar las barras
/// (al desplazarse hacia abajo) y cuándo mostrarlas (hacia arriba o al
/// llegar al inicio).
class HideBarsOnScroll extends StatelessWidget {
  const HideBarsOnScroll({
    super.key,
    required this.onVisibilityChanged,
    required this.child,
  });

  final ValueChanged<bool> onVisibilityChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (notification.depth != 0 || metrics.axis != Axis.vertical) {
          return false;
        }

        if (notification is UserScrollNotification) {
          switch (notification.direction) {
            case ScrollDirection.reverse:
              onVisibilityChanged(false);
            case ScrollDirection.forward:
              onVisibilityChanged(true);
            case ScrollDirection.idle:
              break;
          }
        } else if (notification is ScrollUpdateNotification &&
            metrics.pixels <= metrics.minScrollExtent) {
          onVisibilityChanged(true);
        }
        return false;
      },
      child: child,
    );
  }
}
