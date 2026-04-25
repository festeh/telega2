import 'package:flutter/material.dart';

/// Curated accent presets. Every value's [color] meets ≥ 4.5:1 contrast on the
/// dark surface (#1C1C1E) — verified by `test/core/theme/contrast_test.dart`.
enum AccentPreset {
  telegramBlue(Color(0xFF3390EC)),
  indigo(Color(0xFF818CF8)),
  teal(Color(0xFF2DD4BF)),
  magenta(Color(0xFFE879F9)),
  amber(Color(0xFFFBBF24)),
  crimson(Color(0xFFFB7185)),
  emerald(Color(0xFF34D399));

  const AccentPreset(this.color);
  final Color color;
}

/// Three message-bubble shape variants the user can choose between.
enum BubbleStyle { classicTail, flatRounded, minimalLine }

/// Two list/typography density values. Compact tightens spacing, shrinks
/// chat-list avatars by one step, and reduces the body font scale —
/// without dropping interactive elements below the 44×44 hit-area floor.
enum Density { comfortable, compact }

/// Solid-color background presets for the chat content area (the surface
/// behind message bubbles). Resolved at use site via [resolve] so options
/// can either be static colors or computed from the active [ColorScheme].
enum ChatBackground {
  defaultDark,
  deepDark,
  softDark,
  midnightBlue,
  forestNight,
  plumNight,
}

extension ChatBackgroundResolver on ChatBackground {
  Color resolve(ColorScheme cs) {
    switch (this) {
      case ChatBackground.defaultDark:
        return cs.surface;
      case ChatBackground.deepDark:
        return const Color(0xFF0A0A0C);
      case ChatBackground.softDark:
        return const Color(0xFF222228);
      case ChatBackground.midnightBlue:
        return const Color(0xFF0F1428);
      case ChatBackground.forestNight:
        return const Color(0xFF0F1A14);
      case ChatBackground.plumNight:
        return const Color(0xFF1A1424);
    }
  }
}

/// Fill style for *incoming* (received) message bubbles. Outgoing bubbles
/// always fill with the accent color. This knob is independent of
/// [BubbleStyle] except that [BubbleStyle.minimalLine] forces an outlined
/// look on both sides regardless of this choice.
enum IncomingBubbleFill { standard, subtle, accentTint, outlined }

extension IncomingBubbleFillResolver on IncomingBubbleFill {
  /// Resolves to the bubble fill color. Returns transparent for [outlined];
  /// callers should pair [outlined] with a visible border.
  Color resolve(ColorScheme cs) {
    switch (this) {
      case IncomingBubbleFill.standard:
        return cs.surfaceContainerHighest;
      case IncomingBubbleFill.subtle:
        return cs.surfaceContainer;
      case IncomingBubbleFill.accentTint:
        return cs.primary.withValues(alpha: 0.18);
      case IncomingBubbleFill.outlined:
        return Colors.transparent;
    }
  }

  bool get drawsBorder => this == IncomingBubbleFill.outlined;
}

/// User-controlled appearance state. Persisted across restarts.
@immutable
class AppearanceSettings {
  const AppearanceSettings({
    required this.accent,
    required this.bubble,
    required this.density,
    required this.chatBackground,
    required this.incomingBubbleFill,
  });

  final AccentPreset accent;
  final BubbleStyle bubble;
  final Density density;
  final ChatBackground chatBackground;
  final IncomingBubbleFill incomingBubbleFill;

  static const AppearanceSettings defaults = AppearanceSettings(
    accent: AccentPreset.telegramBlue,
    bubble: BubbleStyle.classicTail,
    density: Density.comfortable,
    chatBackground: ChatBackground.defaultDark,
    incomingBubbleFill: IncomingBubbleFill.standard,
  );

  AppearanceSettings copyWith({
    AccentPreset? accent,
    BubbleStyle? bubble,
    Density? density,
    ChatBackground? chatBackground,
    IncomingBubbleFill? incomingBubbleFill,
  }) {
    return AppearanceSettings(
      accent: accent ?? this.accent,
      bubble: bubble ?? this.bubble,
      density: density ?? this.density,
      chatBackground: chatBackground ?? this.chatBackground,
      incomingBubbleFill: incomingBubbleFill ?? this.incomingBubbleFill,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearanceSettings &&
          other.accent == accent &&
          other.bubble == bubble &&
          other.density == density &&
          other.chatBackground == chatBackground &&
          other.incomingBubbleFill == incomingBubbleFill;

  @override
  int get hashCode => Object.hash(
        accent,
        bubble,
        density,
        chatBackground,
        incomingBubbleFill,
      );

  @override
  String toString() =>
      'AppearanceSettings(accent: ${accent.name}, '
      'bubble: ${bubble.name}, density: ${density.name}, '
      'chatBackground: ${chatBackground.name}, '
      'incomingBubbleFill: ${incomingBubbleFill.name})';
}
