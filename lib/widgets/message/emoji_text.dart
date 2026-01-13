import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_utils.dart';
import 'package:telega2/widgets/emoji_sticker/telegram_emoji_widget.dart';

/// A text widget that replaces emoji characters with custom Telegram-style emoji images
/// Falls back to native emoji rendering if custom assets are not available
class EmojiText extends ConsumerWidget {
  /// The text to display (may contain emojis)
  final String text;

  /// Base text style
  final TextStyle? style;

  /// Size for emoji images (defaults to font size if not specified)
  final double? emojiSize;

  /// Whether to animate animated emojis
  final bool animateEmojis;

  /// Text alignment
  final TextAlign textAlign;

  /// Maximum number of lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow overflow;

  /// Whether text is selectable
  final bool selectable;

  const EmojiText({
    super.key,
    required this.text,
    this.style,
    this.emojiSize,
    this.animateEmojis = true,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if text contains emojis
    if (!containsEmoji(text)) {
      return _buildPlainText();
    }

    // Check if message is only emojis (for large emoji display)
    final emojiOnlyCount = getOnlyEmojiCount(text);
    if (emojiOnlyCount > 0 && emojiOnlyCount <= 3) {
      return _buildLargeEmojiOnly(emojiOnlyCount);
    }

    // Build rich text with inline emoji widgets
    return _buildRichText(context);
  }

  Widget _buildPlainText() {
    if (selectable) {
      return SelectableText(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildLargeEmojiOnly(int count) {
    // Display large emojis when message is only emojis
    final emojis = findEmojis(text).map((m) => m.group(0)!).toList();
    final largeSize = _getLargeEmojiSize(count);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: emojis
          .map((emoji) => TelegramEmojiWidget(
                emoji: emoji,
                size: largeSize,
                animated: false,
              ))
          .toList(),
    );
  }

  double _getLargeEmojiSize(int count) {
    switch (count) {
      case 1:
        return 64.0;
      case 2:
        return 48.0;
      case 3:
        return 40.0;
      default:
        return 32.0;
    }
  }

  Widget _buildRichText(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveEmojiSize = emojiSize ?? (effectiveStyle.fontSize ?? 14.0);

    final segments = splitTextWithEmojis(text);
    final spans = <InlineSpan>[];

    for (final segment in segments) {
      if (segment.isEmoji) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TelegramEmojiWidget(
            emoji: segment.text,
            size: effectiveEmojiSize,
            animated: false,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: segment.text,
          style: effectiveStyle,
        ));
      }
    }

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A simpler version that doesn't use Riverpod (for non-async rendering)
/// Uses native emoji fallback immediately without attempting to load custom assets
class SimpleEmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? emojiSize;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const SimpleEmojiText({
    super.key,
    required this.text,
    this.style,
    this.emojiSize,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    // For simple version, just render text normally
    // Custom emoji rendering happens via TelegramEmojiWidget's fallback
    if (!containsEmoji(text)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveEmojiSize = emojiSize ?? (effectiveStyle.fontSize ?? 14.0);

    final segments = splitTextWithEmojis(text);
    final spans = <InlineSpan>[];

    for (final segment in segments) {
      if (segment.isEmoji) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: StaticEmojiWidget(
            emoji: segment.text,
            size: effectiveEmojiSize,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: segment.text,
          style: effectiveStyle,
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
