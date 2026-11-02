import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/data/models/housing_model.dart';
import '../../../incidents/data/models/incident_model.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../models/assignment_plan.dart';

/// La incidencia ya no está pendiente (otro administrador la atendió).
class IncidentNotPendingException implements Exception {
  const IncidentNotPendingException();
}

/// El técnico dejó de estar disponible o activo antes de confirmar.
class TechnicianUnavailableException implements Exception {
  const TechnicianUnavailableException();
}

/// Acceso a Firestore para la gestión de incidencias del administrador
/// (HU-4.8, y las acciones de asignar y rechazar).
class IncidentAdminRemoteDataSource {
  IncidentAdminRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestoreCollections.incidents);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _housings =>
      _firestore.collection(FirestoreCollections.housings);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  static const assignedType = 'incidencia_asignada';
  static const rejectedType = 'incidencia_rechazada';

  /// Escucha las incidencias en estado "Pendiente". Se ordenan en la app
  /// para no necesitar un índice compuesto en Firestore.
  Stream<List<IncidentModel>> watchPending() {
    return _incidents
        .where('estado', isEqualTo: IncidentStatus.pending.value)
        .snapshots()
        .map((query) => [for (final doc in query.docs) ?_tryParse(doc)]);
  }

  static IncidentModel? _tryParse(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return IncidentModel.fromFirestore(doc);
    } on FormatException {
      return null;
    }
  }

  /// Nombre del usuario [uid], o `null` si no existe.
  Future<String?> userName(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data()?['nombre'] as String?;
  }

  /// Nombre para mostrar de la vivienda [id], o `null` si no existe.
  Future<String?> housingLabel(String id) async {
    final doc = await _housings.doc(id).get();
    if (!doc.exists) return null;
    try {
      return HousingModel.fromFirestore(doc).label;
    } on FormatException {
      return null;
    }
  }

  /// Técnicos con cuenta activa y estado Disponible (HU-4.9). Un técnico
  /// sin el campo `disponible` no se considera disponible.
  Future<List<UserModel>> availableTechnicians() async {
    final query = await _users
        .where('rol', isEqualTo: UserRole.technician.value)
        .where('estadoCuenta', isEqualTo: AccountStatus.active.value)
        .get();
    final technicians = <UserModel>[];
    for (final doc in query.docs) {
      try {
        final user = UserModel.fromFirestore(doc);
        if (user.available == true) technicians.add(user);
      } on FormatException {
        continue;
      }
    }
    technicians.sort((a, b) => a.name.compareTo(b.name));
    return technicians;
  }

  /// Asigna el técnico y la hora estimada. En la misma transacción el
  /// técnico queda no disponible y se avisa al residente y al técnico.
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  }) {
    return _firestore.runTransaction((transaction) async {
      final incidentRef = _incidents.doc(incidentId);
      final technicianRef = _users.doc(technicianId);
      final incidentDoc = await transaction.get(incidentRef);
      final technicianDoc = await transaction.get(technicianRef);

      AssignmentPlan.validate(
        incident: incidentDoc.data(),
        technician: technicianDoc.data(),
        now: DateTime.now(),
      );
      final incident = incidentDoc.data()!;
      final technician = technicianDoc.data()!;

      final reportNumber = Incident.formatReportNumber(
        (incident['folio'] as num?)?.toInt() ?? 0,
      );
      final title = incident['nombre'] as String? ?? '';
      final technicianName = technician['nombre'] as String? ?? 'Técnico';

      transaction.update(
        incidentRef,
        AssignmentPlan.incidentUpdate(
          technicianId: technicianId,
          estimatedTime: estimatedTime,
        ),
      );
      transaction.update(technicianRef, {'disponible': false});

      final residentId = incident['creadaPor'] as String?;
      if (residentId != null && residentId.isNotEmpty) {
        transaction.set(_notifications.doc(), {
          'usuarioId': residentId,
          'tipo': assignedType,
          'titulo': 'Incidencia $reportNumber asignada',
          'mensaje':
              '$technicianName atenderá "$title". Hora estimada de llegada: '
              '${_hour(estimatedTime)}.',
          'refId': incidentId,
          'leida': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(_notifications.doc(), {
        'usuarioId': technicianId,
        'tipo': assignedType,
        'titulo': 'Nueva asignación $reportNumber',
        'mensaje':
            'Se te asignó "$title". Hora estimada de llegada: '
            '${_hour(estimatedTime)}.',
        'refId': incidentId,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Rechaza la incidencia con el [comment] del administrador y avisa al
  /// residente. No se asigna técnico.
  Future<void> reject({required String incidentId, required String comment}) {
    return _firestore.runTransaction((transaction) async {
      final incidentRef = _incidents.doc(incidentId);
      final incidentDoc = await transaction.get(incidentRef);
      final incident = incidentDoc.data();
      if (incident == null ||
          incident['estado'] != IncidentStatus.pending.value) {
        throw const IncidentNotPendingException();
      }

      final reportNumber = Incident.formatReportNumber(
        (incident['folio'] as num?)?.toInt() ?? 0,
      );

      transaction.update(incidentRef, {
        'estado': IncidentStatus.rejected.value,
        'comentarioRechazo': comment,
        'fechaRechazo': FieldValue.serverTimestamp(),
      });

      final residentId = incident['creadaPor'] as String?;
      if (residentId != null && residentId.isNotEmpty) {
        transaction.set(_notifications.doc(), {
          'usuarioId': residentId,
          'tipo': rejectedType,
          'titulo': 'Incidencia $reportNumber rechazada',
          'mensaje': 'Motivo: $comment',
          'refId': incidentId,
          'leida': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static String _hour(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'a. m.' : 'p. m.';
    return '${date.day}/${date.month}/${date.year} $hour:$minute $period';
  }
}
