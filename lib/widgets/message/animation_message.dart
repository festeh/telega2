import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/ui_constants.dart';
import '../../presentation/providers/download_progress_provider.dart';
import '../common/circular_download_progress.dart';
import 'media_placeholder.dart';
import 'media_utils.dart';

class AnimationMessageWidget extends ConsumerStatefulWidget {
  final String? animationPath;
  final int? animationWidth;
  final int? animationHeight;
  final String? thumbnailPath;
  final int? animationFileId;
  final bool isOutgoing;

  const AnimationMessageWidget({
    super.key,
    this.animationPath,
    this.animationWidth,
    this.animationHeight,
    this.thumbnailPath,
    this.animationFileId,
    required this.isOutgoing,
  });

  @override
  ConsumerState<AnimationMessageWidget> createState() =>
      _AnimationMessageWidgetState();
}

class _AnimationMessageWidgetState
    extends ConsumerState<AnimationMessageWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initIfReady();
  }

  @override
  void didUpdateWidget(AnimationMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // File just finished downloading — initialize player
    if (oldWidget.animationPath != widget.animationPath &&
        widget.animationPath != null &&
        widget.animationPath!.isNotEmpty) {
      _initIfReady();
    }
  }

  void _initIfReady() {
    final path = widget.animationPath;
    if (path == null || path.isEmpty || _controller != null) return;

    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    controller.setLooping(true);
    controller.setVolume(0);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isInitialized = true);
      controller.play();
    }).catchError((e) {
      debugPrint('Error initializing animation: $e');
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullScreen(BuildContext context) {
    final path = widget.animationPath;
    if (path == null || path.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenAnimation(animationPath: path);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (displayWidth, displayHeight) = calculateMediaDimensions(
      width: widget.animationWidth,
      height: widget.animationHeight,
    );
    final hasAnimation =
        widget.animationPath != null && widget.animationPath!.isNotEmpty;
    final thumbPath = widget.thumbnailPath;
    final hasThumbnail = thumbPath != null && thumbPath.isNotEmpty;

    // Watch download progress for this file
    final downloadState = ref.watchFileDownloadState(widget.animationFileId);
    final hasFailed =
        downloadState != null && downloadState.status == DownloadStatus.failed;

    return GestureDetector(
      onTap: hasAnimation ? () => _openFullScreen(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Auto-playing video, thumbnail, or placeholder
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (hasThumbnail)
                Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const MediaPlaceholder(
                      icon: Icons.gif,
                      label: 'GIF',
                    );
                  },
                )
              else
                const MediaPlaceholder(icon: Icons.gif, label: 'GIF'),
              // Download progress (only when not yet downloaded)
              if (!hasAnimation)
                Center(
                  child: CircularDownloadProgress(
                    progress: downloadState?.progress ?? 0.0,
                    hasError: hasFailed,
                    onRetry: hasFailed && widget.animationFileId != null
                        ? () => ref.retryDownload(widget.animationFileId!)
                        : null,
                  ),
                ),
              // GIF badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: const Text(
                    'GIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenAnimation extends StatefulWidget {
  final String animationPath;

  const _FullScreenAnimation({required this.animationPath});

  @override
  State<_FullScreenAnimation> createState() => _FullScreenAnimationState();
}

class _FullScreenAnimationState extends State<_FullScreenAnimation> {
  late VideoPlayerController _controller;
  late final FocusNode _focusNode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.animationPath));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(0);
      setState(() => _isInitialized = true);
      _controller.play();
    } catch (e) {
      debugPrint('Error initializing animation: $e');
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
          }
        },
        child: GestureDetector(
          onTap: _close,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  onPressed: _close,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
