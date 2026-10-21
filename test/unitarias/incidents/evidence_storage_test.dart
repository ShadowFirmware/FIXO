import 'dart:convert';
import 'dart:io';

import 'package:fixo/features/incidents/data/datasources/evidence_storage_data_source.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// T-2.3.4 Carga de las evidencias en Cloudinary.
void main() {
  late Directory temp;
  late EvidenceFile photo;
  late EvidenceFile video;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('evidencias');
    photo = EvidenceFile(
      path: (File('${temp.path}/foto.jpg')..writeAsBytesSync([1, 2])).path,
      isVideo: false,
    );
    video = EvidenceFile(
      path: (File('${temp.path}/video.mp4')..writeAsBytesSync([3, 4])).path,
      isVideo: true,
    );
  });

  tearDown(() => temp.deleteSync(recursive: true));

  EvidenceStorageDataSource storageWith(MockClient client) =>
      EvidenceStorageDataSource(
        client: client,
        cloudName: 'demo',
        uploadPreset: 'fixo_unsigned',
      );

  test('PU-77 sube fotos y videos a Cloudinary y devuelve sus URLs', () async {
    final requests = <http.BaseRequest>[];
    final storage = storageWith(
      MockClient((request) async {
        requests.add(request);
        final kind = request.url.pathSegments[2];
        return http.Response(
          jsonEncode({'secure_url': 'https://res.cloudinary.com/$kind'}),
          200,
        );
      }),
    );

    final urls = await storage.uploadBefore('inc-1', [photo, video]);

    expect(urls, [
      'https://res.cloudinary.com/image',
      'https://res.cloudinary.com/video',
    ]);
    expect(requests.map((r) => r.url.path), [
      '/v1_1/demo/image/upload',
      '/v1_1/demo/video/upload',
    ]);
  });

  test('PU-78 si Cloudinary rechaza el archivo o no hay conexión se '
      'lanza un error', () async {
    final rejected = storageWith(
      MockClient((_) async => http.Response('{"error": {}}', 400)),
    );
    await expectLater(
      rejected.uploadBefore('inc-1', [photo]),
      throwsA(
        isA<EvidenceUploadException>().having((e) => e.network, 'red', false),
      ),
    );

    final offline = storageWith(
      MockClient((_) async => throw const SocketException('sin red')),
    );
    await expectLater(
      offline.uploadBefore('inc-1', [photo]),
      throwsA(
        isA<EvidenceUploadException>().having((e) => e.network, 'red', true),
      ),
    );
  });
}
