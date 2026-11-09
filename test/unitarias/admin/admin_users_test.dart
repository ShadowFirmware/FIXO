import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/admin_users_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/resident_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/technician_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_users_fakes.dart';

/// Sección Usuarios del administrador: residentes (HU-4.3) y técnicos
/// (HU-4.4) juntos, con su edición (HU-4.5) y baja (HU-4.6).
void main() {
  late FakeResidentAdminRepository residents;
  late FakeTechnicianAdminRepository technicians;

  setUp(() {
    residents = FakeResidentAdminRepository(
      residents: [residentUser('res-ana', 'Ana López')],
    );
    technicians = FakeTechnicianAdminRepository(
      technicians: [
        technicianUser('tec-juan', 'Juan Pérez'),
        technicianUser(
          'tec-beto',
          'Beto Ruiz',
          specialty: 'Plomería',
          status: AccountStatus.removed,
        ),
      ],
    );
  });

  AdminUsersViewModel usersViewModel({ManagedRole? initialRole}) {
    final viewModel = AdminUsersViewModel(
      residents: ResidentAdminViewModel(repository: residents),
      technicians: TechnicianAdminViewModel(repository: technicians),
      initialRole: initialRole,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('ViewModel', () {
    test('PU-574 reúne residentes y técnicos, y los filtra por rol y '
        'búsqueda', () async {
      final vm = usersViewModel();
      await vm.load();

      expect(vm.users.map((u) => u.name), [
        'Ana López',
        'Beto Ruiz',
        'Juan Pérez',
      ]);
      expect(vm.countOf(null), 3);
      expect(vm.countOf(ManagedRole.resident), 1);
      expect(vm.countOf(ManagedRole.technician), 2);

      vm.setRoleFilter(ManagedRole.technician);
      expect(vm.results.map((u) => u.name), ['Beto Ruiz', 'Juan Pérez']);
      vm.setQuery('juan');
      expect(vm.results.map((u) => u.name), ['Juan Pérez']);
      vm.setQuery('nadie');
      expect(vm.results, isEmpty);

      // Desde la ruta anterior de Técnicos se abre ya filtrado.
      expect(
        usersViewModel(initialRole: ManagedRole.technician).roleFilter,
        ManagedRole.technician,
      );
    });

    test('PU-575 registra cada rol con sus datos y avisa si el correo ya '
        'existe', () async {
      final vm = usersViewModel();
      await vm.load();

      expect(
        await vm.register(
          role: ManagedRole.resident,
          name: 'Carla Díaz',
          email: 'carla@correo.com',
          phone: '7770001122',
          password: 'Password123',
          housingId: 'viv-5c',
        ),
        isTrue,
      );
      expect(residents.registered.single['housingId'], 'viv-5c');
      expect(vm.message, 'Residente registrado correctamente.');

      expect(
        await vm.register(
          role: ManagedRole.technician,
          name: 'Diego Luna',
          email: 'diego@correo.com',
          phone: '7770003344',
          password: 'Password123',
          specialty: 'Plomería',
        ),
        isTrue,
      );
      expect(technicians.registered.single['specialty'], 'Plomería');
      expect(vm.users, hasLength(5));

      expect(
        await vm.register(
          role: ManagedRole.technician,
          name: 'Otro Técnico',
          email: takenEmail,
          phone: '7770005566',
          password: 'Password123',
          specialty: 'Plomería',
        ),
        isFalse,
      );
      expect(vm.message, duplicatedEmail.message);
    });

    test('PU-576 edita, da de baja y habilita según el rol', () async {
      final vm = usersViewModel();
      await vm.load();
      final ana = vm.users.first;
      final beto = vm.users[1];

      await vm.update(
        ana,
        name: 'Ana López',
        email: ana.email,
        phone: '7779998877',
        housingId: 'viv-5c',
      );
      expect(residents.updated.single['housingId'], 'viv-5c');

      await vm.remove(ana);
      expect(residents.removed, ['res-ana']);
      await vm.enable(beto);
      expect(technicians.enabled, ['tec-beto']);
      expect(vm.message, 'Técnico habilitado correctamente.');
    });
  });

  group('pantalla', () {
    Future<AdminUsersViewModel> pumpScreen(
      WidgetTester tester, {
      Size size = const Size(400, 900),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = usersViewModel();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUsersScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();
      return vm;
    }

    Future<void> openForm(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('users.add')));
      await tester.pumpAndSettle();
    }

    testWidgets('PU-577 en el teléfono lista a todos y el formulario se '
        'adapta al rol', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('Todos (3)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('users.role.resident')));
      await tester.pumpAndSettle();
      expect(find.text('Juan Pérez'), findsNothing);

      // En el teléfono el formulario es una pantalla completa.
      await openForm(tester);
      expect(find.text('Registrar usuario'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      expect(find.byKey(const Key('userForm.housing')), findsOneWidget);
      expect(find.byKey(const Key('userForm.specialty')), findsNothing);

      await tester.tap(find.text('Técnico'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('userForm.housing')), findsNothing);
      expect(find.byKey(const Key('userForm.specialty')), findsOneWidget);
    });

    testWidgets('PU-578 indica cada dato que falta o no es válido', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openForm(tester);

      await tester.tap(find.byKey(const Key('userForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(find.text('Ingresa tu teléfono'), findsOneWidget);
      expect(find.text('Ingresa una contraseña'), findsOneWidget);
      expect(find.text('Selecciona una vivienda'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('userForm.email')), 'ana@');
      await tester.enterText(find.byKey(const Key('userForm.phone')), '777');
      await tester.enterText(
        find.byKey(const Key('userForm.password')),
        '1234',
      );
      await tester.pumpAndSettle();
      expect(find.text('Correo no válido'), findsOneWidget);
      expect(find.text('El teléfono debe tener 10 dígitos'), findsOneWidget);
      expect(
        find.text('La contraseña debe tener al menos 8 caracteres'),
        findsOneWidget,
      );

      await tester.tap(find.text('Técnico'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa la especialidad'), findsOneWidget);
      expect(residents.registered, isEmpty);
      expect(technicians.registered, isEmpty);
    });

    testWidgets('PU-579 registra un técnico o avisa si el correo ya está '
        'registrado', (tester) async {
      await pumpScreen(tester);
      await openForm(tester);
      await tester.tap(find.text('Técnico'));
      await tester.pumpAndSettle();

      Future<void> fill(String email) async {
        await tester.enterText(
          find.byKey(const Key('userForm.name')),
          'Diego Luna',
        );
        await tester.enterText(find.byKey(const Key('userForm.email')), email);
        await tester.enterText(
          find.byKey(const Key('userForm.phone')),
          '7770003344',
        );
        await tester.enterText(
          find.byKey(const Key('userForm.password')),
          'Password123',
        );
        await tester.enterText(
          find.byKey(const Key('userForm.specialty')),
          'Plomería',
        );
        await tester.tap(find.byKey(const Key('userForm.save')));
        await tester.pumpAndSettle();
      }

      await fill(takenEmail);
      expect(find.text(duplicatedEmail.message), findsOneWidget);
      expect(find.text('Registrar usuario'), findsOneWidget);

      await fill('diego@correo.com');
      expect(technicians.registered.single['email'], 'diego@correo.com');
      expect(find.text('Registrar usuario'), findsNothing);
      expect(find.text('Técnico registrado correctamente.'), findsOneWidget);
      expect(find.text('Diego Luna'), findsOneWidget);
    });

    testWidgets('PU-580 en la web muestra una tabla y el formulario en una '
        'ventana', (tester) async {
      await pumpScreen(tester, size: const Size(1400, 900));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Agregar usuario'), findsOneWidget);
      expect(find.text('Plomería'), findsOneWidget);
      expect(find.text('Dada de baja'), findsOneWidget);

      await openForm(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Registrar usuario'), findsOneWidget);
    });

    testWidgets('PU-581 da de baja a un usuario después de confirmar', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('users.menu.tec-juan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar de baja'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ya no podrá iniciar sesión'), findsOneWidget);

      await tester.tap(find.byKey(const Key('users.confirmToggle')));
      await tester.pumpAndSettle();
      expect(technicians.removed, ['tec-juan']);
      expect(find.text('Técnico dado de baja correctamente.'), findsOneWidget);
    });

    testWidgets('PU-590 edita a un residente sin pedir rol ni contraseña y '
        'confirma antes de guardar', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('users.menu.res-ana')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar residente'), findsOneWidget);
      expect(find.byKey(const Key('userForm.role')), findsNothing);
      expect(find.byKey(const Key('userForm.password')), findsNothing);
      expect(find.text('Ana López'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('userForm.phone')),
        '7779998877',
      );
      await tester.tap(find.byKey(const Key('userForm.save')));
      await tester.pumpAndSettle();
      // Al editar se confirma antes de guardar.
      expect(
        find.text('¿Deseas guardar los cambios realizados?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('userForm.confirm')));
      await tester.pumpAndSettle();
      expect(residents.updated.single['phone'], '7779998877');
      expect(find.text('Residente actualizado correctamente.'), findsOneWidget);
    });

    testWidgets('PU-596 al cancelar una edición con cambios pide '
        'confirmación para descartarlos', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('users.menu.tec-juan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar técnico'), findsOneWidget);
      expect(find.text('Electricidad'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('userForm.specialty')),
        'Plomería',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Deseas descartar los cambios realizados?'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('userForm.confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Editar técnico'), findsNothing);
      expect(technicians.updated, isEmpty);
    });
  });
}
