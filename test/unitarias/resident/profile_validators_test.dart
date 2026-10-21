import 'package:fixo/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-2.2.5 Validación de los campos del perfil.
void main() {
  test('PU-59 el nombre debe tener entre 3 y 80 caracteres y solo letras', () {
    final cases = {
      '': 'Ingresa tu nombre',
      '   ': 'Ingresa tu nombre',
      'Al': 'El nombre es demasiado corto',
      'A' * 81: 'El nombre no debe pasar de 80 caracteres',
      'María 123': 'El nombre solo puede tener letras',
      'Ana@Ruiz': 'El nombre solo puede tener letras',
      'María José Núñez': null,
      "Ana O'Connor-Ruiz": null,
    };

    for (final MapEntry(key: name, value: error) in cases.entries) {
      expect(Validators.name(name), error, reason: '"$name"');
    }
  });

  test('PU-60 el teléfono debe tener exactamente 10 dígitos', () {
    final cases = {
      '': 'Ingresa tu teléfono',
      '777111223': 'El teléfono debe tener 10 dígitos',
      '77711122334': 'El teléfono debe tener 10 dígitos',
      '777-111-22': 'El teléfono debe tener 10 dígitos',
      '7771112233': null,
      ' 7771112233 ': null,
    };

    for (final MapEntry(key: phone, value: error) in cases.entries) {
      expect(Validators.phone(phone), error, reason: '"$phone"');
    }
  });
}
