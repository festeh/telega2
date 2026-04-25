import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/ui_constants.dart';
import '../core/theme/appearance.dart';
import '../core/theme/motion.dart';
import '../core/theme/telega_tokens.dart';
import '../presentation/providers/app_providers.dart';
import '../presentation/providers/telegram_client_provider.dart';
import '../domain/entities/chat.dart';
import '../widgets/home/left_pane.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/message_input_area.dart';
import 'chat_helpers.dart';
import 'chat_screen.dart';
import '../widgets/chat_export/chat_export_dialog.dart';
import '../presentation/providers/chat_export_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isMobile) {
      return _buildMobileLayout(context, ref);
    }
    return _buildDesktopLayout(context, ref);
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LeftPane(
          onChatSelected: (chat) {
            ref.selectChatForMessages(chat.id);
            Navigator.of(context).push(_chatRoute(chat));
          },
        ),
      ),
    );
  }

  /// Forward transition: subtle slide-up from below + fade-in. Back uses the
  /// inverse automatically. Bounded by [kAppearanceLongTransitionDuration]
  /// so even with reduced-motion the navigation finishes promptly.
  Route<void> _chatRoute(Chat chat) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, _) => ChatScreen(chat: chat),
      transitionDuration: kAppearanceLongTransitionDuration,
      reverseTransitionDuration: kAppearanceLongTransitionDuration,
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final selectedChat = ref.selectedChat;

    return Scaffold(
      body: Row(
        children: [
          // Left Pane - Chat List
          SizedBox(
            width:
                MediaQuery.of(context).size.width * LayoutRatio.leftPaneWidth,
            child: LeftPane(
              onChatSelected: (chat) {
                ref.selectChatForMessages(chat.id);
              },
            ),
          ),
          // Right Pane - Chat Content (70% of screen width)
          Expanded(
            child: selectedChat != null
                ? _buildChatInterface(context, ref, selectedChat)
                : _buildEmptyPane(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(BuildContext context, WidgetRef ref, Chat chat) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<TelegaTokens>()!;
    final chatBg = tokens.chatBackground.resolve(colorScheme);

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Chat Header
          _buildChatHeader(context, ref, chat, colorScheme),
          // Messages Area
          Expanded(
            child: Container(
              color: chatBg,
              child: MessageList(chat: chat),
            ),
          ),
          // Message Input Area (only show if user can send messages)
          if (chat.canSendMessages) MessageInputArea(chat: chat),
        ],
      ),
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    WidgetRef ref,
    Chat chat,
    ColorScheme colorScheme,
  ) {
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final client = ref.read(telegramClientProvider);

    // Get status text based on chat type
    String statusText = getChatStatusText(chat, client);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Chat avatar
          Container(
            width: AvatarSize.sm,
            height: AvatarSize.sm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
              image: chat.photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(chat.photoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: chat.photoPath == null
                ? Center(
                    child: Text(
                      chat.title.isNotEmpty ? chat.title[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Chat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chat.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (statusText.isNotEmpty)
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusText == 'online'
                          ? colorScheme.primary
                          : mutedColor,
                    ),
                  ),
              ],
            ),
          ),
          // Action buttons
          IconButton(
            onPressed: () {
              // TODO: Implement search in chat
            },
            icon: Icon(Icons.search, color: mutedColor),
            tooltip: 'Search in chat',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                ref.read(chatExportProvider.notifier).reset();
                showDialog(
                  context: context,
                  builder: (_) => ChatExportDialog(chat: chat),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Chat info'),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(color: colorScheme.surface);
  }
}
