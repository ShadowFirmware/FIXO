import 'package:flutter/material.dart';

import '../../../../shared/widgets/bars_visibility.dart';
import '../../../../shared/widgets/floating_bottom_bar.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../providers/technician_shell_view_model.dart';
import 'technician_history_screen.dart';
import 'technician_home_screen.dart';
import 'technician_profile_screen.dart';

/// Contenedor principal del técnico con barra de navegación flotante.
class TechnicianShellScreen extends StatefulWidget {
  const TechnicianShellScreen({super.key});

  @override
  State<TechnicianShellScreen> createState() => _TechnicianShellScreenState();
}

class _TechnicianShellScreenState extends State<TechnicianShellScreen> {
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

  final _viewModel = TechnicianShellViewModel();

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
                children: const [
                  TechnicianHomeScreen(),
                  TechnicianHistoryScreen(),
                  NotificationsScreen(),
                  TechnicianProfileScreen(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: FloatingBottomBar(
            items: _items,
            visible: _viewModel.barsVisible,
            selectedIndex: tab.index,
            onSelected: (index) =>
                _viewModel.selectTab(TechnicianTab.values[index]),
          ),
        );
      },
    );
  }
}

