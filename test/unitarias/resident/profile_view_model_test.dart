import 'dart:async';

import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:fixo/features/resident/presentation/providers/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';

/// HU-2.1 Consultar perfil.
void main() {
  late AuthSession session;
  late FakeHousingRepository housings;
  late ProfileViewModel viewModel;

  AppUser residentWith({
    String name = 'María López Hernández',
    String email = 'maria@correo.com',
    String phone = '7771112233',
    String? housingId = 'vivienda-4b',
    AccountStatus status = AccountStatus.active,
    DateTime? createdAt,
  }) => AppUser(
    uid: 'uid-residente',
    name: name,
    email: email,
    phone: phone,
    role: UserRole.resident,
    accountStatus: status,
    housingId: housingId,
    createdAt: createdAt,
  );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    housings = FakeHousingRepository();
    viewModel = ProfileViewModel(session: session, housings: housings);
  });

  tearDown(() => viewModel.dispose());

  test('PU-36 muestra los datos personales y la vivienda del residente '
      'autenticado', () async {
    session.start(residentWith());
    await pumpEventQueue();

    expect(viewModel.name, 'María López Hernández');
    expect(viewModel.email, 'maria@correo.com');
    expect(viewModel.phone, '7771112233');
    expect(viewModel.housing, 'Torre A – 4B');
  });

  test('PU-37 las iniciales usan las dos primeras palabras del nombre', () {
    final cases = {
      'María López Hernández': 'ML',
      '  ana   ruiz ': 'AR',
      'Pedro': 'P',
      '': '?',
    };

    for (final MapEntry(key: name, value: initials) in cases.entries) {
      session.start(residentWith(name: name));
      expect(viewModel.initials, initials, reason: '"$name"');
    }
  });

  test('PU-38 los datos vacíos se muestran como "Sin registrar"', () {
    session.start(residentWith(phone: '   ', housingId: null));

    expect(viewModel.phone, 'Sin registrar');
    expect(viewModel.housing, 'Sin registrar');
    expect(viewModel.memberSince, 'Sin registrar');
  });

  test('PU-39 el estado de la cuenta se muestra en español', () {
    final cases = {
      AccountStatus.active: 'Activa',
      AccountStatus.suspended: 'Suspendida',
      AccountStatus.disabled: 'Deshabilitada',
      AccountStatus.removed: 'Dada de baja',
    };

    for (final MapEntry(key: status, value: text) in cases.entries) {
      session.start(residentWith(status: status));
      expect(viewModel.accountStatus, text);
      expect(viewModel.isAccountActive, status == AccountStatus.active);
    }
  });

  test('PU-40 la fecha de registro se muestra en español', () {
    session.start(residentWith(createdAt: DateTime(2026, 10, 9)));

    expect(viewModel.memberSince, '9 de octubre de 2026');
  });

  test('PU-41 sin sesión no se muestran datos de ningún usuario', () {
    expect(viewModel.name, 'Sin registrar');
    expect(viewModel.email, 'Sin registrar');
    expect(viewModel.initials, '?');
    expect(viewModel.isAccountActive, isFalse);
  });

  test(
    'PU-42 al cambiar o cerrar la sesión se actualizan los datos mostrados',
    () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      session.start(residentWith());
      session.start(residentWith(name: 'Luis Gómez', email: 'luis@correo.com'));
      expect(viewModel.name, 'Luis Gómez');
      expect(viewModel.email, 'luis@correo.com');

      await session.signOut();
      expect(viewModel.name, 'Sin registrar');
      // Además de los 3 cambios de sesión, puede avisar al cargar la vivienda.
      expect(notifications, greaterThanOrEqualTo(3));
    },
  );

  group('Vivienda asignada', () {
    test(
      'PU-47 muestra "Cargando…" mientras se consulta la vivienda',
      () async {
        housings.gate = Completer<void>();
        session.start(residentWith());

        expect(viewModel.housing, 'Cargando…');

        housings.gate!.complete();
        await pumpEventQueue();
        expect(viewModel.housing, 'Torre A – 4B');
      },
    );

    test('PU-48 si la vivienda no existe se muestra "No disponible"', () async {
      session.start(residentWith(housingId: 'vivienda-borrada'));
      await pumpEventQueue();

      expect(viewModel.housing, 'No disponible');
    });

    test('PU-49 si falla la consulta se muestra "No disponible"', () async {
      final failing = FakeHousingRepository(error: StateError('sin red'));
      final vm = ProfileViewModel(session: session, housings: failing);
      addTearDown(vm.dispose);

      session.start(residentWith());
      await pumpEventQueue();

      expect(vm.housing, 'No disponible');
    });

    test(
      'PU-50 al cambiar de residente se consulta su nueva vivienda',
      () async {
        final otherHousings = FakeHousingRepository(
          housings: const {
            'vivienda-4b': torreA4B,
            'casa-12': Housing(
              id: 'casa-12',
              type: HousingType.house,
              number: '12',
            ),
          },
        );
        final vm = ProfileViewModel(session: session, housings: otherHousings);
        addTearDown(vm.dispose);

        session.start(residentWith());
        await pumpEventQueue();
        session.start(residentWith(housingId: 'casa-12'));
        await pumpEventQueue();

        expect(vm.housing, 'Casa 12');
        expect(otherHousings.requestedIds, ['vivienda-4b', 'casa-12']);
      },
    );

    test('PU-51 una respuesta tardía de otra sesión no se muestra', () async {
      housings.gate = Completer<void>();
      session.start(residentWith());
      await session.signOut();

      housings.gate!.complete();
      await pumpEventQueue();

      expect(viewModel.housing, 'Sin registrar');
    });
  });
}
