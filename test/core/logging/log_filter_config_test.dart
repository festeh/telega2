import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:telega2/core/logging/log_filter_config.dart';
import 'package:telega2/core/logging/log_level.dart';
import 'package:telega2/core/logging/tdlib_log_level.dart';

void main() {
  group('LogFilterConfig.parse', () {
    test('null input falls back to provided default with no overrides', () {
      final config = LogFilterConfig.parse(null, fallbackDefault: Level.info);

      expect(config.defaultLevel, Level.info);
      expect(config.overrides, isEmpty);
      expect(config.nativeLevel, isNull);
      expect(config.parseWarnings, isEmpty);
    });

    test('empty input falls back to provided default with no overrides', () {
      final config = LogFilterConfig.parse(
        '   ',
        fallbackDefault: Level.warning,
      );

      expect(config.defaultLevel, Level.warning);
      expect(config.overrides, isEmpty);
      expect(config.parseWarnings, isEmpty);
    });

    test('bare token sets the default level', () {
      final config = LogFilterConfig.parse(
        'debug',
        fallbackDefault: Level.warning,
      );

      expect(config.defaultLevel, Level.debug);
      expect(config.overrides, isEmpty);
    });

    test('module=level adds an override and keeps the fallback default', () {
      final config = LogFilterConfig.parse(
        'messages=debug',
        fallbackDefault: Level.info,
      );

      expect(config.defaultLevel, Level.info);
      expect(config.overrides, {LogModule.messages: Level.debug});
    });

    test('default + multiple overrides parse together', () {
      final config = LogFilterConfig.parse(
        'info,bridge=trace,messages=debug,chats=warning',
        fallbackDefault: Level.warning,
      );

      expect(config.defaultLevel, Level.info);
      expect(config.overrides, {
        LogModule.tdlib: Level.trace,
        LogModule.messages: Level.debug,
        LogModule.chats: Level.warning,
      });
      expect(config.parseWarnings, isEmpty);
    });

    test('bridge and tdlib are aliases for the same subsystem', () {
      final viaBridge = LogFilterConfig.parse(
        'bridge=trace',
        fallbackDefault: Level.info,
      );
      final viaTdlib = LogFilterConfig.parse(
        'tdlib=trace',
        fallbackDefault: Level.info,
      );

      expect(viaBridge.overrides, {LogModule.tdlib: Level.trace});
      expect(viaTdlib.overrides, {LogModule.tdlib: Level.trace});
    });

    test('perf is an alias for the performance module', () {
      final config = LogFilterConfig.parse(
        'perf=debug',
        fallbackDefault: Level.info,
      );

      expect(config.overrides, {LogModule.performance: Level.debug});
    });

    test('bridge.native maps to a TdLibLogLevel', () {
      final config = LogFilterConfig.parse(
        'info,bridge.native=warning',
        fallbackDefault: Level.info,
      );

      expect(config.nativeLevel, TdLibLogLevel.warning);
      expect(config.overrides, isEmpty);
    });

    test('unknown level on default token falls back and warns', () {
      final config = LogFilterConfig.parse(
        'verbose-plus',
        fallbackDefault: Level.info,
      );

      expect(config.defaultLevel, Level.info);
      expect(config.parseWarnings, hasLength(1));
      expect(config.parseWarnings.single, contains('verbose-plus'));
    });

    test('unknown module produces a warning and is ignored', () {
      final config = LogFilterConfig.parse(
        'bogus=trace',
        fallbackDefault: Level.info,
      );

      expect(config.overrides, isEmpty);
      expect(config.parseWarnings, hasLength(1));
      expect(config.parseWarnings.single, contains('bogus'));
    });

    test('unknown level on a known module produces a warning', () {
      final config = LogFilterConfig.parse(
        'messages=loud',
        fallbackDefault: Level.info,
      );

      expect(config.overrides, isEmpty);
      expect(config.parseWarnings, hasLength(1));
      expect(config.parseWarnings.single, contains('loud'));
    });

    test('whitespace and empty tokens are tolerated', () {
      final config = LogFilterConfig.parse(
        ' info , , messages = debug ',
        fallbackDefault: Level.warning,
      );

      expect(config.defaultLevel, Level.info);
      expect(config.overrides, {LogModule.messages: Level.debug});
      expect(config.parseWarnings, isEmpty);
    });

    test('later override for the same module wins', () {
      final config = LogFilterConfig.parse(
        'messages=info,messages=trace',
        fallbackDefault: Level.warning,
      );

      expect(config.overrides, {LogModule.messages: Level.trace});
    });
  });

  group('LogFilterConfig.effectiveLevelFor', () {
    test('returns override when present, otherwise the default', () {
      final config = LogFilterConfig.parse(
        'info,messages=trace',
        fallbackDefault: Level.warning,
      );

      expect(config.effectiveLevelFor(LogModule.messages), Level.trace);
      expect(config.effectiveLevelFor(LogModule.chats), Level.info);
      expect(config.effectiveLevelFor(LogModule.tdlib), Level.info);
    });
  });
}
