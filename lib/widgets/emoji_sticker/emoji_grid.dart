import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/widgets/emoji_sticker/telegram_emoji_widget.dart';

/// A grid widget that displays emojis using custom Telegram-style rendering
class EmojiGrid extends ConsumerWidget {
  /// List of emojis to display
  final List<Emoji> emojis;

  /// Number of columns in the grid
  final int columns;

  /// Size of each emoji
  final double emojiSize;

  /// Callback when an emoji is tapped
  final void Function(Emoji emoji)? onEmojiSelected;

  /// Whether to animate animated emojis
  final bool animateEmojis;

  /// Padding around the grid
  final EdgeInsets padding;

  /// Spacing between emoji cells
  final double spacing;

  const EmojiGrid({
    super.key,
    required this.emojis,
    this.columns = 8,
    this.emojiSize = 32.0,
    this.onEmojiSelected,
    this.animateEmojis = false,
    this.padding = const EdgeInsets.all(8.0),
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (emojis.isEmpty) {
      return const Center(
        child: Text('No emojis', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return _EmojiGridItem(
          emoji: emoji,
          size: emojiSize,
          animated: animateEmojis,
          onTap: () => onEmojiSelected?.call(emoji),
        );
      },
    );
  }
}

/// A single emoji item in the grid
class _EmojiGridItem extends StatelessWidget {
  final Emoji emoji;
  final double size;
  final bool animated;
  final VoidCallback? onTap;

  const _EmojiGridItem({
    required this.emoji,
    required this.size,
    required this.animated,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: TelegramEmojiWidget(
            emoji: emoji.char,
            size: size,
            animated: animated,
          ),
        ),
      ),
    );
  }
}
