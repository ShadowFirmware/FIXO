import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_picker.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_storage_data_source.dart';
import 'package:fixo/features/incidents/data/datasources/incident_remote_data_source.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/incidents/domain/entities/new_incident.dart';
import 'package:fixo/features/incidents/domain/repositories/incident_repository.dart';
import 'package:fixo/features/notifications/data/datasources/notification_remote_data_source.dart';

const photo = EvidenceFile(path: '/fotos/fuga.jpg', isVideo: false);
const video = EvidenceFile(path: '/videos/fuga.mp4', isVideo: true);

/// Transacción vacía: los fakes no escriben en Firestore.
class FakeTransaction implements Transaction {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Simula `incidencias` y el contador de folios.
class FakeIncidentRemoteDataSource implements IncidentRemoteDataSource {
  FakeIncidentRemoteDataSource({this.lastFolio = 0, this.error});

  int lastFolio;
  final FirebaseException? error;
  final created = <IncidentModel>[];

  @override
  String newId() => 'incidencia-${created.length + 1}';

  @override
  Future<IncidentModel> create({
    required String id,
    required IncidentModel Function(int folio) build,
    void Function(Transaction transaction, IncidentModel incident)? alsoWrite,
  }) async {
    if (error != null) throw error!;
    final incident = build(++lastFolio);
    created.add(incident);
    alsoWrite?.call(FakeTransaction(), incident);
    return incident;
  }

  @override
  Future<int> reserveFolio(Transaction transaction) async => ++lastFolio;

  @override
  Stream<IncidentModel?> watchById(String id) {
    if (error != null) return Stream.error(error!);
    return Stream.value(created.where((i) => i.id == id).firstOrNull);
  }
}

/// Simula Firebase Storage: devuelve una URL por archivo.
class FakeEvidenceStorage implements EvidenceStorageDataSource {
  FakeEvidenceStorage({this.error});

  final EvidenceUploadException? error;

  @override
  Future<List<String>> uploadBefore(
    String incidentId,
    List<EvidenceFile> files,
  ) async {
    if (error != null) throw error!;
    return [
      for (var i = 0; i < files.length; i++)
        'https://storage/$incidentId/${i + 1}.${files[i].extension}',
    ];
  }
}

/// Registra los avisos que se mandarían a los administradores.
class FakeNotifications implements NotificationRemoteDataSource {
  FakeNotifications({this.adminIds = const ['uid-admin']});

  final List<String> adminIds;
  final notices =
      <({List<String> adminIds, String incidentId, String title})>[];

  @override
  Future<List<String>> activeAdminIds() async => adminIds;

  @override
  void addNewIncidentNotices(
    Transaction transaction, {
    required List<String> adminIds,
    required String incidentId,
    required String reportNumber,
    required String title,
  }) {
    notices.add((adminIds: adminIds, incidentId: incidentId, title: title));
  }
}

/// Repositorio que guarda en memoria lo que recibe.
class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository({this.error});

  final IncidentFailure? error;
  final received = <NewIncident>[];

  @override
  Future<Incident> register({
    required NewIncident data,
    required String residentId,
    required String housingId,
  }) async {
    if (error != null) throw error!;
    received.add(data);
    return Incident(
      id: 'incidencia-1',
      folio: received.length,
      title: data.title,
      type: data.type,
      description: data.description,
      housingId: housingId,
      createdBy: residentId,
      status: IncidentStatus.pending,
    );
  }

  /// Controla lo que emite [watchById]: con `add` se simula un cambio en
  /// Firestore y con `addError` una falla.
  final changes = StreamController<Incident?>.broadcast();
  final watchedIds = <String>[];

  @override
  Stream<Incident?> watchById(String id) {
    watchedIds.add(id);
    return changes.stream;
  }
}

/// Simula la cámara y la galería.
class FakeEvidencePicker implements EvidencePicker {
  FakeEvidencePicker({this.photos = const [photo], this.video});

  final List<EvidenceFile> photos;
  final EvidenceFile? video;

  @override
  Future<List<EvidenceFile>> pickPhotos({required bool fromCamera}) async =>
      photos;

  @override
  Future<EvidenceFile?> pickVideo({required bool fromCamera}) async => video;
}
