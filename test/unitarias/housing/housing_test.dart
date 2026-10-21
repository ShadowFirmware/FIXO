import 'package:fixo/features/housing/data/models/housing_model.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-2.1 Mostrar la vivienda asignada con su nombre.
void main() {
  group('Housing.label', () {
    test('PU-43 con edificio se muestra "Edificio – Número"', () {
      const housing = Housing(
        id: 'v1',
        type: HousingType.apartment,
        building: 'Torre A',
        number: '4B',
      );

      expect(housing.label, 'Torre A – 4B');
    });

    test('PU-44 sin edificio se muestra el tipo y el número', () {
      const apartment = Housing(
        id: 'v1',
        type: HousingType.apartment,
        number: '4B',
      );
      const house = Housing(
        id: 'v2',
        type: HousingType.house,
        building: '  ',
        number: '12',
      );

      expect(apartment.label, 'Depto 4B');
      expect(house.label, 'Casa 12');
    });
  });

  group('HousingModel.fromMap', () {
    test('PU-45 lee todos los campos de una vivienda', () {
      final housing = HousingModel.fromMap('vivienda-4b', {
        'tipo': 'departamento',
        'edificio': 'Torre A',
        'numero': '4B',
        'activa': true,
        'residenteActivoId': 'uid-residente',
      });

      expect(housing.id, 'vivienda-4b');
      expect(housing.type, HousingType.apartment);
      expect(housing.building, 'Torre A');
      expect(housing.number, '4B');
      expect(housing.active, isTrue);
      expect(housing.residentId, 'uid-residente');
      expect(housing.label, 'Torre A – 4B');
    });

    test('PU-46 rechaza una vivienda con tipo no válido', () {
      expect(
        () =>
            HousingModel.fromMap('x', {'tipo': 'Departamento', 'numero': '1'}),
        throwsFormatException,
      );
    });
  });
}
