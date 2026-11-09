import 'package:fixo/core/errors/housing_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/housing_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_housings_screen.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../housing/fakes.dart';

/// Viviendas en memoria que registra cada cambio y rechaza las repetidas.
class _RecordingHousingRepository extends FakeHousingRepository {
  _RecordingHousingRepository()
    : super(
        housings: {
          'vivienda-4b': torreA4B,
          'casa-12': const Housing(
            id: 'casa-12',
            type: HousingType.house,
            number: '12',
            active: false,
          ),
        },
      );

  final registered = <String>[];
  final updated = <String, String>{};
  final activeChanges = <String, bool>{};

  @override
  Future<Housing> register({
    required HousingType type,
    required String number,
    String? building,
  }) async {
    final key = Housing.identityKeyFor(building: building, number: number);
    if (housings.values.any((h) => h.identityKey == key)) {
      throw HousingFailure.duplicated;
    }
    final housing = Housing(
      id: 'vivienda-nueva',
      type: type,
      number: number.trim(),
      building: building?.trim().isEmpty ?? true ? null : building!.trim(),
    );
    housings[housing.id] = housing;
    registered.add(housing.label);
    return housing;
  }

  @override
  Future<void> update({
    required String id,
    required HousingType type,
    required String number,
    String? building,
  }) async {
    updated[id] = number;
  }

  @override
  Future<void> setActive({required String id, required bool active}) async {
    activeChanges[id] = active;
  }
}

/// HU-4.7 Gestionar lugares de residencia: ViewModel y pantalla.
void main() {
  late _RecordingHousingRepository repository;

  setUp(() => repository = _RecordingHousingRepository());

  HousingAdminViewModel housingViewModel() {
    final viewModel = HousingAdminViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('ViewModel', () {
    test('PU-585 valida el tipo y el número de la residencia', () {
      expect(
        HousingAdminViewModel.validate(type: null, number: '4B'),
        'Selecciona el tipo de residencia',
      );
      expect(
        HousingAdminViewModel.validate(
          type: HousingType.apartment,
          number: '  ',
        ),
        'Ingresa el número o identificador',
      );
      expect(
        HousingAdminViewModel.validateNumber('1' * 21),
        'El número no debe exceder 20 caracteres',
      );
      expect(
        HousingAdminViewModel.validate(type: HousingType.house, number: '12'),
        isNull,
      );
    });

    test('PU-586 registra, edita, activa y avisa si la residencia ya '
        'existe', () async {
      final vm = housingViewModel();
      await vm.load();
      expect(vm.housings, hasLength(2));

      expect(
        await vm.register(
          type: HousingType.apartment,
          number: '5C',
          building: 'Torre A',
        ),
        isTrue,
      );
      expect(repository.registered, ['Torre A – 5C']);
      expect(vm.successMessage, 'Residencia registrada correctamente.');
      expect(vm.housings, hasLength(3));

      expect(
        await vm.register(
          type: HousingType.apartment,
          number: '4b',
          building: 'torre a',
        ),
        isFalse,
      );
      expect(vm.errorMessage, HousingFailure.duplicated.message);

      expect(await vm.register(type: null, number: '9'), isFalse);
      expect(vm.errorMessage, 'Selecciona el tipo de residencia');

      await vm.update(
        torreA4B,
        type: HousingType.apartment,
        number: '4C',
        building: 'Torre A',
      );
      expect(repository.updated, {'vivienda-4b': '4C'});

      await vm.setActive(
        vm.housings.firstWhere((h) => !h.active),
        active: true,
      );
      expect(repository.activeChanges, {'casa-12': true});
      expect(vm.successMessage, 'Residencia activada correctamente.');
    });
  });

  group('pantalla', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      Size size = const Size(400, 900),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminHousingsScreen(viewModel: housingViewModel()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('PU-587 el formulario indica los datos que faltan y si la '
        'residencia ya existe', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Agregar residencia'));
      await tester.pumpAndSettle();

      // En el teléfono es una pantalla completa, no una ventana.
      expect(find.text('Registrar residencia'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      await tester.tap(find.byKey(const Key('housingForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
      expect(find.text('Selecciona el tipo de residencia'), findsOneWidget);
      expect(find.text('Ingresa el número o identificador'), findsOneWidget);

      await tester.tap(find.byKey(const Key('housingForm.type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Departamento').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('housingForm.building')),
        'Torre A',
      );
      await tester.enterText(find.byKey(const Key('housingForm.number')), '4B');
      await tester.tap(find.byKey(const Key('housingForm.save')));
      await tester.pumpAndSettle();
      expect(find.text(HousingFailure.duplicated.message), findsOneWidget);
      expect(find.text('Registrar residencia'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('housingForm.number')), '5C');
      await tester.tap(find.byKey(const Key('housingForm.save')));
      await tester.pumpAndSettle();
      expect(repository.registered, ['Torre A – 5C']);
      expect(find.text('Residencia registrada correctamente.'), findsOneWidget);
    });

    testWidgets('PU-588 al cancelar una edición con cambios pide '
        'confirmación', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar residencia'), findsOneWidget);
      expect(find.text('4B'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('housingForm.number')), '4C');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Deseas descartar los cambios realizados?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar residencia'), findsNothing);
      expect(repository.updated, isEmpty);
    });

    testWidgets('PU-589 en la web muestra la tabla y el detalle en una '
        'ventana', (tester) async {
      await pumpScreen(tester, size: const Size(1400, 900));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Agregar residencia'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Ver').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ver').first);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Ocupación'),
        ),
        findsOneWidget,
      );
    });
  });
}
