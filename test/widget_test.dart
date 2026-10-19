import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixo/features/auth/presentation/screens/login_screen.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(home: LoginScreen()));

  testWidgets('Muestra el formulario de inicio de sesión', (tester) async {
    await pumpLogin(tester);

    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Muestra errores si se envía el formulario vacío', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Muestra error si el correo no tiene formato válido', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'maria');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Correo no válido'), findsOneWidget);
  });
}
