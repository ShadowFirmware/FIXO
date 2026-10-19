import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-1.1.5 Redirigir al usuario según su rol.
void main() {
  test('PU-33 el residente va a la pantalla del residente', () {
    expect(RouteNames.homeFor(UserRole.resident), RouteNames.residentShell);
  });

  test('PU-34 el técnico va a la pantalla del técnico', () {
    expect(RouteNames.homeFor(UserRole.technician), RouteNames.technicianHome);
  });

  test('PU-35 el administrador va a la pantalla del administrador', () {
    expect(RouteNames.homeFor(UserRole.admin), RouteNames.adminHome);
  });
}
