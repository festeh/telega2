import 'package:flutter/material.dart';
import 'package:telega2/widgets/emoji_sticker/custom_emoji_picker.dart';

/// Emoji tab widget that displays the custom Telegram-style emoji picker
/// Uses CustomEmojiPicker for consistent emoji rendering across platforms
class EmojiTab extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback? onEmojiSelected;

  const EmojiTab({
    super.key,
    required this.textController,
    this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomEmojiPicker(
      textController: textController,
      onEmojiSelected: (emoji) {
        onEmojiSelected?.call();
      },
      columns: 8,
      emojiSize: 28,
      showBackspace: true,
      showSearch: true,
      showRecents: true,
    );
  }
}
