import 'package:flutter_test/flutter_test.dart';

import 'package:fixo/app/app.dart';

void main() {
  testWidgets('Muestra la pantalla de login al iniciar', (tester) async {
    await tester.pumpWidget(const FixoApp());

    expect(find.text('FIXO'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
