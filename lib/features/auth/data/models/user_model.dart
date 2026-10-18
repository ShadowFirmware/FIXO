import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// Convierte los documentos de la colección `usuarios` en [AppUser].
class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required super.accountStatus,
    super.conductStatus,
    super.validatedReports,
    super.suspendedUntil,
    super.housingId,
    super.specialty,
    super.available,
    super.createdAt,
  });

  /// Lanza [FormatException] si el documento no tiene un rol o estado de
  /// cuenta válido.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('El usuario ${doc.id} no existe');
    }

    final role = UserRole.fromValue(data['rol'] as String?);
    if (role == null) {
      throw FormatException('Rol no válido: ${data['rol']}');
    }

    final accountStatus = AccountStatus.fromValue(
      data['estadoCuenta'] as String?,
    );
    if (accountStatus == null) {
      throw FormatException(
        'Estado de cuenta no válido: ${data['estadoCuenta']}',
      );
    }

    return UserModel(
      uid: doc.id,
      name: data['nombre'] as String? ?? '',
      email: data['correo'] as String? ?? '',
      phone: data['telefono'] as String? ?? '',
      role: role,
      accountStatus: accountStatus,
      conductStatus: ConductStatus.fromValue(data['estadoConducta'] as String?),
      validatedReports: (data['reportesValidados'] as num?)?.toInt() ?? 0,
      suspendedUntil: (data['suspendidaHasta'] as Timestamp?)?.toDate(),
      housingId: data['viviendaId'] as String?,
      specialty: data['especialidad'] as String?,
      available: data['disponible'] as bool?,
      createdAt: (data['fechaRegistro'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': name,
      'correo': email,
      'telefono': phone,
      'rol': role.value,
      'estadoCuenta': accountStatus.value,
      'fechaRegistro': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (role != UserRole.admin) ...{
        'estadoConducta': (conductStatus ?? ConductStatus.good).value,
        'reportesValidados': validatedReports,
        'suspendidaHasta': suspendedUntil != null
            ? Timestamp.fromDate(suspendedUntil!)
            : null,
      },
      if (role == UserRole.resident) 'viviendaId': housingId,
      if (role == UserRole.technician) ...{
        'especialidad': specialty,
        'disponible': available ?? true,
      },
    };
  }
}
