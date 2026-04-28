import 'dart:collection';

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

/// In-memory ring buffer that captures warning/error/fatal log entries plus a
/// short trail of recent info breadcrumbs that surround them.
///
/// Call [onChanged] after mutating to notify external listeners (e.g. riverpod).
class ErrorLogBuffer {
  static final ErrorLogBuffer instance = ErrorLogBuffer._();

  static const int maxEntries = 200;
  static const int maxBreadcrumbs = 20;

  final List<ErrorLogEntry> _entries = [];
  final Queue<ErrorLogEntry> _breadcrumbs = Queue();
  int _unseenCount = 0;

  /// Set by the riverpod provider to trigger UI rebuilds.
  void Function()? onChanged;

  ErrorLogBuffer._();

  /// Entries newest first.
  List<ErrorLogEntry> get entries => _entries.reversed.toList();

  /// Recent info-level breadcrumbs, newest first.
  List<ErrorLogEntry> get breadcrumbs => _breadcrumbs.toList().reversed.toList();

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

  /// Append an info entry to the breadcrumb ring. Older entries drop off when
  /// the ring exceeds [maxBreadcrumbs]. Breadcrumbs do not bump the unseen
  /// count and do not notify listeners — they are read alongside errors.
  void addBreadcrumb(ErrorLogEntry entry) {
    _breadcrumbs.addLast(entry);
    while (_breadcrumbs.length > maxBreadcrumbs) {
      _breadcrumbs.removeFirst();
    }
  }

  void markSeen() {
    if (_unseenCount > 0) {
      _unseenCount = 0;
      onChanged?.call();
    }
  }

  void clear() {
    _entries.clear();
    _breadcrumbs.clear();
    _unseenCount = 0;
    onChanged?.call();
  }
}
