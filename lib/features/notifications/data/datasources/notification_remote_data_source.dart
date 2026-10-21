import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Escritura de avisos en la colección `notificaciones`.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Tipo de aviso para una incidencia pendiente de asignación (HU-2.3).
  static const newIncidentType = 'nueva_incidencia';

  /// UIDs de los administradores con cuenta activa.
  Future<List<String>> activeAdminIds() async {
    final admins = await _firestore
        .collection(FirestoreCollections.users)
        .where('rol', isEqualTo: UserRole.admin.value)
        .where('estadoCuenta', isEqualTo: AccountStatus.active.value)
        .get();
    return [for (final doc in admins.docs) doc.id];
  }

  /// Agrega dentro de [transaction] un aviso para cada administrador, para
  /// que se guarde junto con la incidencia o no se guarde ninguno.
  void addNewIncidentNotices(
    Transaction transaction, {
    required List<String> adminIds,
    required String incidentId,
    required String reportNumber,
    required String title,
  }) {
    final notifications = _firestore.collection(
      FirestoreCollections.notifications,
    );
    for (final adminId in adminIds) {
      transaction.set(notifications.doc(), {
        'usuarioId': adminId,
        'tipo': newIncidentType,
        'titulo': 'Nueva incidencia $reportNumber',
        'mensaje': '"$title" está pendiente de asignación.',
        'refId': incidentId,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
      });
    }
  }
}
