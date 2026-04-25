import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/core/theme/appearance.dart';
import 'package:telega2/core/theme/telega_tokens.dart';

final _comfortable = AppearanceSettings.defaults;
final _compact = AppearanceSettings.defaults.copyWith(density: Density.compact);

void main() {
  group('TelegaTokens density resolution', () {
    test('Compact tightens every density-dependent value', () {
      final wide = TelegaTokens.from(_comfortable);
      final tight = TelegaTokens.from(_compact);

      // Spacing scale tightens.
      expect(tight.gapXs, lessThan(wide.gapXs));
      expect(tight.gapSm, lessThan(wide.gapSm));
      expect(tight.gapMd, lessThan(wide.gapMd));
      expect(tight.gapLg, lessThan(wide.gapLg));
      expect(tight.gapXl, lessThan(wide.gapXl));

      // Row + bubble paddings tighten.
      expect(
        tight.listRowVerticalPadding,
        lessThan(wide.listRowVerticalPadding),
      );
      expect(
        tight.bubbleVerticalPadding,
        lessThan(wide.bubbleVerticalPadding),
      );
      expect(
        tight.bubbleHorizontalPadding,
        lessThan(wide.bubbleHorizontalPadding),
      );
      expect(tight.bubbleGutterWide, lessThan(wide.bubbleGutterWide));
      expect(tight.bubbleGutterNarrow, lessThan(wide.bubbleGutterNarrow));
      expect(
        tight.composerVerticalPadding,
        lessThan(wide.composerVerticalPadding),
      );

      // Avatar shrinks by one defined step.
      expect(tight.chatListAvatarSize, lessThan(wide.chatListAvatarSize));

      // Body font scale drops.
      expect(tight.bodyFontScale, lessThan(wide.bodyFontScale));
      expect(wide.bodyFontScale, 1.0);
    });

    test('Comfortable matches the existing baseline values', () {
      final wide = TelegaTokens.from(_comfortable);
      // Locks the current visual rhythm so a future "polish" of token values
      // surfaces as an explicit test failure rather than a silent shift.
      expect(wide.gapXs, 4);
      expect(wide.gapSm, 8);
      expect(wide.gapMd, 12);
      expect(wide.gapLg, 16);
      expect(wide.gapXl, 24);
      expect(wide.listRowVerticalPadding, 12);
      expect(wide.bubbleVerticalPadding, 8);
      expect(wide.bubbleHorizontalPadding, 12);
      expect(wide.bubbleGutterWide, 50);
      expect(wide.bubbleGutterNarrow, 10);
      expect(wide.chatListAvatarSize, 50);
      expect(wide.bodyFontScale, 1.0);
    });

    test('minTouchTarget is the WCAG 44px floor regardless of density', () {
      expect(TelegaTokens.from(_comfortable).minTouchTarget, 44.0);
      expect(TelegaTokens.from(_compact).minTouchTarget, 44.0);
    });

    test('clampToTouchTarget enforces 44px minimum', () {
      final tokens = TelegaTokens.from(_compact);
      expect(tokens.clampToTouchTarget(20), 44.0);
      expect(tokens.clampToTouchTarget(44), 44.0);
      expect(tokens.clampToTouchTarget(56), 56.0);
    });
  });

  group('TelegaTokens.bubbleRadius', () {
    TelegaTokens tokensFor(BubbleStyle style) =>
        TelegaTokens.from(AppearanceSettings.defaults.copyWith(bubble: style));

    test('classicTail: outgoing carves the bottom-right corner', () {
      final radius = tokensFor(BubbleStyle.classicTail)
          .bubbleRadius(isOutgoing: true);
      expect(radius.topLeft, const Radius.circular(18));
      expect(radius.topRight, const Radius.circular(18));
      expect(radius.bottomLeft, const Radius.circular(18));
      expect(radius.bottomRight, const Radius.circular(4));
    });

    test('classicTail: incoming carves the bottom-left corner', () {
      final radius = tokensFor(BubbleStyle.classicTail)
          .bubbleRadius(isOutgoing: false);
      expect(radius.topLeft, const Radius.circular(18));
      expect(radius.topRight, const Radius.circular(18));
      expect(radius.bottomLeft, const Radius.circular(4));
      expect(radius.bottomRight, const Radius.circular(18));
    });

    test('flatRounded: 12 on every corner, both sides', () {
      final out =
          tokensFor(BubbleStyle.flatRounded).bubbleRadius(isOutgoing: true);
      final inc =
          tokensFor(BubbleStyle.flatRounded).bubbleRadius(isOutgoing: false);
      expect(out, BorderRadius.circular(12));
      expect(inc, BorderRadius.circular(12));
    });

    test('minimalLine: 8 on every corner, both sides', () {
      final out =
          tokensFor(BubbleStyle.minimalLine).bubbleRadius(isOutgoing: true);
      final inc =
          tokensFor(BubbleStyle.minimalLine).bubbleRadius(isOutgoing: false);
      expect(out, BorderRadius.circular(8));
      expect(inc, BorderRadius.circular(8));
    });
  });

  group('TelegaTokens.lerp', () {
    test('snaps bubbleStyle at t=0.5 boundary', () {
      final classic = TelegaTokens.from(_comfortable);
      final flat = TelegaTokens.from(
        AppearanceSettings.defaults.copyWith(bubble: BubbleStyle.flatRounded),
      );
      expect(
        classic.lerp(flat, 0.49).bubbleStyle,
        BubbleStyle.classicTail,
      );
      expect(
        classic.lerp(flat, 0.51).bubbleStyle,
        BubbleStyle.flatRounded,
      );
    });

    test('linearly interpolates double fields', () {
      final wide = TelegaTokens.from(_comfortable);
      final tight = TelegaTokens.from(_compact);
      final mid = wide.lerp(tight, 0.5);
      expect(mid.gapMd, (wide.gapMd + tight.gapMd) / 2);
      expect(
        mid.chatListAvatarSize,
        (wide.chatListAvatarSize + tight.chatListAvatarSize) / 2,
      );
    });
  });
}
