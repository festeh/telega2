import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/telega_tokens.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/telegram_client_provider.dart';
import 'album_grid.dart';
import 'album_grouping.dart';
import 'animation_message.dart';
import 'document_message.dart';
import 'emoji_text.dart';
import 'photo_message.dart';
import 'reaction_chip.dart';
import 'video_message.dart';

/// Renders a grouped Telegram album (multiple messages sharing a
/// `media_album_id`) as one bubble: reply preview / forwarded line / sender /
/// grid (or vertical stack) / caption / timestamp / per-item reactions.
///
/// Per-item interactions are preserved: long-pressing a cell triggers
/// [onLongPress] with that specific message; tapping is handled by the inner
/// media widget (single-item full-screen viewer, same as today).
class AlbumMessageBubble extends ConsumerWidget {
  final AlbumRow album;
  final bool showSender;
  final void Function(Message message) onLongPress;

  const AlbumMessageBubble({
    super.key,
    required this.album,
    required this.showSender,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<TelegaTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isOutgoing = album.messages.first.isOutgoing;
    final isMinimalLine = tokens.bubbleStyle == BubbleStyle.minimalLine;
    final incomingFill = tokens.incomingBubbleFill;

    final Color fillColor;
    final Color? borderColor;
    final double borderWidth;

    if (isOutgoing) {
      fillColor = isMinimalLine ? Colors.transparent : colorScheme.primary;
      borderColor = isMinimalLine ? colorScheme.primary : null;
      borderWidth = 1.5;
    } else if (isMinimalLine) {
      fillColor = Colors.transparent;
      borderColor = colorScheme.outline;
      borderWidth = 1.5;
    } else {
      fillColor = incomingFill.resolve(colorScheme);
      borderColor = colorScheme.outline;
      borderWidth = incomingFill.drawsBorder ? 1.5 : 1.0;
    }

    final hasShadow = !isMinimalLine && !incomingFill.drawsBorder ||
        isOutgoing && !isMinimalLine;

    final captionMessage = album.messages.firstWhere(
      (m) => m.content.isNotEmpty,
      orElse: () => album.messages.first,
    );
    final hasCaption = captionMessage.content.isNotEmpty;

    final replyMessage = album.messages.cast<Message?>().firstWhere(
          (m) => m?.replyToMessageId != null,
          orElse: () => null,
        );

    final forwardedMessage = album.messages.cast<Message?>().firstWhere(
          (m) => m?.forwardedFrom != null,
          orElse: () => null,
        );

    final isGridMode = album.messages
        .every((m) => _isGridFriendlyType(m.type));

    return GestureDetector(
      onLongPress: () => onLongPress(album.newest),
      child: Container(
        margin: EdgeInsets.only(
          left: isOutgoing ? tokens.bubbleGutterWide : tokens.bubbleGutterNarrow,
          right: isOutgoing ? tokens.bubbleGutterNarrow : tokens.bubbleGutterWide,
          top: tokens.gapXs,
          bottom: tokens.gapXs,
        ),
        child: Row(
          mainAxisAlignment: isOutgoing
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: isOutgoing
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showSender && !isOutgoing) _buildSenderName(context),
                  Container(
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius:
                          tokens.bubbleRadius(isOutgoing: isOutgoing),
                      boxShadow: hasShadow
                          ? [
                              BoxShadow(
                                color:
                                    colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                      border: borderColor != null
                          ? Border.all(color: borderColor, width: borderWidth)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: tokens.bubbleRadius(isOutgoing: isOutgoing),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.bubbleHorizontalPadding,
                          vertical: tokens.bubbleVerticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (replyMessage != null)
                              _buildReplyPreview(context, replyMessage),
                            if (forwardedMessage != null)
                              _buildForwardedFrom(context, forwardedMessage),
                            if (isGridMode)
                              _buildGrid(context)
                            else
                              _buildVerticalStack(context),
                            if (hasCaption) ...[
                              const SizedBox(height: 8),
                              EmojiText(
                                text: captionMessage.content,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.3,
                                  color: _textColorOnBubble(
                                      context, isOutgoing, isMinimalLine),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildTimestamp(context, isOutgoing),
                  ..._buildReactionRows(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isGridFriendlyType(MessageType type) =>
      type == MessageType.photo ||
      type == MessageType.video ||
      type == MessageType.animation;

  Widget _buildGrid(BuildContext context) {
    final cells = <Widget>[];
    for (final message in album.messages) {
      cells.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => onLongPress(message),
          child: _buildMediaCell(message),
        ),
      );
    }
    return AlbumGrid(cells: cells);
  }

  Widget _buildVerticalStack(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < album.messages.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => onLongPress(album.messages[i]),
            child: _buildStackedItem(context, album.messages[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaCell(Message message) {
    switch (message.type) {
      case MessageType.photo:
        return PhotoMessageWidget(
          photoPath: message.photo?.path,
          photoWidth: message.photo?.width,
          photoHeight: message.photo?.height,
          photoFileId: message.photo?.fileId,
          isOutgoing: message.isOutgoing,
        );
      case MessageType.video:
        return VideoMessageWidget(
          videoPath: message.video?.path,
          videoWidth: message.video?.width,
          videoHeight: message.video?.height,
          duration: message.video?.duration,
          thumbnailPath: message.video?.thumbnail?.path,
          videoFileId: message.video?.fileId,
          isOutgoing: message.isOutgoing,
        );
      case MessageType.animation:
        return AnimationMessageWidget(
          animationPath: message.animation?.path,
          animationWidth: message.animation?.width,
          animationHeight: message.animation?.height,
          thumbnailPath: message.animation?.thumbnail?.path,
          animationFileId: message.animation?.fileId,
          isOutgoing: message.isOutgoing,
        );
      default:
        // Grid mode is gated by [_isGridFriendlyType] so this branch is
        // unreachable. Render a tiny placeholder instead of crashing if the
        // gating ever drifts.
        return const SizedBox.shrink();
    }
  }

  Widget _buildStackedItem(BuildContext context, Message message) {
    switch (message.type) {
      case MessageType.document:
        return DocumentMessageWidget(
          documentPath: message.document?.path,
          documentFileId: message.document?.fileId,
          fileName: message.document?.fileName,
          mimeType: message.document?.mimeType,
          size: message.document?.size,
          isOutgoing: message.isOutgoing,
        );
      case MessageType.photo:
        return PhotoMessageWidget(
          photoPath: message.photo?.path,
          photoWidth: message.photo?.width,
          photoHeight: message.photo?.height,
          photoFileId: message.photo?.fileId,
          isOutgoing: message.isOutgoing,
        );
      case MessageType.video:
        return VideoMessageWidget(
          videoPath: message.video?.path,
          videoWidth: message.video?.width,
          videoHeight: message.video?.height,
          duration: message.video?.duration,
          thumbnailPath: message.video?.thumbnail?.path,
          videoFileId: message.video?.fileId,
          isOutgoing: message.isOutgoing,
        );
      case MessageType.animation:
        return AnimationMessageWidget(
          animationPath: message.animation?.path,
          animationWidth: message.animation?.width,
          animationHeight: message.animation?.height,
          thumbnailPath: message.animation?.thumbnail?.path,
          animationFileId: message.animation?.fileId,
          isOutgoing: message.isOutgoing,
        );
      default:
        return _buildGenericItem(context, message);
    }
  }

  Widget _buildGenericItem(BuildContext context, Message message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.content.isNotEmpty ? message.content : 'Attachment',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildSenderName(BuildContext context) {
    final senderId = album.messages.first.senderId;
    final displayName = album.messages.first.senderName ?? 'User $senderId';
    final avatarColor =
        AppTheme.avatarColors[senderId.abs() % AppTheme.avatarColors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 12),
      child: Text(
        displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: avatarColor,
        ),
      ),
    );
  }

  Widget _buildForwardedFrom(BuildContext context, Message source) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).extension<TelegaTokens>()!.bubbleStyle;
    final isOutgoing = source.isOutgoing;
    final textColor = style == BubbleStyle.minimalLine
        ? colorScheme.onSurface.withValues(alpha: 0.5)
        : (isOutgoing
            ? colorScheme.onPrimary.withValues(alpha: 0.6)
            : colorScheme.onSurface.withValues(alpha: 0.5));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        'Forwarded from ${source.forwardedFrom}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, Message replyOwner) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOutline = Theme.of(context).extension<TelegaTokens>()!.bubbleStyle ==
        BubbleStyle.minimalLine;
    final isOutgoing = replyOwner.isOutgoing;
    final primaryColor = isOutline
        ? colorScheme.primary
        : (isOutgoing
            ? colorScheme.onPrimary.withValues(alpha: 0.8)
            : colorScheme.primary);
    final textColor = isOutline
        ? colorScheme.onSurface.withValues(alpha: 0.7)
        : (isOutgoing
            ? colorScheme.onPrimary.withValues(alpha: 0.7)
            : colorScheme.onSurface.withValues(alpha: 0.7));
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: primaryColor, width: 2)),
        color: isOutline
            ? colorScheme.primary.withValues(alpha: 0.1)
            : (isOutgoing
                ? colorScheme.onPrimary.withValues(alpha: 0.1)
                : colorScheme.primary.withValues(alpha: 0.1)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        'Reply',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isOutgoing) {
    final colorScheme = Theme.of(context).colorScheme;
    final newest = album.newest;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(newest.date),
            style: TextStyle(fontSize: 11, color: mutedColor),
          ),
          if (isOutgoing) ...[
            const SizedBox(width: 4),
            _buildAggregateStatus(context, mutedColor),
          ],
        ],
      ),
    );
  }

  Widget _buildAggregateStatus(BuildContext context, Color mutedColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final states = album.messages.map((m) => m.sendingState).toSet();

    if (states.contains(MessageSendingState.failed)) {
      return Icon(Icons.error_outline, size: 14, color: colorScheme.error);
    }
    if (states.contains(MessageSendingState.pending)) {
      return Icon(Icons.access_time, size: 14, color: mutedColor);
    }
    if (states.length == 1 && states.first == MessageSendingState.read) {
      return Icon(Icons.done_all, size: 14, color: colorScheme.primary);
    }
    return Icon(Icons.done, size: 14, color: mutedColor);
  }

  List<Widget> _buildReactionRows(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];
    for (final message in album.messages) {
      final reactions = message.reactions;
      if (reactions == null || reactions.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: reactions.map((reaction) {
              final isPaid = reaction.type == ReactionType.paid;
              return ReactionChip(
                reaction: reaction,
                onTap: isPaid
                    ? null
                    : () => _toggleReaction(ref, message, reaction),
              );
            }).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  void _toggleReaction(
    WidgetRef ref,
    Message message,
    MessageReaction reaction,
  ) {
    final client = ref.read(telegramClientProvider);
    if (reaction.isChosen) {
      client.removeReaction(message.chatId, message.id, reaction);
    } else {
      client.addReaction(message.chatId, message.id, reaction);
    }
  }

  Color _textColorOnBubble(
      BuildContext context, bool isOutgoing, bool isMinimalLine) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isMinimalLine) return colorScheme.onSurface;
    return isOutgoing ? colorScheme.onPrimary : colorScheme.onSurface;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (messageDay == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (messageDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else if (messageDay.year == today.year) {
      return DateFormat('MMM dd HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    }
  }
}
