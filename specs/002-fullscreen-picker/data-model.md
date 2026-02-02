# Data Model: Fullscreen Emoji/Sticker Picker

**Feature**: 002-fullscreen-picker | **Date**: 2026-01-14

## Overview

This feature is primarily a UI enhancement with minimal data model changes. The existing emoji/sticker data structures remain unchanged.

## Existing Data Structures (Unchanged)

### Emoji Entity
```dart
// lib/domain/entities/emoji.dart (existing)
class Emoji {
  final String char;      // Unicode character
  final String codepoint; // Codepoint string (e.g., "1F600")
  final String name;      // Emoji name for search
}
```

### EmojiCategory Enum
```dart
// lib/core/emoji/emoji_data.dart (existing)
enum EmojiCategory {
  recent, smileys, people, animals, food,
  travel, activities, objects, symbols, flags
}
```

### EmojiStickerState
```dart
// lib/presentation/state/emoji_sticker_state.dart (existing)
class EmojiStickerState {
  final bool isPickerVisible;
  final PickerTab selectedTab;
  final double keyboardHeight;
  final List<StickerSet> installedStickerSets;
  final List<Sticker> recentStickers;
}
```

## New/Modified Structures

### FullscreenPickerConfig (New - Optional Helper)

If needed for cleaner code, a simple config class:

```dart
/// Configuration for fullscreen emoji picker display
class FullscreenPickerConfig {
  final int columns;
  final double emojiSize;
  final bool showSearch;
  final bool showCategories;

  const FullscreenPickerConfig({
    required this.columns,
    this.emojiSize = 40.0,
    this.showSearch = true,
    this.showCategories = true,
  });

  /// Calculate optimal config based on screen dimensions
  factory FullscreenPickerConfig.responsive(Size screenSize) {
    final width = screenSize.width;
    final padding = 32.0; // 16px each side
    final availableWidth = width - padding;
    final emojiSize = 40.0;
    final columns = (availableWidth / emojiSize).floor().clamp(6, 20);

    return FullscreenPickerConfig(
      columns: columns,
      emojiSize: emojiSize,
    );
  }
}
```

## State Modifications

No state modifications required. The fullscreen modal will:
1. Receive `TextEditingController` from parent
2. Call callback when emoji selected
3. Be dismissed via Navigator.pop()

The existing `isPickerVisible` state is not needed for fullscreen mode since the modal manages its own visibility.

## Data Flow

```
MessageInputArea
    │
    ├─► User taps emoji button
    │
    ├─► showModalBottomSheet() opens FullscreenEmojiPicker
    │       │
    │       ├─► Displays CustomEmojiPicker (responsive columns)
    │       │
    │       ├─► User taps emoji
    │       │       │
    │       │       └─► onEmojiSelected callback
    │       │               │
    │       │               └─► Inserts into TextEditingController
    │       │
    │       └─► User dismisses (swipe/back/close button)
    │               │
    │               └─► Navigator.pop()
    │
    └─► MessageInputArea retains focus, picker closed
```

## Responsive Grid Calculation

| Screen Width | Columns | Emoji Size | Total Grid Width |
|--------------|---------|------------|------------------|
| 320px | 6 | 40px | 240px |
| 375px | 7 | 40px | 280px |
| 414px | 8 | 40px | 320px |
| 768px | 14 | 40px | 560px |
| 1024px | 20 | 40px | 800px |

Formula:
```dart
columns = ((screenWidth - 32) / 40).floor().clamp(6, 20)
```

## No Database Changes

This feature does not introduce any new persistent storage. Recent emojis continue to use the existing `EmojiRepository.recordEmojiUsage()` mechanism.
