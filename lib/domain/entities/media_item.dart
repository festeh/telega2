/// Encapsulates a local media file to be sent as a message.
class MediaItem {
  final String path;
  final bool isVideo;
  final int? width;
  final int? height;

  const MediaItem({
    required this.path,
    this.isVideo = false,
    this.width,
    this.height,
  });
}
