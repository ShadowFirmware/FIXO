import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/evidence_file.dart';

/// Foto o video del dispositivo en pantalla completa, para revisarlo antes
/// de subirlo (HU-3.6). La foto se puede acercar con dos dedos y el video se
/// toca para pausar o continuar.
class LocalEvidenceViewer extends StatefulWidget {
  const LocalEvidenceViewer({super.key, required this.file});

  final EvidenceFile file;

  /// Abre [file] en pantalla completa.
  static Future<void> open(BuildContext context, EvidenceFile file) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LocalEvidenceViewer(file: file),
        ),
      );

  @override
  State<LocalEvidenceViewer> createState() => _LocalEvidenceViewerState();
}

class _LocalEvidenceViewerState extends State<LocalEvidenceViewer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.file.isVideo) return;
    final controller = _controller = VideoPlayerController.file(
      File(widget.file.path),
    );
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          controller.play();
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final controller = _controller!;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
      ),
      body: Center(child: _failed ? const _ViewerError() : _content()),
    );
  }

  Widget _content() {
    final controller = _controller;
    if (controller == null) {
      return InteractiveViewer(
        maxScale: 4,
        child: Image.file(
          File(widget.file.path),
          errorBuilder: (_, _, _) => const _ViewerError(),
        ),
      );
    }

    final value = controller.value;
    if (!value.isInitialized) {
      return const CircularProgressIndicator(color: AppColors.white);
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: value.aspectRatio,
            child: VideoPlayer(controller),
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
            child: VideoProgressIndicator(controller, allowScrubbing: true),
          ),
        ],
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No se pudo abrir la evidencia.',
      style: TextStyle(color: AppColors.white),
    );
  }
}
