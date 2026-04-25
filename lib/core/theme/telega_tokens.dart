import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'appearance.dart';

/// Density-resolved layout tokens shared by the home (chat list) and chat
/// surfaces. Read via `Theme.of(context).extension<TelegaTokens>()!`.
///
/// Density-dependent values live here. Density-invariant constants
/// (icon sizes, gesture thresholds, fully-rounded radius) stay in
/// `lib/core/constants/ui_constants.dart`.
@immutable
class TelegaTokens extends ThemeExtension<TelegaTokens> {
  const TelegaTokens({
    required this.gapXs,
    required this.gapSm,
    required this.gapMd,
    required this.gapLg,
    required this.gapXl,
    required this.listRowVerticalPadding,
    required this.bubbleVerticalPadding,
    required this.bubbleHorizontalPadding,
    required this.bubbleGutterWide,
    required this.bubbleGutterNarrow,
    required this.composerVerticalPadding,
    required this.chatListAvatarSize,
    required this.bodyFontScale,
    required this.bubbleStyle,
    required this.chatBackground,
    required this.incomingBubbleFill,
    required this.minTouchTarget,
  });

  final double gapXs;
  final double gapSm;
  final double gapMd;
  final double gapLg;
  final double gapXl;

  final double listRowVerticalPadding;
  final double bubbleVerticalPadding;
  final double bubbleHorizontalPadding;
  /// Empty space on the *opposite* side of a bubble (away from the screen edge
  /// the bubble sits against). Keeps message bubbles from spanning the full
  /// width of the chat — preserves the readable column.
  final double bubbleGutterWide;
  /// Empty space on the *near* side of a bubble.
  final double bubbleGutterNarrow;
  final double composerVerticalPadding;

  final double chatListAvatarSize;
  final double bodyFontScale;

  final BubbleStyle bubbleStyle;
  final ChatBackground chatBackground;
  final IncomingBubbleFill incomingBubbleFill;

  final double minTouchTarget;

  /// Resolve tokens for the given user [settings].
  factory TelegaTokens.from(AppearanceSettings settings) {
    final compact = settings.density == Density.compact;
    return TelegaTokens(
      gapXs: compact ? 3 : 4,
      gapSm: compact ? 6 : 8,
      gapMd: compact ? 10 : 12,
      gapLg: compact ? 14 : 16,
      gapXl: compact ? 20 : 24,
      listRowVerticalPadding: compact ? 8 : 12,
      bubbleVerticalPadding: compact ? 6 : 8,
      bubbleHorizontalPadding: compact ? 10 : 12,
      bubbleGutterWide: compact ? 40 : 50,
      bubbleGutterNarrow: compact ? 8 : 10,
      composerVerticalPadding: compact ? 6 : 10,
      chatListAvatarSize: compact ? 40 : 50,
      bodyFontScale: compact ? 0.94 : 1.0,
      bubbleStyle: settings.bubble,
      chatBackground: settings.chatBackground,
      incomingBubbleFill: settings.incomingBubbleFill,
      minTouchTarget: 44.0,
    );
  }

