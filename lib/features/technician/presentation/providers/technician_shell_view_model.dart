import 'package:flutter/foundation.dart';

/// Pestañas de la barra de navegación del técnico.
enum TechnicianTab { home, history, notifications, profile }

/// ViewModel del contenedor principal del técnico: controla qué pestaña está
/// seleccionada y si las barras de navegación se muestran.
class TechnicianShellViewModel extends ChangeNotifier {
  TechnicianTab _currentTab = TechnicianTab.home;
  bool _barsVisible = true;

  TechnicianTab get currentTab => _currentTab;

  /// Las barras se ocultan al desplazarse hacia abajo en una pantalla con
  /// scroll y reaparecen al desplazarse hacia arriba.
  bool get barsVisible => _barsVisible;

  void selectTab(TechnicianTab tab) {
    if (tab == _currentTab) return;
    _currentTab = tab;
    // Al cambiar de pestaña las barras siempre vuelven a mostrarse.
    _barsVisible = true;
    notifyListeners();
  }

  void setBarsVisible(bool visible) {
    if (visible == _barsVisible) return;
    _barsVisible = visible;
    notifyListeners();
  }
}
