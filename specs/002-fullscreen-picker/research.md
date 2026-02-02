# Research: Fullscreen Emoji/Sticker Picker

**Feature**: 002-fullscreen-picker | **Date**: 2026-01-14

## Existing Codebase Analysis

### Current Implementation

The emoji picker is currently implemented as an **inline widget** below the message input:

1. **EmojiStickerPicker** (`lib/widgets/emoji_sticker/emoji_sticker_picker.dart`)
   - Container with TabBar (Emoji/Stickers tabs)
   - Fixed height based on keyboard height (default 300px)
   - Displayed conditionally when `isPickerVisible` is true

2. **CustomEmojiPicker** (`lib/widgets/emoji_sticker/custom_emoji_picker.dart`)
   - Full-featured picker with 10 category tabs
   - Configurable parameters: `columns` (default 8), `emojiSize` (default 32)
   - Built-in search functionality
   - Recent emojis tracking

3. **MessageInputArea** (`lib/widgets/message/message_input_area.dart`)
   - Contains the emoji button trigger (line 336-364)
   - `_showEmojiPicker()` toggles visibility via Riverpod state
   - Picker rendered inline in Column (lines 139-154)

### Existing Modal Patterns

The codebase already uses fullscreen modals in several places:

1. **Attachment Options** (`message_input_area.dart:422-476`)
   ```dart
   showModalBottomSheet(
     context: context,
     builder: (context) => SafeArea(child: Container(...))
   )
   ```

2. **Reaction Picker** (`lib/widgets/message/reaction_picker.dart:198-208`)
   ```dart
   showModalBottomSheet(
     context: context,
     isScrollControlled: true,  // Allows fullscreen
     shape: RoundedRectangleBorder(...),
     builder: (context) => DraggableScrollableSheet(...)
   )
   ```

3. **Basic Emoji Picker** (`lib/widgets/emoji_sticker/basic_emoji_picker.dart:291-330`)
   - QuickEmojiButton uses `showModalBottomSheet` with `isScrollControlled: true`
   - Uses `DraggableScrollableSheet` for variable height

### State Management

- **emojiStickerProvider** (NotifierProvider)
  - `EmojiStickerState`: isPickerVisible, selectedTab, keyboardHeight
  - Methods: showPicker(), hidePicker(), togglePicker(), selectTab()

## Flutter Fullscreen Modal Options

### Option 1: showModalBottomSheet with isScrollControlled (Recommended)

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => SizedBox(
    height: MediaQuery.of(context).size.height,
    child: FullscreenEmojiPicker(...),
  ),
);
```

**Pros**: Simple, maintains parent context, supports swipe dismiss
**Cons**: Technically a bottom sheet (enters from bottom)

### Option 2: Navigator.push with fullscreenDialog

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => FullscreenEmojiPicker(...),
  ),
);
```

**Pros**: True fullscreen, standard navigation
**Cons**: Loses parent context (need to pass text controller callback)

### Option 3: OverlayEntry

**Pros**: Most flexible positioning
**Cons**: Complex lifecycle management, overkill for this use case

**Decision**: Use **Option 1** (showModalBottomSheet) as it:
- Matches existing patterns in the codebase
- Maintains text controller reference
- Supports gesture dismissal natively
- Simpler implementation

## Responsive Grid Calculation

Current CustomEmojiPicker uses fixed columns (8). For fullscreen:

```dart
int calculateColumns(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final emojiSize = 40.0; // Larger for fullscreen
  final padding = 16.0;
  final availableWidth = width - (padding * 2);

  // Minimum 6 columns on phone, more on larger screens
  return max(6, (availableWidth / emojiSize).floor());
}
```

| Screen Width | Columns | Emoji Size |
|--------------|---------|------------|
| 360px (phone) | 6 | 40px |
| 414px (large phone) | 7 | 40px |
| 768px (tablet) | 12 | 40px |
| 1024px+ (desktop) | 16+ | 40px |

## Gesture Support

Flutter's `showModalBottomSheet` with `isScrollControlled: true` automatically supports:
- Swipe down to dismiss
- Back button/gesture dismissal
- Tap outside to dismiss (can be disabled with `isDismissible: false`)

Additional handling needed:
- Android hardware back button: `WillPopScope` or `PopScope`

## Performance Considerations

- **Grid virtualization**: EmojiGrid likely uses ListView.builder (verify)
- **Animation**: Use standard Material animation (300ms)
- **Search debounce**: Already implemented in EmojiSearchWidget (100ms)

## Conclusion

This is a straightforward UI enhancement:
1. Create `FullscreenEmojiPicker` wrapper widget
2. Modify `_showEmojiPicker()` to use `showModalBottomSheet`
3. Add responsive column calculation to CustomEmojiPicker
4. Add header with close button to fullscreen variant

No architectural changes needed. Estimated complexity: Low.
