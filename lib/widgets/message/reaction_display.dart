import 'package:flutter/material.dart';
import 'package:telega2/widgets/emoji_sticker/telegram_emoji_widget.dart';

/// Represents a single reaction with count
class ReactionData {
  final String emoji;
  final int count;
  final bool isSelected;

  const ReactionData({
    required this.emoji,
    required this.count,
    this.isSelected = false,
  });
}

/// Displays reactions on a message using custom Telegram-style emoji rendering
/// Shows emoji with count, and highlights the user's own reaction
class ReactionDisplay extends StatelessWidget {
  /// List of reactions with counts
  final List<ReactionData> reactions;

  /// Callback when a reaction is tapped (to toggle it)
  final void Function(String emoji)? onReactionTapped;

  /// Size of each emoji
  final double emojiSize;

  /// Whether to align reactions to the end (for outgoing messages)
  final bool alignEnd;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    this.onReactionTapped,
    this.emojiSize = 16.0,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: reactions.map((reaction) {
          return _ReactionChip(
            reaction: reaction,
            emojiSize: emojiSize,
            onTap: onReactionTapped != null
                ? () => onReactionTapped!(reaction.emoji)
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// A single reaction chip showing emoji and count
class _ReactionChip extends StatelessWidget {
  final ReactionData reaction;
  final double emojiSize;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.reaction,
    required this.emojiSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: reaction.isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TelegramEmojiWidget(
                emoji: reaction.emoji,
                size: emojiSize,
                animated: false,
              ),
              if (reaction.count > 1) ...[
                const SizedBox(width: 2),
                Text(
                  '${reaction.count}',
                  style: TextStyle(
                    fontSize: emojiSize * 0.75,
                    fontWeight: FontWeight.w500,
                    color: reaction.isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact reaction display for message previews (chat list)
class CompactReactionDisplay extends StatelessWidget {
  /// List of reaction emojis (without counts)
  final List<String> reactions;

  /// Maximum number of reactions to show
  final int maxVisible;

  /// Size of each emoji
  final double emojiSize;

  const CompactReactionDisplay({
    super.key,
    required this.reactions,
    this.maxVisible = 3,
    this.emojiSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final visibleReactions = reactions.take(maxVisible).toList();
    final remaining = reactions.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleReactions.map((emoji) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: TelegramEmojiWidget(
                emoji: emoji,
                size: emojiSize,
                animated: false,
              ),
            )),
        if (remaining > 0)
          Text(
            '+$remaining',
            style: TextStyle(
              fontSize: emojiSize * 0.8,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// A row showing reactions in a message bubble
/// Positioned at the bottom of the message content
class MessageReactionsRow extends StatelessWidget {
  /// Map of emoji to reaction data
  final Map<String, ReactionData> reactions;

  /// Callback when a reaction is tapped
  final void Function(String emoji)? onReactionTapped;

  /// Whether this is an outgoing message
  final bool isOutgoing;

  const MessageReactionsRow({
    super.key,
    required this.reactions,
    this.onReactionTapped,
    this.isOutgoing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReactionDisplay(
      reactions: reactions.values.toList(),
      onReactionTapped: onReactionTapped,
      emojiSize: 16.0,
      alignEnd: isOutgoing,
    );
  }
}
