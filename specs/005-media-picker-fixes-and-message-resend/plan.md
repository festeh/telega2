# Plan: Media Picker Fixes & Message Resend

**Branch**: `005-media-picker-fixes-and-message-resend`

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- Dependencies: `file_picker` (already in pubspec), `photo_manager` (existing)
- TDLib: `resendMessages` API for failed message retry

## Structure

Files to change:

```
lib/
├── widgets/message/
│   ├── media_picker/
│   │   └── media_picker_panel.dart   # Add file picker button, fix reload on resume
│   ├── message_list.dart             # Add "Resend" context menu option
│   ├── message_bubble.dart           # Show local image preview for pending/sending photos
│   └── photo_message.dart            # Accept local file path for upload preview
├── presentation/
│   ├── providers/
│   │   └── media_picker_provider.dart # Fix refresh on app resume
│   └── notifiers/
│       └── message_notifier.dart      # Add resendMessage method
├── domain/
│   └── repositories/
│       └── telegram_client_repository.dart # Add resendMessages to interface
└── data/
    └── repositories/
        └── tdlib_telegram_client.dart # Implement resendMessages TDLib call
```

## Approach

### 1. Add file picker button to media picker panel

**File**: `media_picker_panel.dart`

Add a "File" button in the action row (alongside the Send button). On tap, open `FilePicker.platform.pickFiles()` from the `file_picker` package. When a file is picked, send it as a document via `notifier.sendDocument()` and close the picker.

The button goes on the left side of `_buildActionRow()`, before the Spacer. Icon: `Icons.folder_outlined` with label "File".

### 2. Fix gallery not refreshing when user takes a photo

**File**: `media_picker_panel.dart` → `didChangeAppLifecycleState`

Current code only re-requests permission when `denied`. When the user leaves to take a photo and comes back, the state is `authorized` so nothing happens.

Fix: When state is `resumed` and permission is already `authorized` or `limited`, call `ref.read(mediaPickerProvider.notifier).refresh()` to reload the asset list. This picks up any new photos taken while the picker was open.

### 3. Show actual image preview while sending (instead of placeholder)

**Problem**: When TDLib creates the pending message for a photo send, the `photo.path` may be empty because the local file reference isn't always populated in the `updateNewMessage` event for pending messages.

**File**: `tdlib_telegram_client.dart` → `_handleNewMessage` / `_createMessageFromJson`

When parsing a photo message from TDLib JSON, the local file path is at `content.photo.sizes[last].photo.local.path`. For pending messages being sent, TDLib does populate this field with the local file path. Check if the path extraction logic is working correctly for pending messages.

If the path is already being extracted but is empty for pending messages, the alternative approach: in `sendPhoto()`, create an optimistic `Message` object with the local file path set in `PhotoInfo` before TDLib responds, and add it to state immediately. This gives instant preview.

**Likely fix**: The `_createMessageFromJson` method already parses photo paths. For pending messages, TDLib sets the local path to the file being uploaded. Verify this path is being extracted. If it's working, the issue may be that `PhotoMessageWidget` shows placeholder when `photoPath` is set but the file is still uploading — in which case, it should show the image with a sending overlay instead.

### 4. Add "Resend" option to context menu for failed messages

**Files**: Multiple changes needed:

**a) TDLib client** (`tdlib_telegram_client.dart`):
Add `resendMessages` method that calls TDLib's `resendMessages` API:
```dart
Future<void> resendMessages(int chatId, List<int> messageIds) async {
  await _sendRequest({
    '@type': 'resendMessages',
    'chat_id': chatId,
    'message_ids': messageIds,
  });
}
```

**b) Repository interface** (`telegram_client_repository.dart`):
Add `Future<void> resendMessages(int chatId, List<int> messageIds);`

**c) Message notifier** (`message_notifier.dart`):
Add `resendMessage` method:
```dart
Future<void> resendMessage(int chatId, int messageId) async {
  await _client.resendMessages(chatId, [messageId]);
}
```

**d) Message list context menu** (`message_list.dart`):
Add a "Resend" `ListTile` that only shows when `message.sendingState == MessageSendingState.failed`. Place it at the top of the menu (before Edit). Icon: `Icons.refresh`. On tap, call `notifier.resendMessage(chatId, messageId)`.

## Risks

- **TDLib `resendMessages` availability**: This is a standard TDLib API. If the message has been cleaned up by TDLib internally, the resend may fail silently. Mitigation: show error snackbar on failure.
- **Gallery refresh performance**: Calling `refresh()` on every resume reloads the entire asset list. This is acceptable since it only loads 50 items (first page). If needed, could debounce or only refresh if the user was away for more than a few seconds.
- **Photo preview for pending messages**: Need to verify TDLib actually populates the local path for pending photo messages. If not, will need the optimistic message approach (more complex).

## Open Questions

- None — all four changes are well-scoped and use existing patterns in the codebase.
