import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'log_filter_config.dart';
import 'log_level.dart';
import 'error_log_buffer.dart';
import 'formatters/console_formatter.dart';

export 'log_level.dart' show LogContext, LogModule;

class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();

  late Logger _logger;
  LogContext? _globalContext;
  LogFilterConfig _filter = const LogFilterConfig(defaultLevel: Level.info);

  AppLogger._();

  LogFilterConfig get filter => _filter;

  Future<void> initialize({
    LogFilterConfig? filter,
    LogContext? globalContext,
    bool enableFileLogging = false,
    String? logDirectory,
  }) async {
    _globalContext = globalContext;
    _filter = filter ??
        LogFilterConfig(
          defaultLevel: kDebugMode ? Level.info : Level.warning,
        );

    final outputs = <LogOutput>[];

    // Always add console output in debug mode
    if (kDebugMode) {
      outputs.add(ConsoleOutput());
    }

    // Add file output if enabled or in release mode
    if (enableFileLogging || kReleaseMode) {
      try {
        final fileOutput = await _createFileOutput(logDirectory);
        if (fileOutput != null) {
          outputs.add(fileOutput);
        }
      } catch (e) {
        // If file output fails, continue without it
        debugPrint('Failed to create file output: $e');
      }
    }

    // Underlying logger lets every level through; the per-module gate inside
    // [_log] decides what is actually emitted.
    _logger = Logger(
      level: Level.trace,
      printer: _createPrinter(),
      output: outputs.length == 1 ? outputs.first : MultiOutput(outputs),
    );
  }

  LogPrinter _createPrinter() {
    return ConsoleFormatter(
      includeEmojis: false,
      includeTimestamp: true,
      includeModule: true,
    );
  }

  Future<FileOutput?> _createFileOutput(String? customDirectory) async {
    try {
      final Directory appDir;
      if (customDirectory != null) {
        appDir = Directory(customDirectory);
      } else {
        appDir = await getApplicationDocumentsDirectory();
      }

      final logDir = Directory(path.join(appDir.path, 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFile = File(
        path.join(
          logDir.path,
          'app_${DateTime.now().toIso8601String().split('T')[0]}.log',
        ),
      );

      return FileOutput(file: logFile);
    } catch (e) {
      return null;
    }
  }

  void _log(
    Level level,
    dynamic message, {
    LogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final effectiveContext = context ?? _globalContext;
    final module = effectiveContext?.module ?? LogModule.general;

    // Errors and warnings always emit; lower levels go through the per-module
    // gate so a muted subsystem stays silent.
    final isCritical = level.index >= Level.warning.index;
    if (!isCritical) {
      final effectiveLevel = _filter.effectiveLevelFor(module);
      if (level.index < effectiveLevel.index) {
        return;
      }
    }

    final logMessage = effectiveContext != null
        ? {
            'message': message,
            'module': effectiveContext.module.name,
            'context': effectiveContext.toMap(),
          }
        : message;

    _logger.log(level, logMessage, error: error, stackTrace: stackTrace);

    final messageStr = message is Map
        ? (message['message'] ?? message.toString()).toString()
        : message.toString();
    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: messageStr,
      module: effectiveContext?.module.name,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    if (isCritical) {
      ErrorLogBuffer.instance.add(entry);
    } else if (level == Level.info) {
      ErrorLogBuffer.instance.addBreadcrumb(entry);
    }
  }

  void trace(dynamic message, {LogContext? context}) {
    _log(Level.trace, message, context: context);
  }

  void debug(dynamic message, {LogContext? context}) {
    _log(Level.debug, message, context: context);
  }

  void info(dynamic message, {LogContext? context}) {
    _log(Level.info, message, context: context);
  }

  void warning(dynamic message, {LogContext? context, Object? error}) {
    _log(Level.warning, message, context: context, error: error);
  }

  void error(
    dynamic message, {
    LogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      Level.error,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    dynamic message, {
    LogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      Level.fatal,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Convenience methods for different modules
  void authLog(
    Level level,
    dynamic message, {
    String? userId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final context = LogContext(
      module: LogModule.auth,
      userId: userId,
      metadata: metadata,
    );
    _log(
      level,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void tdlibLog(
    Level level,
    dynamic message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final context = LogContext(
      module: LogModule.tdlib,
      requestId: requestId,
      metadata: metadata,
    );
    _log(
      level,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void networkLog(
    Level level,
    dynamic message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final context = LogContext(
      module: LogModule.network,
      requestId: requestId,
      metadata: metadata,
    );
    _log(
      level,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void performanceLog(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final context = LogContext(
      module: LogModule.performance,
      metadata: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        ...?metadata,
      },
    );
    _log(
      Level.info,
      'Performance: $operation took ${duration.inMilliseconds}ms',
      context: context,
    );
  }

  void setGlobalContext(LogContext context) {
    _globalContext = context;
  }

  void clearGlobalContext() {
    _globalContext = null;
  }

  /// Returns a logger handle that bakes [module] into every emitted entry, so
  /// callers can write `_logger.debug(msg)` without repeating context.
  ScopedLogger scoped(LogModule module) => ScopedLogger._(this, module);

  void close() {
    _logger.close();
  }
}

/// Module-scoped wrapper around [AppLogger]. Each call routes through the same
/// per-module gate as direct [AppLogger] calls, but the module is fixed once at
/// the call site that obtained the scope.
class ScopedLogger {
  final AppLogger _base;
  final LogModule _module;

  const ScopedLogger._(this._base, this._module);

  LogContext _ctx() => LogContext(module: _module);

  void trace(dynamic message) =>
      _base._log(Level.trace, message, context: _ctx());

  void debug(dynamic message) =>
      _base._log(Level.debug, message, context: _ctx());

  void info(dynamic message) =>
      _base._log(Level.info, message, context: _ctx());

  void warning(dynamic message, {Object? error}) =>
      _base._log(Level.warning, message, context: _ctx(), error: error);

  void error(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _base._log(
        Level.error,
        message,
        context: _ctx(),
        error: error,
        stackTrace: stackTrace,
      );

  void fatal(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _base._log(
        Level.fatal,
        message,
        context: _ctx(),
        error: error,
        stackTrace: stackTrace,
      );
}
