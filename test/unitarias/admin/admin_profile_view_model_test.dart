import 'dart:async';

import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/admin/presentation/providers/admin_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';

/// HU-4.1 Consultar perfil del administrador.
void main() {
  late AuthSession session;
  late FakeHousingRepository housings;
  late AdminProfileViewModel viewModel;

  AppUser adminWith({
    String name = 'Carlos Admin Pérez',
    String email = 'admin@correo.com',
    String phone = '5551234567',
    String? housingId,
    AccountStatus status = AccountStatus.active,
    DateTime? createdAt,
  }) => AppUser(
    uid: 'uid-admin',
    name: name,
    email: email,
    phone: phone,
    role: UserRole.admin,
    accountStatus: status,
    housingId: housingId,
    createdAt: createdAt,
  );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    housings = FakeHousingRepository();
    viewModel = AdminProfileViewModel(session: session, housings: housings);
  });

  tearDown(() => viewModel.dispose());

  test(
    'PU-400 muestra los datos personales del administrador autenticado',
    () async {
      session.start(adminWith());
      await pumpEventQueue();

      expect(viewModel.name, 'Carlos Admin Pérez');
      expect(viewModel.email, 'admin@correo.com');
      expect(viewModel.phone, '5551234567');
    },
  );

  test('PU-401 las iniciales usan las dos primeras palabras del nombre', () {
    final cases = {
      'Carlos Admin Pérez': 'CA',
      '  ana   lopez ': 'AL',
      'Pedro': 'P',
      '': '?',
    };

    for (final MapEntry(key: name, value: initials) in cases.entries) {
      session.start(adminWith(name: name));
      expect(viewModel.initials, initials, reason: '"$name"');
    }
  });

  test('PU-402 los datos vacíos se muestran como "Sin registrar"', () {
    session.start(adminWith(phone: '   '));

    expect(viewModel.phone, 'Sin registrar');
    expect(viewModel.memberSince, 'Sin registrar');
  });

  test('PU-403 el estado de la cuenta se muestra en español', () {
    final cases = {
      AccountStatus.active: 'Activa',
      AccountStatus.suspended: 'Suspendida',
      AccountStatus.disabled: 'Deshabilitada',
      AccountStatus.removed: 'Dada de baja',
    };

    for (final MapEntry(key: status, value: text) in cases.entries) {
      session.start(adminWith(status: status));
      expect(viewModel.accountStatus, text);
      expect(viewModel.isAccountActive, status == AccountStatus.active);
    }
  });

  test('PU-404 la fecha de registro se muestra en español', () {
    session.start(adminWith(createdAt: DateTime(2026, 10, 27)));

    expect(viewModel.memberSince, '27 de octubre de 2026');
  });

  test('PU-405 sin sesión no se muestran datos de ningún usuario', () {
    expect(viewModel.name, 'Sin registrar');
    expect(viewModel.email, 'Sin registrar');
    expect(viewModel.initials, '?');
    expect(viewModel.isAccountActive, isFalse);
  });

  test(
    'PU-406 al cambiar o cerrar la sesión se actualizan los datos mostrados',
    () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      session.start(adminWith());
      session.start(adminWith(name: 'Luis Admin', email: 'luis@correo.com'));
      expect(viewModel.name, 'Luis Admin');
      expect(viewModel.email, 'luis@correo.com');

      await session.signOut();
      expect(viewModel.name, 'Sin registrar');
      expect(notifications, greaterThanOrEqualTo(2));
    },
  );

  group('Vivienda asignada', () {
    test('PU-407 muestra "Sin registrar" cuando el administrador no tiene vivienda', () async {
      session.start(adminWith(housingId: null));
      await pumpEventQueue();

      expect(viewModel.housing, 'Sin registrar');
    });

    test(
      'PU-408 muestra "Cargando…" mientras se consulta la vivienda',
      () async {
        housings.gate = Completer<void>();
        session.start(adminWith(housingId: 'vivienda-4b'));

        expect(viewModel.housing, 'Cargando…');

        housings.gate!.complete();
        await pumpEventQueue();
        expect(viewModel.housing, 'Torre A – 4B');
      },
    );

    test(
      'PU-409 si la vivienda no existe se muestra "No disponible"',
      () async {
        session.start(adminWith(housingId: 'vivienda-borrada'));
        await pumpEventQueue();

        expect(viewModel.housing, 'No disponible');
      },
    );

    test('PU-410 si falla la consulta se muestra "No disponible"', () async {
      final failing = FakeHousingRepository(error: StateError('sin red'));
      final vm = AdminProfileViewModel(session: session, housings: failing);
      addTearDown(vm.dispose);

      session.start(adminWith(housingId: 'vivienda-4b'));
      await pumpEventQueue();

      expect(vm.housing, 'No disponible');
    });
  });
}
