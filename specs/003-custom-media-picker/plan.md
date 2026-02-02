# Plan: Custom Media Attachment Picker

**Spec**: specs/003-custom-media-picker/spec.md

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- New dependencies: `photo_manager` (gallery access), `photo_manager_image_provider` (thumbnails)
- Existing: `image_picker` (camera), `file_picker` (documents), `flutter_riverpod` (state)

## Structure

New and modified files:

```
lib/
├── widgets/
│   └── message/
│       ├── message_input_area.dart          # MODIFY - replace bottom sheet with panel
│       └── media_picker/                    # NEW
│           ├── media_picker_panel.dart       # Main panel widget (slides up)
│           ├── media_grid.dart              # Scrollable thumbnail grid
│           └── media_thumbnail.dart         # Single grid item with selection badge
├── presentation/
│   ├── providers/
│   │   └── media_picker_provider.dart       # NEW - asset loading provider
│   └── notifiers/
│       └── message_notifier.dart            # MODIFY - add sendAlbum method
├── data/
│   └── repositories/
│       └── tdlib_telegram_client.dart       # MODIFY - add sendMessageAlbum
└── domain/
    └── repositories/
        └── telegram_client_repository.dart  # MODIFY - add sendMessageAlbum interface
```

## Approach

### 1. Add dependencies

Add `photo_manager` and `photo_manager_image_provider` to pubspec.yaml. These give direct access to device media without a system picker UI.

### 2. Build the media picker panel (`media_picker_panel.dart`)

A bottom panel that slides up when the user taps the attachment button. Replaces the current `showModalBottomSheet` in `message_input_area.dart`.

Layout (top to bottom):
- **Drag handle** at the top for swipe-to-dismiss
- **Action row**: Camera button + Document button + send button (shows selection count when items selected)
- **Media grid**: scrollable grid of device photos/videos

The panel covers roughly the bottom 40-50% of the screen (like Telegram). Dismissible by swiping down or tapping outside.

### 3. Load device media (`media_picker_provider.dart`)

Use `photo_manager` to load recent media:
- `PhotoManager.requestPermissionExtend()` to get permission
- `PhotoManager.getAssetPathList(onlyAll: true)` to get the "Recent" album
- `path.getAssetListPaged(page: 0, size: 50)` for initial load
- Load more pages as user scrolls (pagination)
- Filter to photos and videos only (`RequestType.image | RequestType.video`)

Provider exposes:
- `List<AssetEntity>` of loaded assets
- Permission state (granted, denied, limited)
- Loading state
- `loadMore()` method for pagination

### 4. Build the media grid (`media_grid.dart`)

A `GridView.builder` with 3 columns showing thumbnails.

Each item:
- `AssetEntityImage` widget with `thumbnailSize: ThumbnailSize.square(200)` for efficient loading
- Video items show a duration overlay (bottom-right corner, white text on dark background)
- Tappable to select/deselect

Selection state managed locally in the panel widget (list of selected `AssetEntity` objects, max 10).

### 5. Build media thumbnail (`media_thumbnail.dart`)

Single grid cell widget:
- Thumbnail image fills the cell
- If video: duration label overlay (e.g., "0:34") at bottom-right
- If selected: blue circle overlay at top-right with selection number (1, 2, 3...)
- If selected: slight dark overlay or border to indicate selection

### 6. Selection and send logic

Selection state lives in the panel widget:
- `List<AssetEntity> selectedItems` (ordered by selection time)
- Tap to toggle. If already selected, remove and renumber. If 10 selected, show snackbar.
- Send button appears/updates when items are selected, showing count

On send:
- Get file paths via `asset.file` for each selected item
- Determine type: `asset.type == AssetType.video` → sendVideo, else → sendPhoto
- If single item: use existing `sendPhoto`/`sendVideo`
- If multiple items: use new `sendMessageAlbum` (or send individually in sequence as fallback)
- Caption from the existing text input field attaches to the first item

### 7. Add sendMessageAlbum to TDLib client

TDLib supports `sendMessageAlbum` natively. Add to:

**Repository interface** (`telegram_client_repository.dart`):
```dart
Future<void> sendMessageAlbum(int chatId, List<(String path, bool isVideo)> items, {String? caption, int? replyToMessageId});
```

**TDLib implementation** (`tdlib_telegram_client.dart`):
```dart
// Build array of inputMessageContent objects
// First item gets the caption, rest have no caption
// Call sendMessageAlbum with the array
```

**Message notifier** (`message_notifier.dart`):
```dart
Future<void> sendAlbum(int chatId, List<(String path, bool isVideo)> items, {String? caption});
```

### 8. Modify message_input_area.dart

Replace `_showAttachmentOptions()` (the current `showModalBottomSheet`) with showing the new `MediaPickerPanel`. The panel can be shown as a `DraggableScrollableSheet` inside a bottom sheet, or as an overlay/panel at the bottom.

Camera and Document buttons move into the panel's action row. Their behavior stays the same (open system camera / file picker).

### 9. Handle permissions

On first panel open:
- Call `PhotoManager.requestPermissionExtend()`
- If `PermissionState.authorized` or `PermissionState.limited`: load media
- If `PermissionState.denied`: show message with "Open Settings" button (`PhotoManager.openSetting()`)
- On Linux desktop: skip gallery, show only Camera and Document buttons

### 10. Linux desktop fallback

Check `Platform.isLinux` (or `!Platform.isAndroid && !Platform.isIOS`). On desktop, the panel shows only Camera and Document buttons with a message like "Gallery not available on desktop." No `photo_manager` calls.

## Risks

- **photo_manager permission on Android 14+**: Recent Android versions have stricter media access. `photo_manager` handles this via `requestPermissionExtend()` which returns `limited` access on Android 14+. Limited access still works for browsing — user just sees a subset.
  Mitigation: Handle `limited` state same as `authorized`.

- **Thumbnail loading performance**: Loading many thumbnails at once can be slow.
  Mitigation: Use `AssetEntityImage` with small `ThumbnailSize` (200x200), paginate grid loading (50 items per page), and rely on `photo_manager`'s built-in caching (Glide on Android).

- **sendMessageAlbum error handling**: Album send may partially fail.
  Mitigation: If album send fails, fall back to sending items one by one.

- **Large video files**: `asset.file` copies the video to a temp path which can be slow for large files.
  Mitigation: Show a loading indicator while preparing files for send.
