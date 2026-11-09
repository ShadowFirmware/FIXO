import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/admin_users_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/housing_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/resident_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/technician_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_housings_screen.dart';
import 'package:fixo/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:fixo/features/admin/presentation/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../housing/fakes.dart';
import 'admin_users_fakes.dart';

/// Navegación del administrador: el mismo menú en todas las secciones y,
/// en la web, una barra lateral fija.
void main() {
  const sections = [
    'Inicio',
    'Reportes pendientes',
    'Historial de incidencias',
    'Estadísticas',
    'Usuarios',
    'Residencias',
    'Ver perfil',
  ];

  Widget usersScreen() {
    final viewModel = AdminUsersViewModel(
      residents: ResidentAdminViewModel(
        repository: FakeResidentAdminRepository(),
      ),
      technicians: TechnicianAdminViewModel(
        repository: FakeTechnicianAdminRepository(),
      ),
    );
    addTearDown(viewModel.dispose);
    return AdminUsersScreen(viewModel: viewModel);
  }

  Widget housingsScreen() {
    final viewModel = HousingAdminViewModel(
      repository: FakeHousingRepository(),
    );
    addTearDown(viewModel.dispose);
    return AdminHousingsScreen(viewModel: viewModel);
  }

  Future<void> pump(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();
  }

  testWidgets('PU-591 en el teléfono todas las secciones muestran el mismo '
      'menú completo', (tester) async {
    for (final (screen, route) in [
      (usersScreen, RouteNames.adminUsers),
      (housingsScreen, RouteNames.adminHousings),
    ]) {
      await pump(tester, screen(), const Size(400, 900));
      await openMenu(tester);

      final drawer = find.byType(AdminDrawer);
      for (final section in sections) {
        expect(
          find.descendant(of: drawer, matching: find.text(section)),
          findsOneWidget,
          reason: '$section en $route',
        );
      }
      expect(
        find.descendant(of: drawer, matching: find.text('Cerrar sesión')),
        findsOneWidget,
      );
      // La sección abierta se marca en el menú.
      final current = tester.widget<ListTile>(
        find.byKey(Key('adminNav.$route')),
      );
      expect(current.selected, isTrue);
    }
  });

  testWidgets('PU-592 en la web las secciones están en una barra lateral '
      'fija', (tester) async {
    await pump(tester, usersScreen(), const Size(1400, 900));

    expect(find.byTooltip('Menú'), findsNothing);
    expect(find.byType(AdminNavigationPanel), findsOneWidget);
    for (final section in sections) {
      expect(find.text(section), findsWidgets);
    }
    final current = tester.widget<ListTile>(
      find.byKey(const Key('adminNav.${RouteNames.adminUsers}')),
    );
    expect(current.selected, isTrue);
  });
}
