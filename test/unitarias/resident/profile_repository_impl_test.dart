import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/resident/data/datasources/profile_remote_data_source.dart';
import 'package:fixo/features/resident/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';

/// Datasource que siempre falla con el error indicado.
class _FailingDataSource implements ProfileRemoteDataSource {
  _FailingDataSource(this.code);

  final String code;

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async => throw firestoreError(code);
}

/// T-2.2.6 Guardado de los cambios del perfil.
void main() {
  test('PU-58 los errores de Firestore se traducen a mensajes para el '
      'residente', () async {
    final cases = {
      'unavailable': ProfileFailure.network,
      'permission-denied': ProfileFailure.permissionDenied,
      'not-found': ProfileFailure.notFound,
      'internal': ProfileFailure.unknown,
    };

    for (final MapEntry(key: code, value: failure) in cases.entries) {
      final repository = ProfileRepositoryImpl(
        remote: _FailingDataSource(code),
      );
      await expectLater(
        repository.updateContactInfo(uid: 'u', name: 'Ana', email: 'a@b.com', phone: '1'),
        throwsA(same(failure)),
        reason: code,
      );
    }
  });
}
