import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-1.1.2 Estructura de datos para usuarios y credenciales.
void main() {
  group('UserModel.fromMap', () {
    test('PU-01 lee un residente con todos sus campos', () {
      final suspendedUntil = DateTime(2026, 11, 1);
      final user = UserModel.fromMap('uid-1', {
        'nombre': 'María López',
        'correo': 'maria@correo.com',
        'telefono': '7771112233',
        'rol': 'residente',
        'estadoCuenta': 'suspendida',
        'estadoConducta': 'medio',
        'reportesValidados': 2,
        'suspendidaHasta': Timestamp.fromDate(suspendedUntil),
        'viviendaId': 'vivienda-4b',
      });

      expect(user.uid, 'uid-1');
      expect(user.name, 'María López');
      expect(user.email, 'maria@correo.com');
      expect(user.role, UserRole.resident);
      expect(user.accountStatus, AccountStatus.suspended);
      expect(user.conductStatus, ConductStatus.medium);
      expect(user.validatedReports, 2);
      expect(user.suspendedUntil, suspendedUntil);
      expect(user.housingId, 'vivienda-4b');
    });

    test('PU-02 reconoce los tres roles del sistema', () {
      Map<String, dynamic> withRole(String role) => {
        'rol': role,
        'estadoCuenta': 'activa',
      };

      expect(UserModel.fromMap('a', withRole('admin')).role, UserRole.admin);
      expect(
        UserModel.fromMap('r', withRole('residente')).role,
        UserRole.resident,
      );
      expect(
        UserModel.fromMap('t', withRole('tecnico')).role,
        UserRole.technician,
      );
    });

    test('PU-03 rechaza un documento con rol no válido', () {
      expect(
        () => UserModel.fromMap('x', {
          'rol': 'Residente',
          'estadoCuenta': 'activa',
        }),
        throwsFormatException,
      );
    });

    test('PU-04 rechaza un documento sin estado de cuenta', () {
      expect(
        () => UserModel.fromMap('x', {'rol': 'admin'}),
        throwsFormatException,
      );
    });
  });

  group('UserModel.toFirestore', () {
    test('PU-05 no guarda contraseña ni campos de otros roles', () {
      const admin = UserModel(
        uid: 'a',
        name: 'Admin',
        email: 'admin@correo.com',
        phone: '7771234567',
        role: UserRole.admin,
        accountStatus: AccountStatus.active,
      );

      final data = admin.toFirestore();

      expect(data.keys, isNot(contains('contrasena')));
      expect(data.keys, isNot(contains('password')));
      expect(data.keys, isNot(contains('estadoConducta')));
      expect(data.keys, isNot(contains('viviendaId')));
      expect(data['rol'], 'admin');
      expect(data['estadoCuenta'], 'activa');
    });

    test('PU-06 un técnico nuevo inicia con conducta buena y disponible', () {
      const technician = UserModel(
        uid: 't',
        name: 'Juan',
        email: 'juan@correo.com',
        phone: '7774445566',
        role: UserRole.technician,
        accountStatus: AccountStatus.active,
        specialty: 'plomeria',
      );

      final data = technician.toFirestore();

      expect(data['estadoConducta'], 'bueno');
      expect(data['reportesValidados'], 0);
      expect(data['disponible'], true);
      expect(data['especialidad'], 'plomeria');
    });
  });
}
