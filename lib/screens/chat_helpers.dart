import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/chat.dart';
import '../presentation/providers/app_providers.dart';

String getChatStatusText(Chat chat, dynamic client) {
  switch (chat.type) {
    case ChatType.private:
      final status = client.getUserStatus(chat.id);
      return status ?? '';
    case ChatType.basicGroup:
    case ChatType.supergroup:
    case ChatType.channel:
    case ChatType.secret:
      return '';
  }
}

void showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.logout();
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}
