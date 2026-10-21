import 'package:image_picker/image_picker.dart';

import '../../domain/entities/evidence_file.dart';

/// Abre la cámara o la galería para elegir evidencias.
class EvidencePicker {
  EvidencePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Duración máxima de los videos grabados con la cámara.
  static const maxVideoDuration = Duration(minutes: 1);

  /// Fotos de la galería (varias) o una de la cámara. Lista vacía si el
  /// residente cancela.
  Future<List<EvidenceFile>> pickPhotos({required bool fromCamera}) async {
    if (fromCamera) {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 75,
      );
      return [if (photo != null) await _toEvidence(photo, isVideo: false)];
    }
    final photos = await _picker.pickMultiImage(
      maxWidth: 1920,
      imageQuality: 75,
    );
    return [for (final p in photos) await _toEvidence(p, isVideo: false)];
  }

  /// `null` si el residente cancela.
  Future<EvidenceFile?> pickVideo({required bool fromCamera}) async {
    final video = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );
    return video == null ? null : _toEvidence(video, isVideo: true);
  }

  Future<EvidenceFile> _toEvidence(XFile file, {required bool isVideo}) async =>
      EvidenceFile(
        path: file.path,
        isVideo: isVideo,
        sizeBytes: await file.length(),
      );
}
