/// Foto o video elegido en el dispositivo, antes de subirse.
class EvidenceFile {
  const EvidenceFile({
    required this.path,
    required this.isVideo,
    this.sizeBytes = 0,
  });

  final String path;
  final bool isVideo;
  final int sizeBytes;

  /// Extensión en minúsculas, por ejemplo "jpg" o "mp4".
  String get extension {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return isVideo ? 'mp4' : 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }
}
