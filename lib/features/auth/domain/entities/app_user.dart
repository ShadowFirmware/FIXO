/// Rol del usuario dentro del sistema.
enum UserRole {
  admin('admin'),
  resident('residente'),
  technician('tecnico');

  const UserRole(this.value);

  /// Valor guardado en Firestore.
  final String value;

  static UserRole? fromValue(String? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// Estado de la cuenta del usuario.
enum AccountStatus {
  active('activa'),
  suspended('suspendida'),
  disabled('deshabilitada'),
  removed('baja');

  const AccountStatus(this.value);

  final String value;

  static AccountStatus? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Estado de conducta de residentes y técnicos (HU-7.4).
enum ConductStatus {
  good('bueno'),
  medium('medio'),
  bad('malo');

  const ConductStatus(this.value);

  final String value;

  static ConductStatus? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Usuario registrado en el sistema.
///
/// Las credenciales (correo y contraseña) las administra Firebase
/// Authentication; aquí solo vive el perfil, ligado por [uid].
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.accountStatus,
    this.conductStatus,
    this.validatedReports = 0,
    this.suspendedUntil,
    this.housingId,
    this.specialty,
    this.available,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final AccountStatus accountStatus;

  // Residentes y técnicos
  final ConductStatus? conductStatus;
  final int validatedReports;
  final DateTime? suspendedUntil;

  // Solo residentes
  final String? housingId;

  // Solo técnicos
  final String? specialty;
  final bool? available;

  final DateTime? createdAt;

  /// Copia con los datos que el residente puede modificar (HU-2.2).
  AppUser copyWith({String? name, String? phone}) => AppUser(
    uid: uid,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    role: role,
    accountStatus: accountStatus,
    conductStatus: conductStatus,
    validatedReports: validatedReports,
    suspendedUntil: suspendedUntil,
    housingId: housingId,
    specialty: specialty,
    available: available,
    createdAt: createdAt,
  );
}
