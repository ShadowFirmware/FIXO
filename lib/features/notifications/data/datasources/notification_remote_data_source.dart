import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

/// Servicio de avisos (HU-6.1): guarda en la colección `notificaciones` los
/// avisos que arman los demás módulos con [NotificationModel.newNotice].
///
/// Los avisos de una operación se guardan en la misma transacción o lote
/// que el cambio que los provoca, así no queda un cambio sin aviso ni un
/// aviso sin cambio.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  /// Tipo de aviso para una incidencia pendiente de asignación (HU-2.3).
  static final newIncidentType = NotificationType.newIncident.value;

  /// UIDs de los administradores con cuenta activa.
  Future<List<String>> activeAdminIds() async {
    final admins = await _firestore
        .collection(FirestoreCollections.users)
        .where('rol', isEqualTo: UserRole.admin.value)
        .where('estadoCuenta', isEqualTo: AccountStatus.active.value)
        .get();
    return [for (final doc in admins.docs) doc.id];
  }

  /// Avisos de [userId], del más reciente al más antiguo, cada vez que
  /// cambian. Se ordenan en la app para no necesitar un índice compuesto;
  /// los que todavía no tienen fecha del servidor van primero.
  Stream<List<NotificationModel>> watchFor(String userId) => _notifications
      .where('usuarioId', isEqualTo: userId)
      .snapshots()
      .map((query) {
        final notices = <NotificationModel>[];
        for (final doc in query.docs) {
          try {
            notices.add(NotificationModel.fromMap(doc.id, doc.data()));
          } on FormatException {
            // Un aviso con datos inválidos no oculta los demás.
            continue;
          }
        }
        return notices..sort(newestFirst);
      });

  /// Orden de la lista: primero los más recientes.
  static int newestFirst(AppNotification a, AppNotification b) {
    final aDate = a.date;
    final bDate = b.date;
    if (aDate == null || bDate == null) {
      return (aDate == null ? 0 : 1) - (bDate == null ? 0 : 1);
    }
    return bDate.compareTo(aDate);
  }

  /// Agrega [notices] dentro de [transaction].
  void addNotices(
    Transaction transaction,
    Iterable<Map<String, dynamic>> notices,
  ) {
    for (final notice in notices) {
      transaction.set(_notifications.doc(), notice);
    }
  }

  /// Agrega [notices] a [batch].
  void addToBatch(WriteBatch batch, Iterable<Map<String, dynamic>> notices) {
    for (final notice in notices) {
      batch.set(_notifications.doc(), notice);
    }
  }

  /// Guarda [notices] por su cuenta, cuando no acompañan a otro cambio.
  Future<void> send(Iterable<Map<String, dynamic>> notices) {
    final batch = _firestore.batch();
    addToBatch(batch, notices);
    return batch.commit();
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
    addNotices(transaction, [
      for (final adminId in adminIds)
        NotificationModel.newNotice(
          userId: adminId,
          type: NotificationType.newIncident,
          title: 'Nueva incidencia $reportNumber',
          message: '"$title" está pendiente de asignación.',
          refId: incidentId,
        ),
    ]);
  }
}
