import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/features/admin/presentation/providers/register_resident_view_model.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';

/// HU-4.3 Registrar residente.
void main() {
  late FakeAuthRemoteDataSource auth;
  late FakeHousingRepository housings;
  late RegisterResidentViewModel viewModel;

  setUp(() {
    auth = FakeAuthRemoteDataSource();
    housings = FakeHousingRepository();
    viewModel = RegisterResidentViewModel(auth: auth, housings: housings);
  });

  tearDown(() => viewModel.dispose());

  test('PU-500 carga viviendas activas y disponibles', () async {
    await pumpEventQueue();
    expect(viewModel.housings.length, 1);
    expect(viewModel.housings.first.id, 'vivienda-5a');
  });

  test('PU-501 no hay cambios en campos inicialmente', () {
    viewModel.edit(name: '', email: '', phone: '', password: '');
    expect(viewModel.isSaving, isFalse);
  });

  test('PU-502 no registra con nombre inválido', () async {
    await pumpEventQueue();
    viewModel.edit(name: 'Ab', email: 'test@correo.com', phone: '5551234567', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('PU-503 no registra con correo inválido', () async {
    await pumpEventQueue();
    viewModel.edit(name: 'Juan Perez', email: 'correo-invalido', phone: '5551234567', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('PU-504 no registra con teléfono inválido', () async {
    await pumpEventQueue();
    viewModel.edit(name: 'Juan Perez', email: 'test@correo.com', phone: '123', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('PU-505 no registra con contraseña menor a 8 caracteres', () async {
    await pumpEventQueue();
    viewModel.edit(name: 'Juan Perez', email: 'test@correo.com', phone: '5551234567', password: 'pass123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('PU-506 no registra sin vivienda seleccionada', () async {
    await pumpEventQueue();
    viewModel.edit(name: 'Juan Perez', email: 'test@correo.com', phone: '5551234567', password: 'Password123');
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, 'Selecciona una vivienda');
  });

  test('PU-507 no registra con vivienda ya ocupada', () async {
    final h = Housing(
      id: 'vivienda-ocupada',
      type: HousingType.apartment,
      building: 'Torre B',
      number: '1A',
      active: true,
      residentId: 'otro-uid',
    );
    housings = FakeHousingRepository(housings: {'vivienda-ocupada': h});
    viewModel.dispose();
    viewModel = RegisterResidentViewModel(auth: auth, housings: housings);
    await pumpEventQueue();

    viewModel.edit(name: 'Juan Perez', email: 'test@correo.com', phone: '5551234567', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, contains('no está disponible'));
  });

  test('PU-508 registra residente correctamente', () async {
    await pumpEventQueue();
    viewModel.edit(name: '  Juan   Carlos  ', email: 'nuevo@correo.com', phone: '5559876543', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isTrue);
    expect(viewModel.success, isTrue);
    expect(housings.assignCalls.length, 1);
    expect(housings.assignCalls.first.housingId, 'vivienda-5a');
  });

  test('PU-509 muestra error si correo ya existe', () async {
    await pumpEventQueue();
    auth = FakeAuthRemoteDataSource(signInError: Exception('email-already-in-use'));
    viewModel.dispose();
    viewModel = RegisterResidentViewModel(auth: auth, housings: housings);
    
    viewModel.edit(name: 'Juan Perez', email: 'existente@correo.com', phone: '5551234567', password: 'Password123');
    viewModel.setHousing(viewModel.housings.first);
    final ok = await viewModel.register();

    expect(ok, isFalse);
    expect(viewModel.errorMessage, AuthFailure.emailAlreadyInUse.message);
  });
}
