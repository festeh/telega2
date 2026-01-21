import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/events/message_events.dart';
import '../../data/repositories/tdlib_telegram_client.dart';
import 'telegram_client_provider.dart';

enum DownloadStatus { downloading, failed, completed }

class FileDownloadState {
  final double progress;
  final DownloadStatus status;

  const FileDownloadState({
    this.progress = 0.0,
    this.status = DownloadStatus.downloading,
  });

  FileDownloadState copyWith({
    double? progress,
    DownloadStatus? status,
  }) {
    return FileDownloadState(
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

class DownloadProgressState {
  final Map<int, FileDownloadState> stateByFileId;

  const DownloadProgressState({this.stateByFileId = const {}});

  FileDownloadState? getState(int fileId) => stateByFileId[fileId];

  DownloadProgressState updateProgress(int fileId, double progress) {
    final newMap = Map<int, FileDownloadState>.from(stateByFileId);
    newMap[fileId] = FileDownloadState(
      progress: progress,
      status: DownloadStatus.downloading,
    );
    return DownloadProgressState(stateByFileId: newMap);
  }

  DownloadProgressState setFailed(int fileId) {
    final newMap = Map<int, FileDownloadState>.from(stateByFileId);
    newMap[fileId] = const FileDownloadState(
      progress: 0.0,
      status: DownloadStatus.failed,
    );
    return DownloadProgressState(stateByFileId: newMap);
  }

  DownloadProgressState remove(int fileId) {
    final newMap = Map<int, FileDownloadState>.from(stateByFileId);
    newMap.remove(fileId);
    return DownloadProgressState(stateByFileId: newMap);
  }
}

class DownloadProgressNotifier extends Notifier<DownloadProgressState> {
  StreamSubscription<MessageEvent>? _messageEventSubscription;
  StreamSubscription<FileDownloadComplete>? _fileDownloadSubscription;

  @override
  DownloadProgressState build() {
    _subscribeToEvents();
    ref.onDispose(() {
      _messageEventSubscription?.cancel();
      _fileDownloadSubscription?.cancel();
    });
    return const DownloadProgressState();
  }

  void _subscribeToEvents() {
    final client = ref.read(telegramClientProvider);
    if (client is TdlibTelegramClient) {
      // Listen to message events for progress and failures
      _messageEventSubscription = client.messageEvents.listen((event) {
        if (event is FileDownloadProgressEvent) {
          state = state.updateProgress(event.fileId, event.progress);
        } else if (event is FileDownloadFailedEvent) {
          state = state.setFailed(event.fileId);
        }
      });

      // Listen to file download completions
      _fileDownloadSubscription = client.fileDownloads.listen((event) {
        state = state.remove(event.fileId);
      });
    }
  }

  void retryDownload(int fileId) {
    final client = ref.read(telegramClientProvider);
    // Reset state to downloading
    state = state.updateProgress(fileId, 0.0);
    // Re-trigger download
    client.downloadFile(fileId);
  }
}

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, DownloadProgressState>(
  () => DownloadProgressNotifier(),
);

// Extension methods for convenient access
extension DownloadProgressX on WidgetRef {
  FileDownloadState? watchFileDownloadState(int? fileId) {
    if (fileId == null) return null;
    return watch(
      downloadProgressProvider.select((state) => state.getState(fileId)),
    );
  }

  void retryDownload(int fileId) {
    read(downloadProgressProvider.notifier).retryDownload(fileId);
  }
}
