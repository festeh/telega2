import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/chat.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/telega_tokens.dart';

class ChatListItem extends StatefulWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback? onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<TelegaTokens>()!;
    final scale = tokens.bodyFontScale;

    final transitionDuration = motionDurationFor(
      context,
      kAppearanceTransitionDuration,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: transitionDuration,
          decoration: BoxDecoration(
            color: _getBackgroundColor(colorScheme),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSize(
            duration: transitionDuration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapLg,
                vertical: tokens.listRowVerticalPadding,
              ),
              child: Row(
                children: [
                  _buildAvatar(context),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.chat.title,
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: tokens.gapSm),
                            _buildTimestamp(context),
                          ],
                        ),
                        SizedBox(height: tokens.gapXs),
                        Row(
                          children: [
                            Expanded(child: _buildLastMessage(context)),
                            SizedBox(width: tokens.gapSm),
                            _buildReactionBadge(context),
                            _buildUnreadBadge(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (widget.isSelected) {
      return colorScheme.primary;
    }
    if (_isHovered) {
      return colorScheme.surfaceContainerHigh;
    }
    return Colors.transparent;
  }

  Widget _buildAvatar(BuildContext context) {
    final tokens = Theme.of(context).extension<TelegaTokens>()!;
    final size = tokens.chatListAvatarSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(),
        image: widget.chat.photoPath != null
            ? DecorationImage(
                image: _getImageProvider(widget.chat.photoPath!),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              )
            : null,
      ),
      child: widget.chat.photoPath == null
          ? Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 18 * tokens.bodyFontScale,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  Color _getAvatarColor() {
    final colors = AppTheme.avatarColors;
    return colors[widget.chat.id.abs() % colors.length];
  }

  String _getInitials() {
    final title = widget.chat.title.trim();
    if (title.isEmpty) return '?';

    final words = title.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  Widget _buildTimestamp(BuildContext context) {
    final lastActivity = widget.chat.lastActivity;
    if (lastActivity == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final scale = Theme.of(context).extension<TelegaTokens>()!.bodyFontScale;
    final now = DateTime.now();
    final diff = now.difference(lastActivity);

    String timeText;
    final timeColor = widget.isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.5);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) {
        timeText = 'yesterday';
      } else if (diff.inDays < 7) {
        timeText = '${diff.inDays}d ago';
      } else {
        timeText = '${(diff.inDays / 7).floor()}w ago';
      }
    } else if (diff.inHours > 0) {
      timeText = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      timeText = '${diff.inMinutes}m ago';
    } else {
      timeText = 'now';
    }

    return Text(
      timeText,
      style: TextStyle(fontSize: 12 * scale, color: timeColor),
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = Theme.of(context).extension<TelegaTokens>()!.bodyFontScale;
    final lastMessage = widget.chat.lastMessage;
    final textColor = widget.isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.5);

    if (lastMessage == null) {
      return Text(
        'No messages yet',
        style: TextStyle(fontSize: 14 * scale, color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String messagePrefix = '';
    if (lastMessage.isOutgoing) {
      messagePrefix = 'You: ';
    }

    // Get display text - use content if available, otherwise show type placeholder
    final displayText = lastMessage.content.isNotEmpty
        ? lastMessage.content
        : _getMessageTypeLabel(lastMessage.type);

    return Text(
      '$messagePrefix$displayText',
      style: TextStyle(fontSize: 14 * scale, color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.photo:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.sticker:
        return '🎭 Sticker';
      case MessageType.document:
        return '📎 Document';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.animation:
        return '🎞️ GIF';
      case MessageType.text:
        return 'Message';
    }
  }

  Widget _buildReactionBadge(BuildContext context) {
    final emoji = widget.chat.unreadReactionEmoji;
    if (emoji == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final scale = Theme.of(context).extension<TelegaTokens>()!.bodyFontScale;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colorScheme.onPrimary.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 14 * scale),
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(BuildContext context) {
    if (widget.chat.unreadCount <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final scale = Theme.of(context).extension<TelegaTokens>()!.bodyFontScale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.chat.isMuted
            ? colorScheme.secondary
            : colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          widget.chat.unreadCount > 99 ? '99+' : '${widget.chat.unreadCount}',
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
            color: widget.chat.isMuted
                ? colorScheme.onSecondary
                : colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
