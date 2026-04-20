import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logging/error_log_buffer.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/app_providers.dart';
import '../../screens/error_log_screen.dart';
import '../../screens/settings_screen.dart';
import '../chat/chat_list.dart';

class LeftPane extends ConsumerWidget {
  final Function(Chat)? onChatSelected;

  const LeftPane({super.key, this.onChatSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, ref, colorScheme),
          Expanded(child: ChatList(onChatSelected: onChatSelected)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    ref.watch(errorLogProvider); // rebuild on changes
    final unseenCount = ErrorLogBuffer.instance.unseenCount;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Menu with error log + settings (shows error badge)
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'errors') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ErrorLogScreen(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'errors',
                child: Row(
                  children: [
                    Badge(
                      isLabelVisible: unseenCount > 0,
                      label: Text(
                        unseenCount > 99 ? '99+' : unseenCount.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      child: const Icon(Icons.error_outline),
                    ),
                    const SizedBox(width: 12),
                    const Text('Error log'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
            icon: Badge(
              isLabelVisible: unseenCount > 0,
              label: Text(
                unseenCount > 99 ? '99+' : unseenCount.toString(),
                style: const TextStyle(fontSize: 10),
              ),
              child: Icon(Icons.menu, size: 24, color: mutedColor),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              'Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // New chat button
          IconButton(
            onPressed: () {
              // TODO: Implement new chat functionality
            },
            icon: Icon(
              Icons.edit_outlined,
              size: 24,
              color: mutedColor,
            ),
            tooltip: 'New Chat',
          ),
        ],
      ),
    );
  }
}
