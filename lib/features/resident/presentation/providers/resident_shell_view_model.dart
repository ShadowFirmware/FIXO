import 'package:flutter/foundation.dart';

/// Pestañas de la barra de navegación del residente.
enum ResidentTab { home, history, notifications, profile }

/// ViewModel del contenedor principal del residente: controla qué pestaña
/// está seleccionada.
class ResidentShellViewModel extends ChangeNotifier {
  ResidentTab _currentTab = ResidentTab.home;

  ResidentTab get currentTab => _currentTab;

  void selectTab(ResidentTab tab) {
    if (tab == _currentTab) return;
    _currentTab = tab;
    notifyListeners();
  }
}
