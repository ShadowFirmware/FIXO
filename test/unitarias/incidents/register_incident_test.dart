import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_storage_data_source.dart';
import 'package:fixo/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/incidents/domain/entities/new_incident.dart';
import 'package:fixo/features/incidents/domain/usecases/register_incident.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'fakes.dart';

/// T-2.3.6 a T-2.3.9 Registro de la incidencia.
void main() {
  const data = NewIncident(
    title: '  Fuga en baño ',
    type: IncidentType.water,
    description: ' Gotea la llave del lavabo ',
    evidence: [photo, video],
  );

  late FakeIncidentRemoteDataSource remote;
  late FakeNotifications notifications;

  RegisterIncident registerWith({
    FakeIncidentRemoteDataSource? incidents,
    FakeEvidenceStorage? storage,
  }) => RegisterIncident(
    IncidentRepositoryImpl(
      remote: incidents ?? remote,
      storage: storage ?? FakeEvidenceStorage(),
      notifications: notifications,
    ),
  );

  setUp(() {
    remote = FakeIncidentRemoteDataSource(lastFolio: 6);
    notifications = FakeNotifications(adminIds: ['admin-1', 'admin-2']);
  });

  test('PU-64 registra la incidencia pendiente, con folio y en la vivienda '
      'del residente', () async {
    final incident = await registerWith()(
      resident: TestUsers.resident(),
      data: data,
    );

    expect(incident.reportNumber, 'INC-0007');
    expect(incident.status, IncidentStatus.pending);
    expect(incident.housingId, 'vivienda-4b');
    expect(incident.createdBy, 'uid-residente');
    expect(incident.title, 'Fuga en baño');
    expect(incident.description, 'Gotea la llave del lavabo');
    expect(incident.evidenceBefore, [
      'https://storage/incidencia-1/1.jpg',
      'https://storage/incidencia-1/2.mp4',
    ]);
  });

  test('PU-65 cada incidencia recibe un folio distinto', () async {
    final register = registerWith();
    final first = await register(resident: TestUsers.resident(), data: data);
    final second = await register(resident: TestUsers.resident(), data: data);

    expect(second.folio, first.folio + 1);
    expect(second.id, isNot(first.id));
  });

  test('PU-66 se avisa a los administradores de la nueva incidencia', () async {
    final incident = await registerWith()(
      resident: TestUsers.resident(),
      data: data,
    );

    final notice = notifications.notices.single;
    expect(notice.adminIds, ['admin-1', 'admin-2']);
    expect(notice.incidentId, incident.id);
    expect(notice.title, 'Fuga en baño');
  });

  test('PU-67 sin vivienda asignada o sin ser residente no se registra', () {
    const withoutHousing = AppUser(
      uid: 'uid-sin-vivienda',
      name: 'Ana Ruiz',
      email: 'ana@correo.com',
      phone: '7770000000',
      role: UserRole.resident,
      accountStatus: AccountStatus.active,
    );
    final register = registerWith();

    expect(
      () => register(resident: withoutHousing, data: data),
      throwsA(same(IncidentFailure.noHousing)),
    );
    expect(
      () => register(resident: TestUsers.technician, data: data),
      throwsA(same(IncidentFailure.notResident)),
    );
    expect(remote.created, isEmpty);
  });

  test('PU-68 si fallan las evidencias o Firestore se informa y no se '
      'registra', () async {
    await expectLater(
      registerWith(
        storage: FakeEvidenceStorage(error: const EvidenceUploadException()),
      )(resident: TestUsers.resident(), data: data),
      throwsA(same(IncidentFailure.evidenceUpload)),
    );
    await expectLater(
      registerWith(
        incidents: FakeIncidentRemoteDataSource(
          error: firestoreError('unavailable'),
        ),
      )(resident: TestUsers.resident(), data: data),
      throwsA(same(IncidentFailure.network)),
    );

    expect(remote.created, isEmpty);
    expect(notifications.notices, isEmpty);
  });
}
