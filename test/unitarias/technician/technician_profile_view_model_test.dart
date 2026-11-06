import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/technician/presentation/providers/technician_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';

/// HU-3.1 Consultar perfil del técnico.
void main() {
  late AuthSession session;
  late TechnicianProfileViewModel viewModel;

  AppUser technicianWith({
    String name = 'Jorge Ramírez Soto',
    String email = 'jorge@correo.com',
    String phone = '7774445566',
    String? specialty = 'Luz',
    AccountStatus status = AccountStatus.active,
    DateTime? createdAt,
  }) => AppUser(
    uid: 'uid-tecnico',
    name: name,
    email: email,
    phone: phone,
    role: UserRole.technician,
    accountStatus: status,
    specialty: specialty,
    createdAt: createdAt,
  );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    viewModel = TechnicianProfileViewModel(session: session);
  });

  tearDown(() => viewModel.dispose());

  test('PU-491 muestra los datos del técnico autenticado', () {
    session.start(technicianWith());

    expect(viewModel.name, 'Jorge Ramírez Soto');
    expect(viewModel.email, 'jorge@correo.com');
    expect(viewModel.phone, '7774445566');
    expect(viewModel.specialty, 'Luz');
  });

  test('PU-492 las iniciales usan las dos primeras palabras del nombre', () {
    final cases = {
      'Jorge Ramírez Soto': 'JR',
      '  ana   ruiz ': 'AR',
      'Pedro': 'P',
      '': '?',
    };

    for (final MapEntry(key: name, value: initials) in cases.entries) {
      session.start(technicianWith(name: name));
      expect(viewModel.initials, initials, reason: '"$name"');
    }
  });

  test('PU-493 los datos vacíos se muestran como "Sin registrar"', () {
    session.start(technicianWith(phone: '   ', specialty: null));

    expect(viewModel.phone, 'Sin registrar');
    expect(viewModel.specialty, 'Sin registrar');
    expect(viewModel.memberSince, 'Sin registrar');
  });

  test('PU-494 el estado de la cuenta se muestra en español', () {
    final cases = {
      AccountStatus.active: 'Activa',
      AccountStatus.suspended: 'Suspendida',
      AccountStatus.disabled: 'Deshabilitada',
      AccountStatus.removed: 'Dada de baja',
    };

    for (final MapEntry(key: status, value: label) in cases.entries) {
      session.start(technicianWith(status: status));
      expect(viewModel.accountStatus, label);
      expect(viewModel.isAccountActive, status == AccountStatus.active);
    }
  });

  test('PU-495 la fecha de registro se muestra en español', () {
    session.start(technicianWith(createdAt: DateTime(2026, 10, 27)));

    expect(viewModel.memberSince, '27 de octubre de 2026');
  });

  test('PU-496 sin sesión no se muestran datos de ningún usuario', () {
    expect(viewModel.name, 'Sin registrar');
    expect(viewModel.email, 'Sin registrar');
    expect(viewModel.specialty, 'Sin registrar');
    expect(viewModel.initials, '?');
    expect(viewModel.isAccountActive, isFalse);
  });

  test(
    'PU-497 al cambiar o cerrar la sesión se actualizan los datos',
    () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      session.start(technicianWith());
      session.start(technicianWith(name: 'Luis Ruiz', specialty: 'Agua'));

      expect(viewModel.name, 'Luis Ruiz');
      expect(viewModel.specialty, 'Agua');
      expect(notifications, 2);

      await session.signOut();

      expect(viewModel.name, 'Sin registrar');
      expect(notifications, 3);
    },
  );
}
