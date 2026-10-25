import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

/// Miniaturas de las fotos y videos de una incidencia. Al tocar una se abre
/// en pantalla completa.
class EvidenceGallery extends StatelessWidget {
  const EvidenceGallery({super.key, required this.urls});

  final List<String> urls;

  /// Cloudinary guarda los videos bajo `/video/upload/`.
  static bool isVideo(String url) => url.contains('/video/upload/');

  /// Cloudinary genera un cuadro del video si se pide con extensión `.jpg`.
  static String videoThumbnail(String url) {
    final dot = url.lastIndexOf('.');
    final slash = url.lastIndexOf('/');
    return dot > slash ? '${url.substring(0, dot)}.jpg' : '$url.jpg';
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No se adjuntaron evidencias.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final url in urls)
            _Thumbnail(
              url: url,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => isVideo(url)
                      ? _VideoViewer(url: url)
                      : _PhotoViewer(url: url),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final video = EvidenceGallery.isVideo(url);

    return SizedBox.square(
      dimension: _size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video ? EvidenceGallery.videoThumbnail(url) : url,
              fit: BoxFit.cover,
              cacheWidth: 240,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(color: AppColors.surfaceAlt),
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.surfaceAlt,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            if (video)
              const ColoredBox(
                color: Color(0x55000000),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto en pantalla completa; se puede acercar con dos dedos.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
      ),
      body: InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const CircularProgressIndicator(color: AppColors.white),
            errorBuilder: (_, _, _) => const _ViewerError(),
          ),
        ),
      ),
    );
  }
}

/// Reproductor del video; se toca para pausar o continuar.
class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.url});

  final String url;

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late final _controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: _failed
            ? const _ViewerError()
            : !value.isInitialized
            ? const CircularProgressIndicator(color: AppColors.white)
            : GestureDetector(
                onTap: _togglePlay,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    if (!value.isPlaying)
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.white,
                        size: 72,
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No se pudo cargar la evidencia.',
      style: TextStyle(color: AppColors.white),
    );
  }
}
