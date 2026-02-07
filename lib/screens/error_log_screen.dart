import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../core/logging/error_log_buffer.dart';
import '../presentation/providers/app_providers.dart';

class ErrorLogScreen extends ConsumerStatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  ConsumerState<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends ConsumerState<ErrorLogScreen> {
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    // Mark all errors as seen when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorLogBuffer.instance.markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(errorLogProvider); // rebuild on changes
    final buffer = ErrorLogBuffer.instance;
    final entries = buffer.entries;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Error Log (${entries.length})'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              onPressed: () => ErrorLogBuffer.instance.clear(),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No errors logged',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isExpanded = _expandedIndices.contains(index);
                final hasDetails =
                    entry.error != null || entry.stackTrace != null;

                return _buildEntryTile(
                  entry,
                  index,
                  isExpanded,
                  hasDetails,
                  colorScheme,
                );
              },
            ),
    );
  }

  Widget _buildEntryTile(
    ErrorLogEntry entry,
    int index,
    bool isExpanded,
    bool hasDetails,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: hasDetails
          ? () => setState(() {
                if (isExpanded) {
                  _expandedIndices.remove(index);
                } else {
                  _expandedIndices.add(index);
                }
              })
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: level badge, module, timestamp
            Row(
              children: [
                _buildLevelBadge(entry.level, colorScheme),
                if (entry.module != null) ...[
                  const SizedBox(width: 8),
                  _buildModuleTag(entry.module!, colorScheme),
                ],
                const Spacer(),
                Text(
                  _formatTimestamp(entry.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                  ),
                ),
                if (hasDetails) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Message
            Text(
              entry.message,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
            // Expanded details
            if (isExpanded) ...[
              if (entry.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    entry.error!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              if (entry.stackTrace != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    entry.stackTrace!,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(Level level, ColorScheme colorScheme) {
    final (label, color) = switch (level) {
      Level.warning => ('WARN', Colors.orange),
      Level.error => ('ERROR', colorScheme.error),
      Level.fatal => ('FATAL', Colors.red.shade900),
      _ => (level.name.toUpperCase(), colorScheme.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildModuleTag(String module, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        module,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    return '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';
  }
}
