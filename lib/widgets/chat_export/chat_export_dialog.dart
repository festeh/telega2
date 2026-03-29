import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/chat_export_provider.dart';

class ChatExportDialog extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatExportDialog({super.key, required this.chat});

  @override
  ConsumerState<ChatExportDialog> createState() => _ChatExportDialogState();
}

class _ChatExportDialogState extends ConsumerState<ChatExportDialog> {
  DateTimeRange? _selectedRange;
  bool _pickingDates = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDatePicker();
    });
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2013), // Telegram launch year
      lastDate: now,
      initialDateRange: DateTimeRange(start: thirtyDaysAgo, end: now),
      helpText: 'Select date range to export',
      saveText: 'Select',
    );

    if (!mounted) return;

    if (picked == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _selectedRange = picked;
      _pickingDates = false;
    });
  }

  void _startExport() {
    if (_selectedRange == null) return;

    // Set toDate to end of day
    final toDate = DateTime(
      _selectedRange!.end.year,
      _selectedRange!.end.month,
      _selectedRange!.end.day,
      23, 59, 59,
    );

    ref.read(chatExportProvider.notifier).exportChat(
      chatId: widget.chat.id,
      chatTitle: widget.chat.title,
      chatType: widget.chat.type,
      fromDate: _selectedRange!.start,
      toDate: toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(chatExportProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');

    if (_pickingDates) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(
        exportState.status == ChatExportStatus.done
            ? 'Export Complete'
            : exportState.status == ChatExportStatus.error
                ? 'Export Failed'
                : 'Export Chat',
      ),
      content: _buildContent(exportState, colorScheme, dateFormat),
      actions: _buildActions(exportState),
    );
  }

  Widget _buildContent(
    ChatExportState exportState,
    ColorScheme colorScheme,
    DateFormat dateFormat,
  ) {
    switch (exportState.status) {
      case ChatExportStatus.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat: ${widget.chat.title}'),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(_selectedRange!.start)} — ${dateFormat.format(_selectedRange!.end)}',
              style: TextStyle(color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Messages in this range will be exported as JSON to your Downloads folder.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );

      case ChatExportStatus.exporting:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching and exporting messages...'),
            SizedBox(height: 8),
          ],
        );

      case ChatExportStatus.done:
        final fileName = exportState.filePath?.split('/').last ?? 'export.json';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('${exportState.exportedCount} messages exported'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fileName,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );

      case ChatExportStatus.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Export failed')),
              ],
            ),
            if (exportState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                exportState.errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        );
    }
  }

  List<Widget> _buildActions(ChatExportState exportState) {
    switch (exportState.status) {
      case ChatExportStatus.idle:
        return [
          TextButton(
            onPressed: () {
              ref.read(chatExportProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _startExport,
            child: const Text('Export'),
          ),
        ];

      case ChatExportStatus.exporting:
        return [];

      case ChatExportStatus.done:
        return [
          FilledButton(
            onPressed: () {
              ref.read(chatExportProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ];

      case ChatExportStatus.error:
        return [
          TextButton(
            onPressed: () {
              ref.read(chatExportProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: _startExport,
            child: const Text('Retry'),
          ),
        ];
    }
  }
}
