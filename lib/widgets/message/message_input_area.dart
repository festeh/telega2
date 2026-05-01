import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/media_item.dart';
import '../../presentation/providers/app_providers.dart';
import '../emoji_sticker/emoji_sticker_picker.dart';
import 'media_picker/media_picker_panel.dart';
import 'message_text_input.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Haptic acknowledgement of the send action. No-op on platforms without
    // tactile feedback (Linux/web/desktop without vibration motors).
    HapticFeedback.lightImpact();

    _textController.clear();

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
            child: MessageTextInput(
              controller: _textController,
              focusNode: _focusNode,
              hintText: isSending ? 'Sending...' : 'Type a message...',
              enabled: !isSending,
              onSubmit: _sendMessage,
              onEmojiTap: _showEmojiPicker,
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
    MediaPickerPanel.show(
      context: context,
      onSend: _sendSelectedMedia,
      onFilePicked: _sendDocument,
    );
  }

  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
  static const _videoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm'};

  Future<void> _sendDocument(String filePath) async {
    final chatId = widget.chat.id;
    final notifier = ref.read(messageProvider.notifier);
    final caption = _textController.text.trim();
    final ext = filePath.toLowerCase().split('.').last;
    final dotExt = '.$ext';

    if (dotExt == '.gif') {
      await notifier.sendAnimation(
        chatId,
        MediaItem(path: filePath),
        caption: caption.isNotEmpty ? caption : null,
      );
    } else if (_imageExtensions.contains(dotExt)) {
      await notifier.sendPhoto(
        chatId,
        MediaItem(path: filePath),
        caption: caption.isNotEmpty ? caption : null,
      );
    } else if (_videoExtensions.contains(dotExt)) {
      await notifier.sendVideo(
        chatId,
        MediaItem(path: filePath, isVideo: true),
        caption: caption.isNotEmpty ? caption : null,
      );
    } else {
      await notifier.sendDocument(
        chatId,
        filePath,
        caption: caption.isNotEmpty ? caption : null,
      );
    }

    if (caption.isNotEmpty) {
      _textController.clear();
    }
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

    // Resolve file paths, resize photos if needed, and determine types
    final resolvedItems = <MediaItem>[];
    for (final asset in items) {
      if (asset.type == AssetType.video) {
        final file = await asset.file;
        if (file == null) continue;
        resolvedItems.add(MediaItem(path: file.path, isVideo: true));
      } else {
        final item = await _resolvePhotoAsset(asset);
        if (item != null) resolvedItems.add(item);
      }
    }

    if (resolvedItems.isEmpty) return;

    if (resolvedItems.length == 1) {
      final item = resolvedItems.first;
      if (item.isVideo) {
        await notifier.sendVideo(
          chatId,
          item,
          caption: hasCaption ? effectiveCaption : null,
        );
      } else {
        await notifier.sendPhoto(
          chatId,
          item,
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
    }
  }

  /// Max pixels per side when resizing photos for sending (matches tdesktop).
  static const _maxPhotoSide = 2560;

  /// TDLib rejects photos where width + height > 10000.
  static bool _needsResize(int w, int h) => w + h > 10000;

  /// Returns scaled (width, height) fitting within [_maxPhotoSide] per side.
  static (int, int) _scaledDimensions(int w, int h) {
    if (w <= _maxPhotoSide && h <= _maxPhotoSide) return (w, h);
    final scale = _maxPhotoSide / (w > h ? w : h);
    return ((w * scale).round(), (h * scale).round());
  }

  /// Resolve a photo [AssetEntity] to a [MediaItem], resizing if too large.
  Future<MediaItem?> _resolvePhotoAsset(AssetEntity asset) async {
    final w = asset.width;
    final h = asset.height;

    if (!_needsResize(w, h)) {
      final file = await asset.file;
      if (file == null) return null;
      return MediaItem(path: file.path, width: w, height: h);
    }

    // Resize via photo_manager's platform-native scaling
    final (scaledW, scaledH) = _scaledDimensions(w, h);
    final bytes = await asset.thumbnailDataWithSize(
      ThumbnailSize(scaledW, scaledH),
      format: ThumbnailFormat.jpeg,
      quality: 87,
    );
    if (bytes == null) return null;

    // Write resized JPEG to temp file
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tg_send_${asset.id.hashCode}_${scaledW}x$scaledH.jpg',
    );
    await file.writeAsBytes(bytes);
    return MediaItem(path: file.path, width: scaledW, height: scaledH);
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
