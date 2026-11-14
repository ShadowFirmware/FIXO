import 'package:image_picker/image_picker.dart';

import '../../../../core/services/app_permissions.dart';

import '../../domain/entities/evidence_file.dart';

/// Abre la cámara o la galería para elegir evidencias.
class EvidencePicker {
  EvidencePicker({ImagePicker? picker, AppPermissions? permissions})
    : _picker = picker ?? ImagePicker(),
      _permissions = permissions ?? const DeviceAppPermissions();

  final ImagePicker _picker;
  final AppPermissions _permissions;

  /// Duración máxima de los videos grabados con la cámara.
  static const maxVideoDuration = Duration(minutes: 1);

  /// Fotos de la galería (varias) o una de la cámara. Lista vacía si el
  /// residente cancela.
  Future<List<EvidenceFile>> pickPhotos({required bool fromCamera}) async {
    if (fromCamera) {
      await _ensureCamera();
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
    if (fromCamera) await _ensureCamera();
    final video = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );
    return video == null ? null : _toEvidence(video, isVideo: true);
  }

  /// Pide el permiso de la cámara la primera vez que se usa. Lanza
  /// [CameraPermissionDeniedException] si no se concede.
  Future<void> _ensureCamera() async {
    final state = await _permissions.requestCamera();
    if (state == PermissionState.granted ||
        state == PermissionState.notRequired) {
      return;
    }
    throw CameraPermissionDeniedException(
      permanently: state == PermissionState.permanentlyDenied,
    );
  }

  Future<EvidenceFile> _toEvidence(XFile file, {required bool isVideo}) async =>
      EvidenceFile(
        path: file.path,
        isVideo: isVideo,
        sizeBytes: await file.length(),
      );
}

/// No se concedió el permiso de la cámara.
class CameraPermissionDeniedException implements Exception {
  const CameraPermissionDeniedException({required this.permanently});

  /// El sistema ya no vuelve a preguntar: hay que activarlo en los ajustes.
  final bool permanently;

  String get message => permanently
      ? 'FIXO no tiene acceso a la cámara. Actívalo en los ajustes del '
            'teléfono para tomar fotos o videos.'
      : 'Para tomar fotos o videos, permite el acceso a la cámara.';
}
