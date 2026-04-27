import 'dart:async';
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants/ui_constants.dart';
import '../../presentation/providers/download_progress_provider.dart';
import '../common/circular_download_progress.dart';
import 'media_error.dart';
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
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<int?>? _widthSub;
  StreamSubscription<String>? _errorSub;
  bool _isInitialized = false;
  String? _initError;

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
      _initError = null;
      _initIfReady();
    }
  }

  void _initIfReady() {
    final path = widget.animationPath;
    if (path == null || path.isEmpty || _player != null) return;

    final player = Player();
    _player = player;
    _videoController = VideoController(
      player,
      configuration: videoControllerConfig(),
    );

    _widthSub = player.stream.width.listen((w) {
      if (!mounted || w == null || _isInitialized) return;
      setState(() => _isInitialized = true);
    });

    _errorSub = player.stream.error.listen((err) {
      if (!mounted || err.isEmpty) return;
      debugPrint('Error initializing animation: $err');
      setState(() => _initError = err);
    });

    player.setPlaylistMode(PlaylistMode.loop);
    player.setVolume(0);
    player.open(Media(path));
  }

  @override
  void dispose() {
    _widthSub?.cancel();
    _errorSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  MediaError? _currentError(bool downloadFailed) {
    if (_initError != null) {
      return MediaError(message: 'Cannot play GIF', details: _initError);
    }
    if (downloadFailed && widget.animationFileId != null) {
      return MediaError(
        message: 'Download failed',
        onRetry: () => ref.retryDownload(widget.animationFileId!),
      );
    }
    if (widget.animationFileId == null && !_isInitialized) {
      return const MediaError(message: 'No file attached');
    }
    return null;
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

    final error = _currentError(hasFailed);

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
              // Background: playing video, or thumbnail (if downloaded)
              if (_isInitialized && _videoController != null)
                Video(
                  controller: _videoController!,
                  controls: NoVideoControls,
                  fit: BoxFit.cover,
                )
              else if (hasThumbnail && error == null)
                Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stackTrace) => MediaError(
                    message: 'Thumbnail unreadable',
                    details: '$err',
                  ),
                ),
              // Error takes over the entire tile when present
              ?error,
              // Download progress (only when not yet downloaded and no error)
              if (!hasAnimation && error == null)
                Center(
                  child: CircularDownloadProgress(
                    progress: downloadState?.progress ?? 0.0,
                    hasError: false,
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
  late final Player _player;
  late final VideoController _videoController;
  late final FocusNode _focusNode;
  StreamSubscription<int?>? _widthSub;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _player = Player();
    _videoController = VideoController(
      _player,
      configuration: videoControllerConfig(),
    );

    _widthSub = _player.stream.width.listen((w) {
      if (!mounted || w == null || _isInitialized) return;
      setState(() => _isInitialized = true);
    });

    _player.setPlaylistMode(PlaylistMode.loop);
    _player.setVolume(0);
    _player.open(Media(widget.animationPath));
  }

  @override
  void dispose() {
    _widthSub?.cancel();
    _focusNode.dispose();
    _player.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
          }
        },
        child: ExtendedImageSlidePage(
          slideAxis: SlideAxis.vertical,
          slideType: SlideType.onlyImage,
          slidePageBackgroundHandler: (offset, pageSize) {
            final double ratio = (offset.dy.abs() / (pageSize.height / 2))
                .clamp(0.0, 1.0);
            return Colors.black.withValues(alpha: 1 - ratio);
          },
          child: GestureDetector(
            onTap: _close,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: ExtendedImageSlidePageHandler(
                    child: _isInitialized
                        ? Video(
                            controller: _videoController,
                            controls: NoVideoControls,
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: _close,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
