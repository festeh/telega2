# Plan: Chat Export to JSON with Date Picker

**Spec**: specs/011-chat-export-to-json-with-date-picker/spec.md

## Tech Stack

- Dart 3.10+, Flutter + flutter_riverpod
- Existing TDLib integration (`getChatHistory`, `getChatMessageByDate`)
- `path_provider` for Downloads path (reuse pattern from `document_message.dart`)
- `dart:convert` for JSON encoding
- Flutter's built-in `showDateRangePicker` for date selection

## Structure

Files to create/modify:

```
lib/
├── screens/
│   └── chat_screen.dart                    # Add "Export chat" menu item
├── widgets/
│   └── chat_export/
│       └── chat_export_dialog.dart         # NEW: export dialog with date picker + progress
├── data/
│   └── repositories/
│       └── tdlib_telegram_client.dart      # Add getMessageByDate() and loadMessagesInRange()
├── domain/
│   └── repositories/
│       └── telegram_client_repository.dart # Add interface methods
└── presentation/
    └── providers/
        └── chat_export_provider.dart       # NEW: export state + logic
```

## Approach

### 1. Add TDLib methods for date-based message loading

Add two methods to `TdlibTelegramClient`:

- **`getMessageByDate(chatId, date)`** - calls TDLib's `getChatMessageByDate` to find the message ID closest to a given Unix timestamp. This anchors our pagination start/end points.
- **`loadMessagesInRange(chatId, fromDate, toDate)`** - uses `getMessageByDate` to find the starting message, then paginates backward through `getChatHistory` until messages fall before `fromDate`. Collects all messages in range and returns them.

Add corresponding abstract methods to `TelegramClientRepository`.

### 2. Create export provider

`ChatExportProvider` - a simple `AsyncNotifier` that:

- Holds export state: `idle`, `pickingDates`, `exporting(progress)`, `done(filePath)`, `error(message)`
- `exportChat(chatId, chatTitle, chatType, fromDate, toDate)`:
  1. Calls `loadMessagesInRange` on the TDLib client
  2. Serializes messages to the JSON format from the spec
  3. Writes to Downloads folder (reuse the platform path logic from `DocumentMessageWidget`)
  4. Returns the file path on success

### 3. Create export dialog widget

`ChatExportDialog` - a dialog/bottom sheet that:

1. Opens Flutter's `showDateRangePicker` immediately
2. On date selection, shows a confirmation with the selected range and an "Export" button
3. On export, shows a `CircularProgressIndicator` while messages load
4. On completion, shows the file name and a "Done" button
5. On error, shows the error message with a "Retry" button

Use Flutter's built-in `showDateRangePicker` - it handles from/to validation out of the box.

### 4. Add menu item to chat screen

Add an "Export chat" `PopupMenuItem` to the existing `PopupMenuButton` in `ChatScreen._buildAppBar`. On tap, show the `ChatExportDialog`.

### 5. JSON serialization

Create a `toExportJson()` method on `Message` that returns a `Map<String, dynamic>` with the fields from the spec format. Keep media references as type descriptions (not file paths, which are local). Include reactions, reply references, and forward attribution.

The top-level JSON wraps messages with chat metadata, export timestamp, date range, and message count.

### 6. File writing

Reuse the Downloads path logic from `document_message.dart`:
- Android: `/storage/emulated/0/Download`
- Linux: `$HOME/Downloads`
- macOS: `$HOME/Downloads`

File name format: `{chat_title}_{from_date}_{to_date}.json` (sanitized for filesystem).
Add `(1)`, `(2)` suffix if file exists, same pattern as document downloads.

## Risks

- **Large chat history**: Loading thousands of messages could take time. Mitigation: show progress, load in pages, keep UI responsive with async gaps.
- **TDLib rate limiting on getChatHistory**: Rapid sequential calls might be throttled. Mitigation: small delay between page fetches (already used in existing code).
- **Memory for very large exports**: All messages held in memory before writing JSON. Mitigation: for typical exports (up to ~10K messages) this is fine. Streaming JSON would add complexity for marginal benefit.

## Open Questions

- None - this is a focused feature with clear requirements.
