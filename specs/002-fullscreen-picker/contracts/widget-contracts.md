# Widget Contracts: Fullscreen Emoji/Sticker Picker

**Feature**: 002-fullscreen-picker | **Date**: 2026-01-14

## FullscreenEmojiPicker Widget

### Constructor Contract

```dart
class FullscreenEmojiPicker extends ConsumerStatefulWidget {
  /// Text controller for emoji insertion
  /// Required - emojis will be inserted at cursor position
  final TextEditingController textController;

  /// Chat ID for sticker sending functionality
  /// Required - needed for StickerTab
  final int chatId;

  /// Callback after emoji is inserted
  /// Optional - picker remains open after callback
  final VoidCallback? onEmojiSelected;

  /// Callback after sticker is sent
  /// Optional - picker typically closes after callback
  final VoidCallback? onStickerSent;

  const FullscreenEmojiPicker({
    super.key,
    required this.textController,
    required this.chatId,
    this.onEmojiSelected,
    this.onStickerSent,
  });
}
```

### Static Show Method Contract

```dart
/// Opens the fullscreen emoji picker as a modal bottom sheet
///
/// Returns a Future that completes when the picker is dismissed
/// The picker can be dismissed by:
/// - Tapping the close button
/// - Swiping down
/// - Pressing back button/gesture
/// - Calling Navigator.pop(context)
///
/// Example:
/// ```dart
/// await FullscreenEmojiPicker.show(
///   context,
///   textController: _textController,
///   chatId: chat.id,
/// );
/// ```
static Future<void> show(
  BuildContext context, {
  required TextEditingController textController,
  required int chatId,
  VoidCallback? onEmojiSelected,
  VoidCallback? onStickerSent,
});
```

## Responsive Behavior Contract

### Column Calculation

```dart
/// Calculate number of emoji columns based on screen width
///
/// Guarantees:
/// - Minimum 6 columns (phone portrait)
/// - Maximum 20 columns (large desktop)
/// - Consistent emoji size of 40-44px
///
/// Formula: ((screenWidth - 32) / emojiSize).floor().clamp(6, 20)
int _calculateColumns(BuildContext context);
```

### Screen Size Response

| Screen Type | Width Range | Columns | Emoji Size |
|-------------|-------------|---------|------------|
| Phone Portrait | 320-414px | 6-8 | 40px |
| Phone Landscape | 568-896px | 10-14 | 40px |
| Tablet Portrait | 768-834px | 14-16 | 40px |
| Tablet Landscape | 1024-1366px | 18-20 | 40px |
| Desktop | 1280px+ | 20 (max) | 40px |

## Gesture Contracts

### Dismiss Gestures

| Gesture | Expected Behavior |
|---------|-------------------|
| Swipe down on header | Dismiss picker |
| Swipe down on content | Scroll content, then dismiss if at top |
| Back button (Android) | Dismiss picker |
| Back gesture (iOS) | Dismiss picker |
| Close button tap | Dismiss picker |
| Tap outside modal | Dismiss picker (default) |

### Selection Gestures

| Gesture | Expected Behavior |
|---------|-------------------|
| Single tap emoji | Insert emoji, keep picker open |
| Long press emoji | No action (future: skin tone selector) |
| Single tap sticker | Send sticker, close picker |
| Swipe between tabs | Switch emoji/sticker tab |

## Animation Contracts

### Open Animation
- Duration: 300ms (Material default)
- Curve: Curves.easeOutCubic
- Direction: Slide up from bottom

### Close Animation
- Duration: 200ms (Material default)
- Curve: Curves.easeInCubic
- Direction: Slide down to bottom

### Tab Switch Animation
- Duration: 300ms
- Curve: Curves.easeInOut
- Type: Cross-fade with slide

## Error Handling Contract

| Scenario | Behavior |
|----------|----------|
| Text controller disposed | Graceful no-op on insert |
| Network error (stickers) | Show error in sticker tab |
| Empty search results | Show "No emojis found" message |
| Orientation change mid-animation | Complete animation, then rebuild |
