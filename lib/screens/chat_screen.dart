import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/telegram_client_provider.dart';
import '../domain/entities/chat.dart';
import 'chat_helpers.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/message_input_area.dart';

class ChatScreen extends ConsumerWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, ref, colorScheme),
      body: SafeArea(
        top: false, // AppBar handles top
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: MessageList(chat: chat),
              ),
            ),
            if (chat.canSendMessages) MessageInputArea(chat: chat),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final client = ref.read(telegramClientProvider);
    final statusText = getChatStatusText(chat, client);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.search, color: mutedColor),
          tooltip: 'Search in chat',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              showLogoutDialog(context, ref);
            }
          },
          itemBuilder: (context) => [
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
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
