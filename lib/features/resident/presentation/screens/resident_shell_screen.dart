import 'package:flutter/material.dart';

import '../../../../shared/widgets/bars_visibility.dart';
import '../../../../shared/widgets/floating_bottom_bar.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../providers/resident_shell_view_model.dart';
import 'incident_history_screen.dart';
import 'profile_screen.dart';
import 'resident_home_screen.dart';

/// Contenedor principal del residente con barra de navegación flotante.
class ResidentShellScreen extends StatefulWidget {
  const ResidentShellScreen({super.key});

  @override
  State<ResidentShellScreen> createState() => _ResidentShellScreenState();
}

class _ResidentShellScreenState extends State<ResidentShellScreen> {
  static const _items = [
    FloatingBottomBarItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    FloatingBottomBarItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'Historial',
    ),
    FloatingBottomBarItem(
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
      label: 'Avisos',
    ),
    FloatingBottomBarItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  final _viewModel = ResidentShellViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final tab = _viewModel.currentTab;
        return Scaffold(
          extendBody: true,
          body: BarsVisibilityScope(
            visible: _viewModel.barsVisible,
            child: HideBarsOnScroll(
              onVisibilityChanged: _viewModel.setBarsVisible,
              child: IndexedStack(
                index: tab.index,
                children: [
                  ResidentHomeScreen(
                    onSeeHistory: () =>
                        _viewModel.selectTab(ResidentTab.history),
                  ),
                  const IncidentHistoryScreen(),
                  const NotificationsScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: FloatingBottomBar(
            items: _items,
            visible: _viewModel.barsVisible,
            selectedIndex: tab.index,
            onSelected: (index) =>
                _viewModel.selectTab(ResidentTab.values[index]),
          ),
        );
      },
    );
  }
}
