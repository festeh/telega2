import 'package:logger/logger.dart';

class ErrorLogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final String? module;
  final String? error;
  final String? stackTrace;

  const ErrorLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.module,
    this.error,
    this.stackTrace,
  });
}

/// In-memory ring buffer that captures warning/error/fatal log entries.
///
/// Call [onChanged] after mutating to notify external listeners (e.g. riverpod).
class ErrorLogBuffer {
  static final ErrorLogBuffer instance = ErrorLogBuffer._();

  static const int maxEntries = 200;

  final List<ErrorLogEntry> _entries = [];
  int _unseenCount = 0;

  /// Set by the riverpod provider to trigger UI rebuilds.
  void Function()? onChanged;

  ErrorLogBuffer._();

  /// Entries newest first.
  List<ErrorLogEntry> get entries => _entries.reversed.toList();

  int get length => _entries.length;

  int get unseenCount => _unseenCount;

  void add(ErrorLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    _unseenCount++;
    onChanged?.call();
  }

  void markSeen() {
    if (_unseenCount > 0) {
      _unseenCount = 0;
      onChanged?.call();
    }
  }

  void clear() {
    _entries.clear();
    _unseenCount = 0;
    onChanged?.call();
  }
}
