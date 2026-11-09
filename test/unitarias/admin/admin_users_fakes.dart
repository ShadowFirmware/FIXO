import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/features/admin/domain/repositories/resident_admin_repository.dart';
import 'package:fixo/features/admin/domain/repositories/technician_admin_repository.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';

/// Correo que ya está registrado en los fakes.
const takenEmail = 'ocupado@correo.com';

const duplicatedEmail = AuthFailure(
  'El correo electrónico ya está registrado.',
);

AppUser residentUser(
  String uid,
  String name, {
  String? housingId = 'viv-4b',
  AccountStatus status = AccountStatus.active,
}) => AppUser(
  uid: uid,
  name: name,
  email: '$uid@correo.com',
  phone: '7771112233',
  role: UserRole.resident,
  accountStatus: status,
  conductStatus: ConductStatus.good,
  housingId: housingId,
);

AppUser technicianUser(
  String uid,
  String name, {
  String specialty = 'Electricidad',
  AccountStatus status = AccountStatus.active,
}) => AppUser(
  uid: uid,
  name: name,
  email: '$uid@correo.com',
  phone: '7774445566',
  role: UserRole.technician,
  accountStatus: status,
  conductStatus: ConductStatus.good,
  specialty: specialty,
  available: true,
);

/// Simula los residentes y las viviendas en Firestore.
class FakeResidentAdminRepository implements ResidentAdminRepository {
  FakeResidentAdminRepository({
    List<AppUser>? residents,
    List<Housing>? housings,
  }) : residents = residents ?? [],
       housings =
           housings ??
           const [
             Housing(
               id: 'viv-4b',
               type: HousingType.apartment,
               number: '4B',
               building: 'Torre A',
               residentId: 'res-ana',
             ),
             Housing(
               id: 'viv-5c',
               type: HousingType.apartment,
               number: '5C',
               building: 'Torre A',
             ),
           ];

  final List<AppUser> residents;
  final List<Housing> housings;

  /// Datos de cada registro y edición.
  final registered = <Map<String, String>>[];
  final updated = <Map<String, String?>>[];
  final removed = <String>[];
  final enabled = <String>[];

  @override
  Future<List<AppUser>> listResidents() async => List.of(residents);

  @override
  Future<List<Housing>> listHousings() async => housings;

  @override
  Future<List<Housing>> listAvailableHousings() async =>
      housings.where((h) => h.active && h.residentId == null).toList();

  @override
  Future<void> registerResident({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String housingId,
  }) async {
    if (email == takenEmail) throw duplicatedEmail;
    registered.add({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'housingId': housingId,
    });
    residents.add(residentUser('res-nuevo', name, housingId: housingId));
  }

  @override
  Future<void> updateResident({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? housingId,
    String? previousHousingId,
  }) async {
    updated.add({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'housingId': housingId,
    });
  }

  @override
  Future<void> removeResident({required String uid, String? housingId}) async =>
      removed.add(uid);

  @override
  Future<void> deleteResident({required String uid, String? housingId}) =>
      removeResident(uid: uid, housingId: housingId);

  @override
  Future<void> deactivateResident({required String uid, String? housingId}) =>
      removeResident(uid: uid, housingId: housingId);

  @override
  Future<void> enableResident({required String uid}) async => enabled.add(uid);

  @override
  Future<void> activateResident({required String uid}) =>
      enableResident(uid: uid);
}

/// Simula los técnicos en Firestore.
class FakeTechnicianAdminRepository implements TechnicianAdminRepository {
  FakeTechnicianAdminRepository({List<AppUser>? technicians})
    : technicians = technicians ?? [];

  final List<AppUser> technicians;

  final registered = <Map<String, String>>[];
  final updated = <Map<String, String?>>[];
  final removed = <String>[];
  final enabled = <String>[];

  @override
  Future<List<AppUser>> listTechnicians() async => List.of(technicians);

  @override
  Future<void> registerTechnician({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
  }) async {
    if (email == takenEmail) throw duplicatedEmail;
    registered.add({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'specialty': specialty,
    });
    technicians.add(technicianUser('tec-nuevo', name, specialty: specialty));
  }

  @override
  Future<void> updateTechnician({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? specialty,
  }) async {
    updated.add({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'specialty': specialty,
    });
  }

  @override
  Future<void> removeTechnician({required String uid}) async =>
      removed.add(uid);

  @override
  Future<void> deleteTechnician({required String uid}) =>
      removeTechnician(uid: uid);

  @override
  Future<void> deactivateTechnician({required String uid}) =>
      removeTechnician(uid: uid);

  @override
  Future<void> enableTechnician({required String uid}) async =>
      enabled.add(uid);

  @override
  Future<void> activateTechnician({required String uid}) =>
      enableTechnician(uid: uid);
}
