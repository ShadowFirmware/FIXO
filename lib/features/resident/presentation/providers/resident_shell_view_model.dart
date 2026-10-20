import 'package:flutter/foundation.dart';

/// Pestañas de la barra de navegación del residente.
enum ResidentTab { home, history, notifications, profile }

/// ViewModel del contenedor principal del residente: controla qué pestaña
/// está seleccionada y si las barras de navegación se muestran.
class ResidentShellViewModel extends ChangeNotifier {
  ResidentTab _currentTab = ResidentTab.home;
  bool _barsVisible = true;

  ResidentTab get currentTab => _currentTab;

  /// Las barras se ocultan al desplazarse hacia abajo en una pantalla con
  /// scroll y reaparecen al desplazarse hacia arriba.
  bool get barsVisible => _barsVisible;

  void selectTab(ResidentTab tab) {
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
