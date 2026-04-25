import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/motion.dart';
import '../../domain/entities/chat.dart';
import '../emoji_sticker/telegram_emoji_widget.dart';

/// A single reaction pill with press feedback. The pill scales up slightly and
/// flashes a primary tint while the user holds it down — short, bounded by
/// [kAppearanceTransitionDuration], skipped under reduced-motion.
class ReactionChip extends StatefulWidget {
  const ReactionChip({
    super.key,
    required this.reaction,
    required this.onTap,
  });

  final MessageReaction reaction;
  final VoidCallback? onTap;

  @override
  State<ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<ReactionChip> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reaction = widget.reaction;
    final isChosen = reaction.isChosen;
    final disabled = widget.onTap == null;
    final duration = motionDurationFor(context, kAppearanceTransitionDuration);

    final restingFill = isChosen
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final pressedFill = colorScheme.primary.withValues(alpha: 0.18);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapUp: disabled
          ? null
          : (_) {
              _setPressed(false);
              widget.onTap!();
            },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 1.08 : 1.0,
        duration: duration,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _pressed ? pressedFill : restingFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChosen
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionGlyph(reaction: reaction),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                  color: isChosen
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the icon/emoji portion of a reaction chip — emoji widget,
/// downloaded custom emoji image, loading spinner, or fallback icon.
class ReactionGlyph extends StatelessWidget {
  const ReactionGlyph({super.key, required this.reaction});

  final MessageReaction reaction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if ((reaction.type == ReactionType.emoji ||
            reaction.type == ReactionType.paid) &&
        reaction.emoji != null) {
      return TelegramEmojiWidget(
        emoji: reaction.emoji!,
        size: 16,
        animated: false,
      );
    }
    if (reaction.type == ReactionType.customEmoji &&
        reaction.customEmojiPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.file(
          File(reaction.customEmojiPath!),
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.emoji_emotions,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    if (reaction.type == ReactionType.customEmoji) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      );
    }
    return Icon(
      Icons.emoji_emotions,
      size: 14,
      color: colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }
}
