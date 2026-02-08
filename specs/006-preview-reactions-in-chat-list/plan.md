# Plan: Preview Reactions in Chat List

**Branch**: 006-preview-reactions-in-chat-list

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- Data: Existing TDLib integration via `TdlibTelegramClient`

## Structure

Files to change:

```
lib/
├── domain/
│   ├── entities/chat.dart          # Add unreadReactionEmoji to Chat
│   └── events/chat_events.dart     # Add ChatUnreadReactionEvent
├── data/repositories/
│   └── tdlib_telegram_client.dart  # Detect new reaction, emit event with emoji
├── presentation/notifiers/
│   └── chat_notifier.dart          # Handle new event, update chat state
└── widgets/chat/
    └── chat_list_item.dart         # Render reaction emoji badge
```

## Approach

### 1. Add `unreadReactionEmoji` field to `Chat` in `chat.dart`

```dart
class Chat {
  // ... existing fields ...
  final String? unreadReactionEmoji;  // "👍" — last unread reaction emoji, null if none
}
```

Add to constructor, `copyWith`, `fromJson`.

### 2. Add `ChatUnreadReactionEvent` to `chat_events.dart`

```dart
class ChatUnreadReactionEvent extends ChatEvent {
  final int chatId;
  final String? emoji;  // null = clear the badge
  ChatUnreadReactionEvent(this.chatId, this.emoji);
}
```

### 3. Emit reaction event from `tdlib_telegram_client.dart`

In `_handleMessageInteractionInfoUpdate()`, after parsing reactions:

- Compare new reactions to old cached reactions on the message (diff counts).
- If any reaction count increased, pick the first emoji whose count grew.
- Only emit for private and basic group chats (`type == ChatType.private || type == ChatType.basicGroup`).
- Emit `ChatUnreadReactionEvent(chatId, emoji)` on `_chatEventController`.

No extra API calls needed — the emoji is right there in the reaction data.

### 4. Handle event in `chat_notifier.dart`

Add a case to `_handleChatEvent`:

```dart
case ChatUnreadReactionEvent(:final chatId, :final emoji):
  _updateChatProperty(
    chatId,
    (chat) => chat.copyWith(unreadReactionEmoji: emoji),
  );
```

Clear the badge when the user opens the chat (selecting a chat already triggers state updates — clear `unreadReactionEmoji` there).

### 5. Render reaction emoji badge in `chat_list_item.dart`

In the bottom row (next to unread count badge), add a small reaction emoji badge:

- If `chat.unreadReactionEmoji != null`, render a small pill with the emoji (similar style to unread badge but with the emoji character instead of a count).
- Position it next to the unread count badge.

## Risks

- **Custom emoji reactions**: For `ReactionType.customEmoji`, we don't have a simple emoji string. Show a placeholder `🫧` in the badge.
- **Badge clearing**: When the user opens a chat, call TDLib's `readAllChatReactions` (new method to add to `tdlib_telegram_client.dart`), same place where `viewMessages`/`markAsRead` is called — in `message_notifier.dart`'s `markAsRead()` or alongside it in `message_list.dart`'s `_markLatestAsRead()`. TDLib will respond with `updateChatUnreadReactionCount` (count: 0), which we handle by clearing `unreadReactionEmoji` on the chat.
