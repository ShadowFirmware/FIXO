import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/resident/presentation/providers/edit_profile_view_model.dart';
import 'package:fixo/features/resident/presentation/providers/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import 'fakes.dart';

/// HU-2.2 Modificar perfil.
void main() {
  late AuthSession session;
  late FakeProfileRepository profiles;

  EditProfileViewModel createViewModel({
    FakeHousingRepository? housings,
    FakeProfileRepository? repository,
  }) {
    final vm = EditProfileViewModel(
      session: session,
      housings: housings ?? FakeHousingRepository(),
      profiles: repository ?? profiles,
    );
    addTearDown(vm.dispose);
    return vm;
  }

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.resident());
    profiles = FakeProfileRepository();
  });

  test('PU-52 el formulario se llena con los datos actuales del '
      'residente', () async {
    final vm = createViewModel();
    await pumpEventQueue();

    expect(vm.initialName, 'María López Hernández');
    expect(vm.initialPhone, '7771112233');
    expect(vm.email, 'maria@correo.com');
    expect(vm.housing, 'Torre A – 4B');
  });

  test('PU-53 la vivienda se muestra aunque no se pueda consultar', () async {
    final failing = createViewModel(
      housings: FakeHousingRepository(error: StateError('sin red')),
    );
    await pumpEventQueue();

    expect(failing.housing, 'No disponible');
  });

  test('PU-54 solo hay cambios si el nombre o el teléfono son '
      'distintos', () {
    final vm = createViewModel();

    vm.edit(name: '  María López Hernández ', phone: '7771112233');
    expect(vm.hasChanges, isFalse);

    vm.edit(name: 'María López', phone: '7771112233');
    expect(vm.hasChanges, isTrue);

    vm.edit(name: 'María López Hernández', phone: '7779998877');
    expect(vm.hasChanges, isTrue);
  });

  test('PU-55 con datos inválidos informa el error y no guarda', () async {
    final vm = createViewModel();

    vm.edit(name: 'María', phone: '777');
    expect(await vm.save(), isFalse);
    expect(vm.errorMessage, 'El teléfono debe tener 10 dígitos');

    vm.edit(name: 'M4ría', phone: '7779998877');
    expect(await vm.save(), isFalse);
    expect(vm.errorMessage, 'El nombre solo puede tener letras');

    expect(profiles.saved, isEmpty);
    expect(session.currentUser!.phone, '7771112233');
  });

  test('PU-56 al guardar se actualiza el perfil mostrado', () async {
    final vm = createViewModel();
    final profile = ProfileViewModel(
      session: session,
      housings: FakeHousingRepository(),
    );
    addTearDown(profile.dispose);

    vm.edit(name: '  María   López ', phone: ' 7779998877 ');
    final saved = await vm.save();

    expect(saved, isTrue);
    expect(profiles.saved.single, (
      uid: 'uid-residente',
      name: 'María López',
      phone: '7779998877',
    ));
    expect(profile.name, 'María López');
    expect(profile.phone, '7779998877');
    // Lo que no se edita se conserva.
    expect(session.currentUser!.housingId, 'vivienda-4b');
    expect(vm.hasChanges, isFalse);
  });

  test('PU-57 si falla el guardado se informa y no cambia el perfil', () async {
    final vm = createViewModel(
      repository: FakeProfileRepository(error: ProfileFailure.network),
    );

    vm.edit(name: 'María López', phone: '7779998877');

    expect(await vm.save(), isFalse);
    expect(vm.errorMessage, ProfileFailure.network.message);
    expect(vm.isSaving, isFalse);
    expect(session.currentUser!.name, 'María López Hernández');
  });
}
