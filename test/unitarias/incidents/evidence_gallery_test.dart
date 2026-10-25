import 'package:fixo/features/incidents/presentation/widgets/evidence_gallery.dart';
import 'package:flutter_test/flutter_test.dart';

/// T-2.4.3 Fotografías y videos de la incidencia.
void main() {
  test('PU-89 distingue fotos y videos de Cloudinary y genera la miniatura '
      'del video', () {
    const photo = 'https://res.cloudinary.com/a60rrjpn/image/upload/v1/1.jpg';
    const video = 'https://res.cloudinary.com/a60rrjpn/video/upload/v1/2.mp4';

    expect(EvidenceGallery.isVideo(photo), isFalse);
    expect(EvidenceGallery.isVideo(video), isTrue);
    expect(
      EvidenceGallery.videoThumbnail(video),
      'https://res.cloudinary.com/a60rrjpn/video/upload/v1/2.jpg',
    );
  });
}
