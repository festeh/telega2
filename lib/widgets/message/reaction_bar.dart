import 'package:flutter/material.dart';
import 'package:telega2/widgets/emoji_sticker/telegram_emoji_widget.dart';

/// Displays a horizontal bar of quick reaction emojis
/// Uses custom Telegram-style emoji rendering for consistent display
class ReactionBar extends StatelessWidget {
  final List<String> reactions;
  final Function(String) onReactionSelected;
  final double emojiSize;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onReactionSelected,
    this.emojiSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: reactions.map((emoji) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onReactionSelected(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TelegramEmojiWidget(
                    emoji: emoji,
                    size: emojiSize,
                    animated: false,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
