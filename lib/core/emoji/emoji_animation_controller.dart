import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controller for managing emoji animation behavior
/// Handles battery saver detection and performance optimization
class EmojiAnimationController {
  static final EmojiAnimationController _instance =
      EmojiAnimationController._internal();
  factory EmojiAnimationController() => _instance;
  EmojiAnimationController._internal();

  final _batterySaverController = StreamController<bool>.broadcast();
  bool _isBatterySaving = false;
  bool _initialized = false;

  /// Stream of battery saver state changes
  Stream<bool> get batterySaverStream => _batterySaverController.stream;

  /// Current battery saver state
  bool get isBatterySaving => _isBatterySaving;

  /// Initialize the controller
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Check initial battery saver state
    await _checkBatterySaver();

    // On Android, we could use battery_plus package for real detection
    // For now, we'll use a simple approach
  }

  /// Check if battery saver is enabled
  Future<void> _checkBatterySaver() async {
    try {
      if (Platform.isAndroid) {
        // On Android, check power save mode via method channel
        // This is a simplified implementation
        // Real implementation would use battery_plus or similar package
        const channel = MethodChannel('flutter.native/battery');
        try {
          final isPowerSaveMode =
              await channel.invokeMethod<bool>('isPowerSaveMode') ?? false;
          _updateBatterySaver(isPowerSaveMode);
        } on MissingPluginException {
          // Plugin not available, assume not in power save mode
          _updateBatterySaver(false);
        }
      } else if (Platform.isIOS) {
        // iOS low power mode detection would go here
        _updateBatterySaver(false);
      } else {
        // Desktop platforms don't typically have battery saver
        _updateBatterySaver(false);
      }
    } catch (e) {
      debugPrint('Error checking battery saver: $e');
      _updateBatterySaver(false);
    }
  }

  void _updateBatterySaver(bool isSaving) {
    if (_isBatterySaving != isSaving) {
      _isBatterySaving = isSaving;
      _batterySaverController.add(isSaving);
    }
  }

  /// Manually set battery saver state (for testing or manual override)
  void setBatterySaver(bool isSaving) {
    _updateBatterySaver(isSaving);
  }

  /// Dispose resources
  void dispose() {
    _batterySaverController.close();
  }
}

/// Configuration for emoji animations
class EmojiAnimationConfig {
  /// Maximum number of concurrent animated emojis
  final int maxConcurrentAnimations;

  /// Whether to reduce animation quality when many emojis are visible
  final bool reduceQualityWhenBusy;

  /// Threshold for "many emojis" (triggers quality reduction)
  final int busyThreshold;

  /// Frame rate limit for animations (0 = no limit)
  final int frameRateLimit;

  const EmojiAnimationConfig({
    this.maxConcurrentAnimations = 10,
    this.reduceQualityWhenBusy = true,
    this.busyThreshold = 5,
    this.frameRateLimit = 0,
  });

  /// Default configuration
  static const EmojiAnimationConfig defaultConfig = EmojiAnimationConfig();

  /// Low power configuration (for battery saver mode)
  static const EmojiAnimationConfig lowPower = EmojiAnimationConfig(
    maxConcurrentAnimations: 3,
    reduceQualityWhenBusy: true,
    busyThreshold: 2,
    frameRateLimit: 30,
  );
}

/// Tracks visible animated emojis for performance optimization
class AnimatedEmojiTracker {
  final Set<String> _visibleAnimatedEmojis = {};
  final int _maxVisible;

  AnimatedEmojiTracker({int maxVisible = 10}) : _maxVisible = maxVisible;

  /// Register an animated emoji as visible
  /// Returns true if animation should play, false if limit exceeded
  bool registerVisible(String id) {
    if (_visibleAnimatedEmojis.length >= _maxVisible) {
      return false;
    }
    _visibleAnimatedEmojis.add(id);
    return true;
  }

  /// Unregister an animated emoji
  void unregisterVisible(String id) {
    _visibleAnimatedEmojis.remove(id);
  }

  /// Current count of visible animated emojis
  int get visibleCount => _visibleAnimatedEmojis.length;

  /// Whether limit is exceeded
  bool get isOverLimit => _visibleAnimatedEmojis.length >= _maxVisible;

  /// Clear all tracked emojis
  void clear() {
    _visibleAnimatedEmojis.clear();
  }
}
