import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/ui_constants.dart';
import '../../presentation/providers/download_progress_provider.dart';
import '../common/circular_download_progress.dart';
import 'media_placeholder.dart';
import 'media_utils.dart';

class PhotoMessageWidget extends ConsumerWidget {
  final String? photoPath;
  final int? photoWidth;
  final int? photoHeight;
  final int? photoFileId;
  final bool isOutgoing;

  const PhotoMessageWidget({
    super.key,
    this.photoPath,
    this.photoWidth,
    this.photoHeight,
    this.photoFileId,
    required this.isOutgoing,
  });

  void _openFullScreen(BuildContext context) {
    final path = photoPath;
    if (path == null || path.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(imagePath: path);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final (displayWidth, displayHeight) = calculateMediaDimensions(
      width: photoWidth,
      height: photoHeight,
    );
    final path = photoPath;
    final hasPhoto = path != null && path.isNotEmpty;

    // Watch download progress for this file
    final downloadState = ref.watchFileDownloadState(photoFileId);
    final isDownloading =
        downloadState != null &&
        downloadState.status == DownloadStatus.downloading;
    final hasFailed =
        downloadState != null && downloadState.status == DownloadStatus.failed;

    return GestureDetector(
      onTap: hasPhoto ? () => _openFullScreen(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasPhoto ? _buildImage() : const MediaPlaceholder.photo(),
              // Show progress overlay when downloading or failed
              if (!hasPhoto && (isDownloading || hasFailed))
                Center(
                  child: CircularDownloadProgress(
                    progress: downloadState.progress,
                    hasError: hasFailed,
                    onRetry: hasFailed && photoFileId != null
                        ? () => ref.retryDownload(photoFileId!)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final path = photoPath;
    if (path == null) return const SizedBox.shrink();

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const MediaPlaceholder.photo();
      },
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  static const List<double> _doubleTapScales = [1.0, 2.0];

  late final FocusNode _focusNode;
  late final AnimationController _doubleTapController;
  Animation<double>? _doubleTapAnimation;
  VoidCallback? _doubleTapListener;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
    _doubleTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    if (_doubleTapListener != null) {
      _doubleTapAnimation?.removeListener(_doubleTapListener!);
    }
    _doubleTapController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _onDoubleTap(ExtendedImageGestureState state) {
    final pointerDownPosition = state.pointerDownPosition;
    final double begin = state.gestureDetails!.totalScale!;
    final double end = (begin == _doubleTapScales[0])
        ? _doubleTapScales[1]
        : _doubleTapScales[0];

    if (_doubleTapListener != null) {
      _doubleTapAnimation?.removeListener(_doubleTapListener!);
    }
    _doubleTapController
      ..stop()
      ..reset();

    _doubleTapAnimation = _doubleTapController.drive(
      Tween<double>(begin: begin, end: end),
    );
    _doubleTapListener = () {
      state.handleDoubleTap(
        scale: _doubleTapAnimation!.value,
        doubleTapPosition: pointerDownPosition,
      );
    };
    _doubleTapAnimation!.addListener(_doubleTapListener!);
    _doubleTapController.forward();
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
                  child: ExtendedImage.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.gesture,
                    enableSlideOutPage: true,
                    onDoubleTap: _onDoubleTap,
                    initGestureConfigHandler: (state) => GestureConfig(
                      minScale: 1.0,
                      maxScale: 4.0,
                      animationMinScale: 0.9,
                      animationMaxScale: 4.5,
                      initialScale: 1.0,
                      inPageView: false,
                      cacheGesture: false,
                      initialAlignment: InitialAlignment.center,
                    ),
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
