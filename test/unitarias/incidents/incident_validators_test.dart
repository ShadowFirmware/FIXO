import 'package:fixo/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-2.3.5 Validación de los campos de la incidencia.
void main() {
  test('PU-75 el título es obligatorio y tiene de 5 a 80 caracteres', () {
    final cases = {
      '': 'Ingresa un título',
      '   ': 'Ingresa un título',
      'Fuga': 'El título debe tener al menos 5 caracteres',
      'A' * 81: 'El título no debe pasar de 80 caracteres',
      'Fuga en baño': null,
    };

    for (final MapEntry(key: title, value: error) in cases.entries) {
      expect(Validators.incidentTitle(title), error, reason: '"$title"');
    }
  });

  test('PU-76 la descripción es obligatoria y tiene de 10 a 500 '
      'caracteres', () {
    final cases = {
      '': 'Describe el problema',
      'Gotea': 'La descripción debe tener al menos 10 caracteres',
      'A' * 501: 'La descripción no debe pasar de 500 caracteres',
      'Gotea la llave del lavabo': null,
    };

    for (final MapEntry(key: text, value: error) in cases.entries) {
      expect(Validators.incidentDescription(text), error, reason: '"$text"');
    }
  });
}
