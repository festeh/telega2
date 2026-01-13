import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for emoji animations
class EmojiAnimationState {
  /// Whether animations are globally enabled
  final bool animationsEnabled;

  /// Whether animations should auto-play
  final bool autoPlay;

  /// Whether to pause animations when app is in background
  final bool pauseInBackground;

  /// Whether app is currently in foreground
  final bool isInForeground;

  /// Whether device is in battery saver mode
  final bool isBatterySaving;

  const EmojiAnimationState({
    this.animationsEnabled = true,
    this.autoPlay = true,
    this.pauseInBackground = true,
    this.isInForeground = true,
    this.isBatterySaving = false,
  });

  /// Whether animations should currently play
  bool get shouldAnimate {
    if (!animationsEnabled) return false;
    if (isBatterySaving) return false;
    if (pauseInBackground && !isInForeground) return false;
    return autoPlay;
  }

  EmojiAnimationState copyWith({
    bool? animationsEnabled,
    bool? autoPlay,
    bool? pauseInBackground,
    bool? isInForeground,
    bool? isBatterySaving,
  }) {
    return EmojiAnimationState(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      autoPlay: autoPlay ?? this.autoPlay,
      pauseInBackground: pauseInBackground ?? this.pauseInBackground,
      isInForeground: isInForeground ?? this.isInForeground,
      isBatterySaving: isBatterySaving ?? this.isBatterySaving,
    );
  }
}

/// Notifier for managing emoji animation state
class EmojiAnimationNotifier extends Notifier<EmojiAnimationState> {
  @override
  EmojiAnimationState build() {
    return const EmojiAnimationState();
  }

  /// Enable or disable all animations
  void setAnimationsEnabled(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
  }

  /// Enable or disable auto-play
  void setAutoPlay(bool autoPlay) {
    state = state.copyWith(autoPlay: autoPlay);
  }

  /// Enable or disable pause in background
  void setPauseInBackground(bool pause) {
    state = state.copyWith(pauseInBackground: pause);
  }

  /// Update foreground state (call from app lifecycle observer)
  void setInForeground(bool inForeground) {
    state = state.copyWith(isInForeground: inForeground);
  }

  /// Update battery saver state
  void setBatterySaving(bool saving) {
    state = state.copyWith(isBatterySaving: saving);
  }
}

/// Provider for emoji animation state
final emojiAnimationProvider =
    NotifierProvider<EmojiAnimationNotifier, EmojiAnimationState>(
  EmojiAnimationNotifier.new,
);

/// Provider for whether animations should play
final shouldAnimateEmojisProvider = Provider<bool>((ref) {
  return ref.watch(emojiAnimationProvider).shouldAnimate;
});
