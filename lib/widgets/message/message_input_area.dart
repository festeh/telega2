import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/app_providers.dart';
import '../emoji_sticker/emoji_sticker_picker.dart';
import 'media_picker/media_picker_panel.dart';

class MessageInputArea extends ConsumerStatefulWidget {
  final Chat chat;

  const MessageInputArea({super.key, required this.chat});

  @override
  ConsumerState<MessageInputArea> createState() => _MessageInputAreaState();
}

class _MessageInputAreaState extends ConsumerState<MessageInputArea>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isMultiline = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateKeyboardHeight();
  }

  void _updateKeyboardHeight() {
    final viewInsets =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets;
    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final keyboardHeight = viewInsets.bottom / devicePixelRatio;

    // Only store substantial keyboard heights (not during animation)
    if (keyboardHeight > 150) {
      ref.read(emojiStickerProvider.notifier).setKeyboardHeight(keyboardHeight);
    }
  }

  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      _isMultiline = text.contains('\n') || text.length > 50;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _isMultiline = false;
    });

    try {
      await ref
          .read(messageProvider.notifier)
          .sendMessage(widget.chat.id, text);
    } catch (e) {
      _textController.text = text;

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: colorScheme.onError,
              onPressed: () => _sendMessage(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSending = ref.watch(
      messageProvider.select((state) => state.value?.isSending ?? false),
    );
    final hasError = ref.watch(
      messageProvider.select((state) => state.hasError),
    );
    final replyingToMessage = ref.watch(
      messageProvider.select((state) => state.value?.replyingToMessage),
    );

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
          if (hasError) _buildErrorBanner(),
          if (replyingToMessage != null) _buildReplyPreview(replyingToMessage),
          _buildInputArea(isSending),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    final error = ref.watch(
      messageProvider.select((state) => state.error?.toString()),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error ?? 'An error occurred',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onErrorContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(messageProvider.notifier).clearError(),
            child: Text(
              'Dismiss',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(Message message) {
    final colorScheme = Theme.of(context).colorScheme;
    final senderName =
        message.senderName ?? (message.isOutgoing ? 'You' : 'User');
    final content = message.content.length > 50
        ? '${message.content.substring(0, 50)}...'
        : message.content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
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
          IconButton(
            onPressed: () =>
                ref.read(messageProvider.notifier).clearReplyingTo(),
            icon: Icon(
              Icons.close,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isSending) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: isSending ? null : _showAttachmentOptions,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              Icons.attach_file,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Attach file',
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: !isSending,
                maxLines: null,
                textInputAction: _isMultiline
                    ? TextInputAction.newline
                    : TextInputAction.send,
                onSubmitted: (_) {
                  if (!_isMultiline) {
                    _sendMessage();
                  }
                },
                decoration: InputDecoration(
                  hintText: isSending ? 'Sending...' : 'Type a message...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(
                      alpha: isSending ? 0.3 : 0.5,
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
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: isSending ? null : _showEmojiPicker,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    iconSize: 22,
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: colorScheme.onSurface.withValues(
                        alpha: isSending ? 0.3 : 0.6,
                      ),
                    ),
                    tooltip: 'Emoji & Stickers',
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 40,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          _buildSendButton(isSending),
        ],
      ),
    );
  }

  Widget _buildSendButton(bool isSending) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      width: 36,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isSending
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: isSending ? null : _sendMessage,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: isSending
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              )
            : Icon(Icons.send, color: colorScheme.onPrimary, size: 18),
        tooltip: isSending ? 'Sending...' : 'Send message',
      ),
    );
  }

  void _showAttachmentOptions() {
    MediaPickerPanel.show(context: context, onSend: _sendSelectedMedia);
  }

  Future<void> _sendSelectedMedia(
    List<AssetEntity> items,
    String? caption,
  ) async {
    final chatId = widget.chat.id;
    final notifier = ref.read(messageProvider.notifier);

    // Use caption from text input if not explicitly provided
    final effectiveCaption = caption ?? _textController.text.trim();
    final hasCaption = effectiveCaption.isNotEmpty;

    // Resolve file paths and determine types
    final resolvedItems = <(String path, bool isVideo)>[];
    for (final asset in items) {
      final file = await asset.file;
      if (file == null) continue;
      resolvedItems.add((file.path, asset.type == AssetType.video));
    }

    if (resolvedItems.isEmpty) return;

    if (resolvedItems.length == 1) {
      final (path, isVideo) = resolvedItems.first;
      if (isVideo) {
        await notifier.sendVideo(
          chatId,
          path,
          caption: hasCaption ? effectiveCaption : null,
        );
      } else {
        await notifier.sendPhoto(
          chatId,
          path,
          caption: hasCaption ? effectiveCaption : null,
        );
      }
    } else {
      await notifier.sendAlbum(
        chatId,
        resolvedItems,
        caption: hasCaption ? effectiveCaption : null,
      );
    }

    // Clear text field if caption was used from it
    if (hasCaption && caption == null) {
      _textController.clear();
      setState(() => _isMultiline = false);
    }
  }

  Future<void> _pickFromCamera() async {
    // Camera is not available on Linux desktop
    if (Platform.isLinux) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not available on desktop')),
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await ref
            .read(messageProvider.notifier)
            .sendPhoto(widget.chat.id, image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        await ref
            .read(messageProvider.notifier)
            .sendDocument(widget.chat.id, result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick document: $e')));
      }
    }
  }

  void _showEmojiPicker() {
    _focusNode.unfocus();
    EmojiStickerPicker.show(
      context: context,
      textController: _textController,
      chatId: widget.chat.id,
      onStickerSent: () {
        Navigator.of(context).pop();
      },
    );
  }
}
