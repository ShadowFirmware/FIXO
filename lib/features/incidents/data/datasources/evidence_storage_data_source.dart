import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/cloudinary_config.dart';
import '../../domain/entities/evidence_file.dart';

/// No se pudo subir una evidencia.
class EvidenceUploadException implements Exception {
  const EvidenceUploadException({this.network = false});

  /// `true` si falló por falta de conexión.
  final bool network;
}

/// Sube las evidencias a Cloudinary. En Firestore solo se guardan sus URLs.
class EvidenceStorageDataSource {
  EvidenceStorageDataSource({
    http.Client? client,
    this._cloudName = CloudinaryConfig.cloudName,
    this._uploadPreset = CloudinaryConfig.uploadPreset,
  }) : _clientOverride = client;

  final http.Client? _clientOverride;
  final String _cloudName;
  final String _uploadPreset;

  bool get _isConfigured =>
      !_cloudName.startsWith('TU_') && !_uploadPreset.startsWith('TU_');

  static const _timeout = Duration(minutes: 2);

  /// Sube los archivos a la carpeta `fixo/incidencias/{incidentId}/antes` y
  /// devuelve sus URLs en el mismo orden. Lanza [EvidenceUploadException]
  /// si alguno falla.
  Future<List<String>> uploadBefore(
    String incidentId,
    List<EvidenceFile> files,
  ) async {
    if (files.isEmpty) return const [];
    if (!_isConfigured) {
      throw const EvidenceUploadException();
    }

    final client = _clientOverride ?? http.Client();
    try {
      return [
        for (var i = 0; i < files.length; i++)
          await _upload(
            client,
            files[i],
            folder: '${CloudinaryConfig.folder}/incidencias/$incidentId/antes',
            publicId: '${i + 1}',
          ),
      ];
    } on SocketException {
      throw const EvidenceUploadException(network: true);
    } on TimeoutException {
      throw const EvidenceUploadException(network: true);
    } on http.ClientException {
      throw const EvidenceUploadException(network: true);
    } finally {
      if (_clientOverride == null) client.close();
    }
  }

  Future<String> _upload(
    http.Client client,
    EvidenceFile file, {
    required String folder,
    required String publicId,
  }) async {
    final resourceType = file.isVideo ? 'video' : 'image';
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/$_cloudName/$resourceType/upload',
            ),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = folder
          ..fields['public_id'] = publicId
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await http.Response.fromStream(
      await client.send(request).timeout(_timeout),
    );
    if (response.statusCode != 200) throw const EvidenceUploadException();

    final url =
        (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'];
    if (url is! String) throw const EvidenceUploadException();
    return url;
  }
}
