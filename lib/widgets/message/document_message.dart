import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../presentation/providers/download_progress_provider.dart';
import '../../presentation/providers/telegram_client_provider.dart';

class DocumentMessageWidget extends ConsumerStatefulWidget {
  final String? documentPath;
  final int? documentFileId;
  final String? fileName;
  final String? mimeType;
  final int? size;
  final bool isOutgoing;

  const DocumentMessageWidget({
    super.key,
    this.documentPath,
    this.documentFileId,
    this.fileName,
    this.mimeType,
    this.size,
    required this.isOutgoing,
  });

  @override
  ConsumerState<DocumentMessageWidget> createState() =>
      _DocumentMessageWidgetState();
}

class _DocumentMessageWidgetState extends ConsumerState<DocumentMessageWidget> {
  bool _saved = false;
  String? _saveError;

  String get _displayName => widget.fileName ?? 'Document';

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    if (mimeType.startsWith('video/')) return Icons.videocam;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Icons.folder_zip;
    }
    if (mimeType.contains('text')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _saveToDownloads() async {
    final path = widget.documentPath;
    if (path == null) return;

    try {
      // Get Downloads directory
      final String downloadsPath;
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download';
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'] ?? '/home';
        downloadsPath = '$home/Downloads';
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? '/Users';
        downloadsPath = '$home/Downloads';
      } else {
        downloadsPath = Directory.systemTemp.path;
      }

      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final targetName = widget.fileName ?? p.basename(path);
      var targetFile = File(p.join(downloadsPath, targetName));

      // Avoid overwriting: add (1), (2), etc.
      if (await targetFile.exists()) {
        final nameWithoutExt = p.basenameWithoutExtension(targetName);
        final ext = p.extension(targetName);
        var counter = 1;
        do {
          targetFile = File(
            p.join(downloadsPath, '$nameWithoutExt ($counter)$ext'),
          );
          counter++;
        } while (await targetFile.exists());
      }

      await File(path).copy(targetFile.path);
      if (mounted) {
        setState(() {
          _saved = true;
          _saveError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveError = e.toString());
      }
    }
  }

  void _startDownload() {
    final fileId = widget.documentFileId;
    if (fileId == null) return;
    ref.read(telegramClientProvider).downloadFile(fileId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloadState = ref.watchFileDownloadState(widget.documentFileId);
    final isDownloaded = widget.documentPath != null;
    final isDownloading =
        downloadState?.status == DownloadStatus.downloading;
    final hasFailed = downloadState?.status == DownloadStatus.failed;

    final contentColor =
        widget.isOutgoing ? colorScheme.onPrimary : colorScheme.onSurface;
    final subtitleColor = contentColor.withValues(alpha: 0.6);

    return InkWell(
      onTap: isDownloading
          ? null
          : isDownloaded
              ? _saveToDownloads
              : _startDownload,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon or progress
            _buildIcon(
              colorScheme,
              contentColor,
              isDownloaded,
              isDownloading,
              hasFailed,
              downloadState?.progress ?? 0,
            ),
            const SizedBox(width: 10),
            // File info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: contentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_formatSize(widget.size).isNotEmpty || _saved)
                    Text(
                      _saved
                          ? 'Saved to Downloads'
                          : _saveError != null
                              ? 'Save failed'
                              : _formatSize(widget.size),
                      style: TextStyle(
                        fontSize: 13,
                        color: _saved
                            ? Colors.green
                            : _saveError != null
                                ? Colors.red
                                : subtitleColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
    ColorScheme colorScheme,
    Color contentColor,
    bool isDownloaded,
    bool isDownloading,
    bool hasFailed,
    double progress,
  ) {
    if (isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: progress > 0 ? progress : null,
          strokeWidth: 2.5,
          color: contentColor,
        ),
      );
    }

    if (hasFailed) {
      return Icon(Icons.error_outline, size: 40, color: Colors.red);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: contentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isDownloaded
            ? _iconForMimeType(widget.mimeType)
            : Icons.download,
        size: 22,
        color: contentColor,
      ),
    );
  }
}