  /// Border radius for a message bubble in the active style.
  /// `classicTail` carves a 4-radius corner on the trailing side
  /// (right for outgoing, left for incoming) so the bubble reads as tailed.
  BorderRadius bubbleRadius({required bool isOutgoing}) {
    switch (bubbleStyle) {
      case BubbleStyle.classicTail:
        return isOutgoing
            ? const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              );
      case BubbleStyle.flatRounded:
        return BorderRadius.circular(12);
      case BubbleStyle.minimalLine:
        return BorderRadius.circular(8);
    }
  }

  /// Clamp a visual size to the minimum touch target. Used to ensure
  /// Compact density does not drop hit areas below 44×44.
  double clampToTouchTarget(double size) =>
      size < minTouchTarget ? minTouchTarget : size;

  @override
  TelegaTokens copyWith({
    double? gapXs,
    double? gapSm,
    double? gapMd,
    double? gapLg,
    double? gapXl,
    double? listRowVerticalPadding,
    double? bubbleVerticalPadding,
    double? bubbleHorizontalPadding,
    double? bubbleGutterWide,
    double? bubbleGutterNarrow,
    double? composerVerticalPadding,
    double? chatListAvatarSize,
    double? bodyFontScale,
    BubbleStyle? bubbleStyle,
    ChatBackground? chatBackground,
    IncomingBubbleFill? incomingBubbleFill,
    double? minTouchTarget,
  }) {
    return TelegaTokens(
      gapXs: gapXs ?? this.gapXs,
      gapSm: gapSm ?? this.gapSm,
      gapMd: gapMd ?? this.gapMd,
      gapLg: gapLg ?? this.gapLg,
      gapXl: gapXl ?? this.gapXl,
      listRowVerticalPadding:
          listRowVerticalPadding ?? this.listRowVerticalPadding,
      bubbleVerticalPadding:
          bubbleVerticalPadding ?? this.bubbleVerticalPadding,
      bubbleHorizontalPadding:
          bubbleHorizontalPadding ?? this.bubbleHorizontalPadding,
      bubbleGutterWide: bubbleGutterWide ?? this.bubbleGutterWide,
      bubbleGutterNarrow: bubbleGutterNarrow ?? this.bubbleGutterNarrow,
      composerVerticalPadding:
          composerVerticalPadding ?? this.composerVerticalPadding,
      chatListAvatarSize: chatListAvatarSize ?? this.chatListAvatarSize,
      bodyFontScale: bodyFontScale ?? this.bodyFontScale,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      chatBackground: chatBackground ?? this.chatBackground,
      incomingBubbleFill: incomingBubbleFill ?? this.incomingBubbleFill,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
    );
  }

  @override
  TelegaTokens lerp(ThemeExtension<TelegaTokens>? other, double t) {
    if (other is! TelegaTokens) return this;
    return TelegaTokens(
      gapXs: ui.lerpDouble(gapXs, other.gapXs, t)!,
      gapSm: ui.lerpDouble(gapSm, other.gapSm, t)!,
      gapMd: ui.lerpDouble(gapMd, other.gapMd, t)!,
      gapLg: ui.lerpDouble(gapLg, other.gapLg, t)!,
      gapXl: ui.lerpDouble(gapXl, other.gapXl, t)!,
      listRowVerticalPadding: ui.lerpDouble(
        listRowVerticalPadding,
        other.listRowVerticalPadding,
        t,
      )!,
      bubbleVerticalPadding: ui.lerpDouble(
        bubbleVerticalPadding,
        other.bubbleVerticalPadding,
        t,
      )!,
      bubbleHorizontalPadding: ui.lerpDouble(
        bubbleHorizontalPadding,
        other.bubbleHorizontalPadding,
        t,
      )!,
      bubbleGutterWide: ui.lerpDouble(
        bubbleGutterWide,
        other.bubbleGutterWide,
        t,
      )!,
      bubbleGutterNarrow: ui.lerpDouble(
        bubbleGutterNarrow,
        other.bubbleGutterNarrow,
        t,
      )!,
      composerVerticalPadding: ui.lerpDouble(
        composerVerticalPadding,
        other.composerVerticalPadding,
        t,
      )!,
      chatListAvatarSize: ui.lerpDouble(
        chatListAvatarSize,
        other.chatListAvatarSize,
        t,
      )!,
      bodyFontScale: ui.lerpDouble(bodyFontScale, other.bodyFontScale, t)!,
      bubbleStyle: t < 0.5 ? bubbleStyle : other.bubbleStyle,
      chatBackground: t < 0.5 ? chatBackground : other.chatBackground,
      incomingBubbleFill:
          t < 0.5 ? incomingBubbleFill : other.incomingBubbleFill,
      minTouchTarget: ui.lerpDouble(minTouchTarget, other.minTouchTarget, t)!,
    );
  }
}
