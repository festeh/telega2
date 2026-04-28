# Plan: File/Document Download in Chat

## Tech Stack

- Dart 3.10+, Flutter + flutter_riverpod
- Existing TDLib integration (downloadFile, updateFile events)
- open_filex or url_launcher for opening downloaded files

## Structure

Files to modify/create:

```
lib/
├── domain/
│   ├── entities/chat.dart              # Add DocumentInfo class + document field on Message
│   └── events/message_events.dart      # Add MessageDocumentUpdatedEvent
├── data/
│   └── repositories/tdlib_telegram_client.dart  # Parse document, track file, handle update
├── presentation/
│   └── notifiers/message_notifier.dart          # Handle MessageDocumentUpdatedEvent
└── widgets/
    └── message/
        ├── message_bubble.dart          # Route document type to DocumentMessageWidget
        └── document_message.dart        # NEW: document download/open UI widget
```

## Approach

### 1. Add DocumentInfo data class (chat.dart)

Add a `DocumentInfo` class next to the existing `VideoInfo`/`AnimationInfo`:

```dart
class DocumentInfo {
  final String? path;
  final int? fileId;
  final String? fileName;
  final String? mimeType;
  final int? size; // bytes
}
```

Add `final DocumentInfo? document;` field to the `Message` class, constructor, `copyWith`, and `fromJson`.

### 2. Parse document from TDLib JSON (chat.dart)

Add `parseDocumentInfo()` inside `Message.fromJson`, following the same pattern as `parseVideoInfo()`:

- Extract from `contentMap['document']`
- File is in `document['document']` (the nested file object)
- Get `file_name`, `mime_type` from the document object
- Get file path from `document['document']['local']['path']`
- Get file ID from `document['document']['id']`
- Get size from `document['document']['expected_size']` or `document['document']['size']`

Update `parseContent()` to show file name instead of generic "Document":
```dart
case 'messageDocument':
  final caption = contentMap['caption']?['text'] as String?;
  return caption?.isNotEmpty == true ? caption! : '';
```

### 3. Add MessageDocumentUpdatedEvent (message_events.dart)

```dart
class MessageDocumentUpdatedEvent extends MessageEvent {
  final int chatId;
  final int messageId;
  final String documentPath;
}
```

### 4. Track document files in TDLib client (tdlib_telegram_client.dart)

Follow the exact pattern of video/animation tracking:

- Add `_documentFileToMessage` map (next to existing `_animationFileToMessage`)
- Register document file IDs when caching messages (in the block that does `_videoFileToMessage[...]`)
- Add `_updateMessageDocumentByFileId()` method (copy `_updateMessageVideoByFileId` pattern)
- Call it from the file update handler (next to `_updateMessageAnimationByFileId`)

### 5. Handle event in message notifier (message_notifier.dart)

Add a case for `MessageDocumentUpdatedEvent` in the event switch, following the `_handleMessageVideoUpdated` pattern:

```dart
case MessageDocumentUpdatedEvent(:final chatId, :final messageId, :final documentPath):
  _handleMessageDocumentUpdated(chatId, messageId, documentPath);
```

### 6. Create DocumentMessageWidget (document_message.dart)

A `ConsumerWidget` that shows:

- File icon (based on mime type or extension)
- File name (truncated if long)
- File size (formatted: KB, MB)
- Download button / progress indicator / "Open" button

States:
1. **Not downloaded** (path is null): Show file name + size + download icon. Tap triggers `ref.read(telegramClientProvider).downloadFile(fileId)`.
2. **Downloading** (watched via `ref.watchFileDownloadState(fileId)`): Show `CircularDownloadProgress` overlay.
3. **Downloaded** (path exists): Show file name + size + checkmark. Tap copies file to Downloads folder using `path_provider` (`getDownloadsDirectory()` on desktop, `getExternalStorageDirectory()` on Android).

Layout: horizontal row with icon on left, name+size in middle, action button on right.

### 7. Wire up in message_bubble.dart

Replace the placeholder:
```dart
case MessageType.document:
  return _buildDocumentMessage(context);
```

Add `_buildDocumentMessage()` that creates `DocumentMessageWidget` with caption support (same pattern as video/photo messages).

## Risks

- **Large file downloads**: The existing download progress infrastructure already handles this. No new risk.
- **Missing file name in TDLib response**: Fallback to "Document" if `file_name` is null.
- **Save to Downloads**: `path_provider` is already a dependency. Use it to get the Downloads directory and copy the file there.
