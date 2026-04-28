import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'app_logger.dart';
import 'log_filter_config.dart';
import 'log_level.dart';
import 'tdlib_log_level.dart';

class LoggingConfig {
  static const String envVarName = 'TELEGA_LOG';

  static TdLibLogLevel? _tdlibLogLevel;
  static LogFilterConfig _filter = const LogFilterConfig(
    defaultLevel: Level.info,
  );

  /// Get the current TDLib log level
  static TdLibLogLevel get tdlibLogLevel =>
      _tdlibLogLevel ?? TdLibLogLevel.getDefault(kDebugMode, kReleaseMode);

  /// The active log filter (default level + per-module overrides).
  static LogFilterConfig get filter => _filter;

  static Future<void> initialize({TdLibLogLevel? tdlibLogLevel}) async {
    final fallbackDefault = kDebugMode
        ? Level.info
        : (kProfileMode ? Level.info : Level.warning);

    final envValue = _readEnvVar();
    _filter = LogFilterConfig.parse(envValue, fallbackDefault: fallbackDefault);

    // Native (TDLib C++) level: explicit env override wins, otherwise the
    // caller's preference, otherwise the build-mode default.
    _tdlibLogLevel = _filter.nativeLevel ??
        tdlibLogLevel ??
        TdLibLogLevel.getDefault(kDebugMode, kReleaseMode);

    final enableFileLogging = !kDebugMode;
    String? logDirectory;
    if (enableFileLogging) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        logDirectory = path.join(
          appDir.path,
          'telegram_flutter_client',
          'logs',
        );
      } catch (_) {
        // Fall through — file output disabled if the directory lookup fails.
      }
    }

    final globalContext = LogContext(
      module: LogModule.general,
      metadata: {
        'app_version': '1.0.0',
        'build_mode': kDebugMode
            ? 'debug'
            : (kProfileMode ? 'profile' : 'release'),
        'platform': defaultTargetPlatform.name,
      },
    );

    await AppLogger.instance.initialize(
      filter: _filter,
      globalContext: globalContext,
      enableFileLogging: enableFileLogging,
      logDirectory: logDirectory,
    );

    // Surface parse warnings now that the logger is up.
    for (final warning in _filter.parseWarnings) {
      AppLogger.instance.warning(
        warning,
        context: const LogContext(module: LogModule.general),
      );
    }

    AppLogger.instance.info(
      'Logging system initialized',
      context: LogContext(
        module: LogModule.general,
        metadata: {
          'default_level': _filter.defaultLevel.name,
          'overrides': _filter.overrides.map(
            (module, level) => MapEntry(module.name, level.name),
          ),
          'env_var': envValue,
          'tdlib_log_level': tdlibLogLevel.toString(),
          'file_logging': enableFileLogging,
          'log_directory': logDirectory,
        },
      ),
    );
  }

  static Future<void> configureForTesting() async {
    _filter = const LogFilterConfig(defaultLevel: Level.debug);
    await AppLogger.instance.initialize(
      filter: _filter,
      enableFileLogging: false,
      globalContext: const LogContext(
        module: LogModule.general,
        metadata: {'environment': 'test'},
      ),
    );
  }

  static String? _readEnvVar() {
    try {
      return Platform.environment[envVarName];
    } catch (_) {
      // Some platforms (web) don't allow env access; treat as unset.
      return null;
    }
  }

  static void shutdown() {
    AppLogger.instance.close();
  }
}
