import 'package:logger/logger.dart';

import 'log_level.dart';
import 'tdlib_log_level.dart';

/// Per-subsystem log verbosity, parsed from an environment variable in the
/// style of `RUST_LOG`.
///
/// Grammar (`,`-separated tokens):
///   - bare level token (e.g. `info`) → sets the default level
///   - `module=level` (e.g. `messages=debug`) → overrides one subsystem
///   - `bridge.native=level` → sets the native (C++) bridge level
///
/// Module names accept `bridge` and `tdlib` as aliases, plus `perf` for
/// `performance`. Level names match `package:logger`'s level names exactly:
/// `trace`, `debug`, `info`, `warning`, `error`, `fatal`.
///
/// Warnings encountered during parsing accumulate in [parseWarnings] so the
/// caller can surface them after the logger itself is initialized.
class LogFilterConfig {
  final Level defaultLevel;
  final Map<LogModule, Level> overrides;
  final TdLibLogLevel? nativeLevel;
  final List<String> parseWarnings;

  const LogFilterConfig({
    required this.defaultLevel,
    this.overrides = const {},
    this.nativeLevel,
    this.parseWarnings = const [],
  });

  Level effectiveLevelFor(LogModule module) =>
      overrides[module] ?? defaultLevel;

  /// Build a config from a raw env-var value. `null` or empty input yields the
  /// fallback default with no overrides.
  static LogFilterConfig parse(
    String? value, {
    required Level fallbackDefault,
  }) {
    if (value == null || value.trim().isEmpty) {
      return LogFilterConfig(defaultLevel: fallbackDefault);
    }

    Level defaultLevel = fallbackDefault;
    final overrides = <LogModule, Level>{};
    TdLibLogLevel? nativeLevel;
    final warnings = <String>[];

    for (final raw in value.split(',')) {
      final token = raw.trim();
      if (token.isEmpty) continue;

      final eq = token.indexOf('=');
      if (eq == -1) {
        // Bare level → default.
        final level = _parseLevel(token);
        if (level == null) {
          warnings.add('TELEGA_LOG: unknown level "$token", ignored');
          continue;
        }
        defaultLevel = level;
        continue;
      }

      final key = token.substring(0, eq).trim().toLowerCase();
      final valuePart = token.substring(eq + 1).trim();

      if (key == 'bridge.native') {
        final native = _parseNativeLevel(valuePart);
        if (native == null) {
          warnings.add(
            'TELEGA_LOG: unknown native level "$valuePart" for bridge.native, ignored',
          );
          continue;
        }
        nativeLevel = native;
        continue;
      }

      final module = _parseModule(key);
      if (module == null) {
        warnings.add('TELEGA_LOG: unknown module "$key", ignored');
        continue;
      }
      final level = _parseLevel(valuePart);
      if (level == null) {
        warnings.add(
          'TELEGA_LOG: unknown level "$valuePart" for module "$key", ignored',
        );
        continue;
      }
      overrides[module] = level;
    }

    return LogFilterConfig(
      defaultLevel: defaultLevel,
      overrides: overrides,
      nativeLevel: nativeLevel,
      parseWarnings: warnings,
    );
  }

  static Level? _parseLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'trace':
        return Level.trace;
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      case 'fatal':
        return Level.fatal;
      default:
        return null;
    }
  }

  static LogModule? _parseModule(String raw) {
    switch (raw) {
      case 'auth':
        return LogModule.auth;
      case 'tdlib':
      case 'bridge':
        return LogModule.tdlib;
      case 'messages':
        return LogModule.messages;
      case 'chats':
        return LogModule.chats;
      case 'network':
        return LogModule.network;
      case 'storage':
        return LogModule.storage;
      case 'ui':
        return LogModule.ui;
      case 'performance':
      case 'perf':
        return LogModule.performance;
      case 'general':
        return LogModule.general;
      default:
        return null;
    }
  }

  static TdLibLogLevel? _parseNativeLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'fatal':
        return TdLibLogLevel.fatal;
      case 'error':
        return TdLibLogLevel.error;
      case 'warning':
        return TdLibLogLevel.warning;
      case 'info':
        return TdLibLogLevel.info;
      case 'debug':
        return TdLibLogLevel.debug;
      case 'verbose':
        return TdLibLogLevel.verbose;
      default:
        return null;
    }
  }
}
