# Plan: Forwarded Message Attribution

**Branch**: `004-forwarded-message-attribution`

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- TDLib integration (existing)

## Structure

Files to change:

```
lib/
├── domain/entities/
│   └── chat.dart                    # Add forwardedFrom field to Message
├── data/repositories/
│   └── tdlib_telegram_client.dart   # Populate forwardedFrom from TDLib forward_info
└── widgets/message/
    └── message_bubble.dart          # Render "Forwarded from X" header inside bubble
```

## Approach

### 1. Add `forwardedFrom` field to Message model

In `chat.dart`, add a single nullable String field to `Message`:

```dart
final String? forwardedFrom;  // Original sender name for forwarded messages
```

Update these places:
- Constructor: add `this.forwardedFrom`
- `fromJson`: accept optional `forwardedFrom` parameter (like `senderName`)
- `toJson`: include `'forwarded_from': forwardedFrom`
- `copyWith`: add `forwardedFrom` parameter

One field is enough. We don't need `isForwarded` since `forwardedFrom != null` covers it. We don't need origin IDs since TDesktop only uses them for click-to-navigate, which we can skip for now.

### 2. Populate `forwardedFrom` in TDLib repository

In `_createMessageFromJson`, change the forward_info parsing to **always** extract the original sender name into `forwardedFrom`, instead of only using it as a fallback for `senderName`:

```
Before:  if (forwardInfo != null && senderName == null) { ... set senderName ... }
After:   if (forwardInfo != null) { ... set forwardedFromName ... }
         // Keep senderName from the actual message sender (not the original author)
```

This separates two concerns:
- `senderName` = who posted this message in the current chat
- `forwardedFrom` = who originally wrote the content

Handle all three origin types (same logic that exists today, just targeting a different variable):
- `messageOriginChannel` → channel title or author_signature
- `messageOriginUser` → user name from cache
- `messageOriginHiddenUser` → sender_name from origin

Pass `forwardedFrom` into `Message.fromJson()`.

### 3. Render "Forwarded from X" header in message bubble

In `message_bubble.dart`, add a `_buildForwardedFrom` widget that renders inside the bubble, above the message content. Style it similar to how TDesktop does it: smaller, muted service-style text.

Display location: inside `_buildMessageBubble`, between the reply preview and the message content:

```dart
if (message.replyToMessageId != null)
  _buildReplyPreview(context, ref),
if (message.forwardedFrom != null)          // NEW
  _buildForwardedFrom(context),             // NEW
_buildMessageContent(context),
```

Styling (following TDesktop patterns):
- Font size: 12px (same as sender name)
- Font weight: w400 (lighter than sender name's w500)
- Color: muted — `colorScheme.onSurface.withValues(alpha: 0.5)` for incoming, `colorScheme.onPrimary.withValues(alpha: 0.6)` for outgoing
- Text: `"Forwarded from {name}"`
- Bottom padding of 4px to separate from content

## Risks

- **Forward info cache miss**: Channel/user names might not be in `_chats`/`_userNames` cache when the message arrives. Mitigation: fall back to "Unknown" — same behavior as current senderName fallback. The names populate as TDLib sends user/chat updates.
- **Breaking `copyWith` callers**: Adding a field to `copyWith` with a default of `null` is non-breaking since it's nullable with a fallback to `this.forwardedFrom`.

## Open Questions

None — scope is well-defined.
