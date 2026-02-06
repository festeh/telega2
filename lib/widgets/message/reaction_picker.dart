import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/widgets/emoji_sticker/telegram_emoji_widget.dart';
import 'package:telega2/widgets/emoji_sticker/custom_emoji_picker.dart';

/// Default quick reactions shown in the reaction picker
const List<String> defaultQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

/// A compact reaction picker showing quick reactions with an expand button
/// Used in message context menus for quick emoji reactions
class ReactionPicker extends ConsumerStatefulWidget {
  /// Callback when a reaction is selected
  final void Function(String emoji) onReactionSelected;

  /// Callback when expand button is pressed (to show full picker)
  final VoidCallback? onExpandPressed;

  /// Quick reactions to display
  final List<String> quickReactions;

  /// Size of each emoji
  final double emojiSize;

  /// Background color
  final Color? backgroundColor;

  /// Whether this picker is shown inline or as overlay
  final bool isOverlay;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.onExpandPressed,
    this.quickReactions = defaultQuickReactions,
    this.emojiSize = 32.0,
    this.backgroundColor,
    this.isOverlay = true,
  });

  @override
  ConsumerState<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends ConsumerState<ReactionPicker> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = widget.backgroundColor ?? colorScheme.surfaceContainerHigh;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      elevation: widget.isOverlay ? 8 : 0,
      shadowColor: Colors.black26,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reaction emojis
            ...widget.quickReactions.map(
              (emoji) => _buildReactionButton(emoji),
            ),

            // Expand button
            if (widget.onExpandPressed != null) ...[
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              _buildExpandButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onReactionSelected(emoji),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: TelegramEmojiWidget(
            emoji: emoji,
            size: widget.emojiSize,
            animated: false,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onExpandPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.add_circle_outline,
            size: widget.emojiSize,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A full-screen reaction picker that shows after expanding
/// Shows the CustomEmojiPicker for selecting any emoji as reaction
class ExpandedReactionPicker extends StatelessWidget {
  /// Callback when a reaction is selected
  final void Function(String emoji) onReactionSelected;

  /// Callback when picker is closed
  final VoidCallback? onClose;

  const ExpandedReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Choose reaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Emoji picker
          SizedBox(
            height: 350,
            child: CustomEmojiPicker(
              onEmojiSelected: (emoji) {
                onReactionSelected(emoji);
                onClose?.call();
              },
              showBackspace: false,
              showSearch: true,
              showRecents: true,
              columns: 8,
              emojiSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Show the expanded picker as a modal bottom sheet
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpandedReactionPicker(
        onReactionSelected: (emoji) => Navigator.pop(context, emoji),
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
