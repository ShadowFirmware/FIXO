import 'package:fixo/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-1.1.6 Mensajes de error en el formulario de inicio de sesión.
void main() {
  group('Validators.email', () {
    test('PU-30 correo vacío pide ingresar el correo', () {
      expect(Validators.email(''), 'Ingresa tu correo');
      expect(Validators.email('   '), 'Ingresa tu correo');
      expect(Validators.email(null), 'Ingresa tu correo');
    });

    test('PU-31 correo con formato incorrecto se rechaza', () {
      for (final email in ['maria', 'maria@', 'maria@correo', '@correo.com']) {
        expect(Validators.email(email), 'Correo no válido', reason: email);
      }
    });

    test('PU-32 correo válido no muestra error', () {
      expect(Validators.email('maria@correo.com'), isNull);
      expect(Validators.email('  20233tn111@utez.edu.mx  '), isNull);
    });
  });

  group('Validators.requiredPassword', () {
    test('PU-33 contraseña vacía pide ingresar la contraseña', () {
      expect(Validators.requiredPassword(''), 'Ingresa tu contraseña');
      expect(Validators.requiredPassword(null), 'Ingresa tu contraseña');
    });

    test('PU-34 contraseña escrita no muestra error', () {
      expect(Validators.requiredPassword('Password123'), isNull);
    });
  });
}
