import 'package:fixo/core/theme/app_colors.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/resident/presentation/providers/register_incident_view_model.dart';
import 'package:fixo/features/resident/presentation/screens/register_incident_screen.dart';
import 'package:fixo/shared/widgets/adaptive_form.dart';
import 'package:fixo/shared/widgets/chip_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';

/// Mejoras de la interfaz que comparten todas las secciones: filtros
/// legibles, formularios adaptados al dispositivo y avisos de datos que
/// faltan.
void main() {
  testWidgets('PU-593 el filtro sin seleccionar tiene texto e ícono negros y '
      'el seleccionado, blancos sobre el fondo azul', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              ChoiceChip(
                avatar: const ChipIcon(
                  Icons.water_drop_outlined,
                  selected: false,
                ),
                label: const Text('Agua'),
                selected: false,
                onSelected: (_) {},
              ),
              ChoiceChip(
                avatar: const ChipIcon(Icons.bolt_outlined, selected: true),
                label: const Text('Luz'),
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    int? textColor(String text) => tester
        .widget<RichText>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        )
        .text
        .style
        ?.color
        ?.toARGB32();
    int? iconColor(IconData icon) => tester
        .widget<RichText>(
          find.descendant(
            of: find.byIcon(icon),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color
        ?.toARGB32();

    expect(textColor('Agua'), AppColors.textPrimary.toARGB32());
    expect(
      iconColor(Icons.water_drop_outlined),
      AppColors.textPrimary.toARGB32(),
    );
    expect(textColor('Luz'), AppColors.white.toARGB32());
    expect(iconColor(Icons.bolt_outlined), AppColors.white.toARGB32());
  });

  group('formularios adaptables', () {
    Future<void> openForm(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAdaptiveForm<void>(
                  context: context,
                  title: 'Formulario de prueba',
                  builder: (_) => const AdaptiveFormLayout(
                    fields: [Text('Contenido')],
                    footer: Text('Botones'),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('PU-594 en el teléfono es una pantalla completa y en la web '
        'una ventana', (tester) async {
      await openForm(tester, const Size(400, 800));
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Formulario de prueba'), findsOneWidget);
      // Los botones quedan al final de la pantalla.
      expect(tester.getBottomLeft(find.text('Botones')).dy, greaterThan(700));
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Formulario de prueba'), findsNothing);

      await openForm(tester, const Size(1400, 900));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Contenido'), findsOneWidget);
    });
  });

  testWidgets('PU-595 al enviar un formulario incompleto se marcan los '
      'campos y se avisa', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.resident());
    final incidents = FakeIncidentRepository();
    final viewModel = RegisterIncidentViewModel(
      session: session,
      housings: FakeHousingRepository(),
      incidents: incidents,
      picker: FakeEvidencePicker(),
    );
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RegisterIncidentScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar incidencia'));
    await tester.pumpAndSettle();
    expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
    expect(find.text('Ingresa un título'), findsOneWidget);
    expect(find.text('Elige el tipo de incidencia'), findsOneWidget);
    expect(find.text('Describe el problema'), findsOneWidget);
    expect(incidents.received, isEmpty);
  });
}
