import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/providers/register_incident_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';

/// HU-2.3 Registrar incidencia: formulario.
void main() {
  late AuthSession session;
  late FakeIncidentRepository incidents;

  RegisterIncidentViewModel createViewModel({
    FakeIncidentRepository? repository,
    FakeEvidencePicker? picker,
  }) {
    final vm = RegisterIncidentViewModel(
      session: session,
      housings: FakeHousingRepository(),
      incidents: repository ?? incidents,
      picker: picker ?? FakeEvidencePicker(),
    );
    addTearDown(vm.dispose);
    return vm;
  }

  void fillValid(RegisterIncidentViewModel vm) {
    vm
      ..title = 'Fuga en baño'
      ..description = 'Gotea la llave del lavabo'
      ..selectType(IncidentType.water);
  }

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.resident());
    incidents = FakeIncidentRepository();
  });

  test('PU-69 muestra la vivienda del residente, que no se puede '
      'cambiar', () async {
    final vm = createViewModel();
    await pumpEventQueue();

    expect(vm.housing, 'Torre A – 4B');
    expect(vm.hasHousing, isTrue);
  });

  test('PU-70 sin los campos obligatorios no se registra', () async {
    final vm = createViewModel();

    expect(await vm.register(), isNull);
    expect(vm.errorMessage, 'Ingresa un título');
    expect(vm.typeError, 'Elige el tipo de incidencia');

    vm
      ..title = 'Fuga en baño'
      ..selectType(IncidentType.water);
    expect(await vm.register(), isNull);
    expect(vm.errorMessage, 'Describe el problema');
    expect(vm.typeError, isNull);

    expect(incidents.received, isEmpty);
  });

  test('PU-71 se pueden adjuntar fotos y videos, hasta 5', () async {
    final vm = createViewModel(
      picker: FakeEvidencePicker(photos: [photo, photo, photo], video: video),
    );

    await vm.addPhotos(fromCamera: false);
    await vm.addVideo(fromCamera: true);
    expect(vm.evidence.length, 4);
    expect(vm.evidence.last.isVideo, isTrue);

    await vm.addPhotos(fromCamera: false);
    expect(vm.evidence.length, 5);
    expect(vm.canAddEvidence, isFalse);
    expect(vm.evidenceMessage, 'Solo puedes adjuntar hasta 5 evidencias.');

    vm.removeEvidence(vm.evidence.first);
    expect(vm.evidence.length, 4);
  });

  test('PU-72 no acepta videos de más de 50 MB', () async {
    const heavy = EvidenceFile(
      path: '/videos/largo.mp4',
      isVideo: true,
      sizeBytes: 60 * 1024 * 1024,
    );
    final vm = createViewModel(picker: FakeEvidencePicker(video: heavy));

    await vm.addVideo(fromCamera: false);

    expect(vm.evidence, isEmpty);
    expect(
      vm.evidenceMessage,
      'Las fotos pueden pesar hasta 10 MB y los videos hasta 50 MB.',
    );
  });

  test('PU-73 con datos válidos registra la incidencia con sus '
      'evidencias', () async {
    final vm = createViewModel();
    fillValid(vm);
    await vm.addPhotos(fromCamera: true);

    final incident = await vm.register();

    expect(incident, isNotNull);
    expect(incident!.reportNumber, 'INC-0001');
    expect(incident.status, IncidentStatus.pending);
    expect(incidents.received.single.evidence, [photo]);
    expect(vm.isSaving, isFalse);
  });

  test('PU-74 si falla el registro se informa al residente', () async {
    final vm = createViewModel(
      repository: FakeIncidentRepository(error: IncidentFailure.network),
    );
    fillValid(vm);

    expect(await vm.register(), isNull);
    expect(vm.errorMessage, IncidentFailure.network.message);
    expect(vm.isSaving, isFalse);
  });
}
