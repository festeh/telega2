import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants/ui_constants.dart';

/// media_kit's hardware-accelerated texture path renders incorrectly on Linux
/// (video turns solid blue after the first frame), so we force software
/// rendering there. Other platforms keep hardware acceleration for
/// battery/performance.
VideoControllerConfiguration videoControllerConfig() {
  if (Platform.isLinux) {
    return const VideoControllerConfiguration(
      enableHardwareAcceleration: false,
    );
  }
  return const VideoControllerConfiguration();
}

/// Creates a [Player] with platform-appropriate codec settings.
///
/// On Linux, libmpv probes VDPAU/CUDA/Vulkan/VAAPI before falling back to
/// software decoding, spamming stderr on machines without those drivers.
/// Forcing `hwdec=no` skips the probe and silences the failures.
Player createPlayer() {
  final player = Player();
  if (Platform.isLinux) {
    final platform = player.platform;
    if (platform is NativePlayer) {
      platform.setProperty('hwdec', 'no');
    }
  }
  return player;
}

/// Calculates display dimensions for media content while maintaining aspect ratio.
///
/// Returns (width, height) tuple constrained to max dimensions.
/// Falls back to default dimensions if source size is invalid.
(double, double) calculateMediaDimensions({
  int? width,
  int? height,
  double maxWidth = MediaSize.maxWidth,
  double maxHeight = MediaSize.maxHeight,
  double defaultWidth = MediaSize.defaultWidth,
  double defaultHeight = MediaSize.defaultHeight,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return (defaultWidth, defaultHeight);
  }

  final aspectRatio = width / height;
  double displayWidth;
  double displayHeight;

  if (aspectRatio > 1) {
    // Landscape
    displayWidth = maxWidth;
    displayHeight = maxWidth / aspectRatio;
    if (displayHeight > maxHeight) {
      displayHeight = maxHeight;
      displayWidth = maxHeight * aspectRatio;
    }
  } else {
    // Portrait or square
    displayHeight = maxHeight;
    displayWidth = maxHeight * aspectRatio;
    if (displayWidth > maxWidth) {
      displayWidth = maxWidth;
      displayHeight = maxWidth / aspectRatio;
    }
  }

  return (displayWidth, displayHeight);
}
