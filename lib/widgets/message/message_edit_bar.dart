import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/app_providers.dart';
import 'message_text_input.dart';

/// Inline edit bar shown at the bottom of [ChatScreen] in place of the
/// composer when [MessageState.editingMessage] is set.
///
/// Layout:
/// ```
///  ✎  Editing message
///     Original text preview…
///  ─────────────────────────────────────────
///  [✕]  [ Edit text…             😊 ]  [✓]
/// ```
class MessageEditBar extends ConsumerStatefulWidget {
  final int chatId;
  final Message message;

  const MessageEditBar({
    super.key,
    required this.chatId,
    required this.message,
  });

  @override
  ConsumerState<MessageEditBar> createState() => _MessageEditBarState();
}

class _MessageEditBarState extends ConsumerState<MessageEditBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(MessageEditBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the user picks a different message to edit while the bar is mounted,
    // reseed the controller text. This is a defensive case — normally the
    // ChatScreen rebuilds with a new key.
    if (oldWidget.message.id != widget.message.id) {
      _controller.text = widget.message.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    ref.read(messageProvider.notifier).cancelEditing();
  }

  Future<void> _save() async {
    final newText = _controller.text.trim();
    if (newText.isEmpty || newText == widget.message.content) {
      _cancel();
      return;
    }
    await ref
        .read(messageProvider.notifier)
        .editMessage(widget.chatId, widget.message.id, newText);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBanner(colorScheme),
          _buildInputRow(colorScheme),
        ],
      ),
    );
  }

  Widget _buildBanner(ColorScheme colorScheme) {
    final preview = widget.message.content.length > 60
        ? '${widget.message.content.substring(0, 60)}...'
        : widget.message.content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _cancel,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Cancel edit',
          ),
          Expanded(
            child: MessageTextInput(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Edit message...',
              onSubmit: _save,
              onEmojiTap: null,
            ),
          ),
          _buildSaveButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final trimmed = value.text.trim();
        final canSave =
            trimmed.isNotEmpty && trimmed != widget.message.content;
        return Container(
          height: 36,
          width: 36,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: canSave
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: canSave ? _save : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.check,
              color: canSave
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
              size: 18,
            ),
            tooltip: 'Save',
          ),
        );
      },
    );
  }
}
