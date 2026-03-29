import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/chat.dart';
import 'telegram_client_provider.dart';

enum ChatExportStatus { idle, exporting, done, error }

class ChatExportState {
  final ChatExportStatus status;
  final String? filePath;
  final String? errorMessage;
  final int exportedCount;

  const ChatExportState({
    this.status = ChatExportStatus.idle,
    this.filePath,
    this.errorMessage,
    this.exportedCount = 0,
  });

  ChatExportState copyWith({
    ChatExportStatus? status,
    String? filePath,
    String? errorMessage,
    int? exportedCount,
  }) {
    return ChatExportState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      exportedCount: exportedCount ?? this.exportedCount,
    );
  }
}

class ChatExportNotifier extends Notifier<ChatExportState> {
  @override
  ChatExportState build() => const ChatExportState();

  void reset() => state = const ChatExportState();

  Future<void> exportChat({
    required int chatId,
    required String chatTitle,
    required ChatType chatType,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    state = const ChatExportState(status: ChatExportStatus.exporting);

    try {
      final client = ref.read(telegramClientProvider);
      final messages = await client.loadMessagesInRange(
        chatId,
        fromDate,
        toDate,
      );

      final exportData = {
        'chat': {
          'id': chatId,
          'title': chatTitle,
          'type': chatType.name,
        },
        'exportDate': DateTime.now().toUtc().toIso8601String(),
        'dateRange': {
          'from': fromDate.toUtc().toIso8601String(),
          'to': toDate.toUtc().toIso8601String(),
        },
        'messageCount': messages.length,
        'messages': messages.map((m) => m.toExportJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final filePath = await _saveToDownloads(chatTitle, fromDate, toDate, jsonString);

      state = ChatExportState(
        status: ChatExportStatus.done,
        filePath: filePath,
        exportedCount: messages.length,
      );
    } catch (e) {
      state = ChatExportState(
        status: ChatExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String> _saveToDownloads(
    String chatTitle,
    DateTime fromDate,
    DateTime toDate,
    String content,
  ) async {
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

    // Sanitize chat title for filename
    final safeName = chatTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final fromStr = '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
    final toStr = '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';
    final baseName = '${safeName}_${fromStr}_$toStr';

    var targetFile = File(p.join(downloadsPath, '$baseName.json'));

    // Avoid overwriting
    if (await targetFile.exists()) {
      var counter = 1;
      do {
        targetFile = File(p.join(downloadsPath, '$baseName ($counter).json'));
        counter++;
      } while (await targetFile.exists());
    }

    await targetFile.writeAsString(content);
    return targetFile.path;
  }
}

final chatExportProvider =
    NotifierProvider<ChatExportNotifier, ChatExportState>(
      () => ChatExportNotifier(),
    );
