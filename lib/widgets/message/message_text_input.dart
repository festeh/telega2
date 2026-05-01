import 'package:flutter/material.dart';

/// Reusable text input chrome for the message composer.
///
/// Owns no domain state — just renders a rounded TextField with an emoji
/// suffix button and forwards submit/emoji-tap events to the parent.
///
/// Keystroke-derived state (e.g. multiline) is computed via
/// [ValueListenableBuilder] on the controller so we don't rebuild the whole
/// row per character. The Android selection-handle overlay was getting
/// dislodged by full-row rebuilds in the previous implementation.
class MessageTextInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool enabled;
  final VoidCallback? onSubmit;
  final VoidCallback? onEmojiTap;

  const MessageTextInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmit,
    required this.onEmojiTap,
    this.enabled = true,
  });

  static bool _isMultiline(String text) =>
      text.contains('\n') || text.length > 50;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final multiline = _isMultiline(value.text);
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            maxLines: null,
            textInputAction:
                multiline ? TextInputAction.newline : TextInputAction.send,
            onSubmitted: (_) {
              if (!multiline) onSubmit?.call();
            },
            style: TextStyle(
              fontSize: 16,
              height: 1.3,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(
                  alpha: enabled ? 0.5 : 0.3,
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colorScheme.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              suffixIcon: onEmojiTap == null
                  ? null
                  : IconButton(
                      onPressed: enabled ? onEmojiTap : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      iconSize: 22,
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: colorScheme.onSurface.withValues(
                          alpha: enabled ? 0.6 : 0.3,
                        ),
                      ),
                      tooltip: 'Emoji & Stickers',
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}
