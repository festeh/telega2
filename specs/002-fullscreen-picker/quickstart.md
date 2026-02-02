# Quickstart: Fullscreen Emoji/Sticker Picker

**Feature**: 002-fullscreen-picker | **Date**: 2026-01-14

## Overview

Transform the inline emoji picker into a fullscreen modal for improved browsing experience.

## Prerequisites

- Flutter SDK 3.x
- Existing emoji picker infrastructure (CustomEmojiPicker, EmojiGrid)
- Development environment set up per project README

## Quick Implementation Guide

### Step 1: Create Fullscreen Wrapper Widget

Create `lib/widgets/emoji_sticker/fullscreen_emoji_picker.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_emoji_picker.dart';
import 'sticker_tab.dart';

class FullscreenEmojiPicker extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final int chatId;
  final VoidCallback? onEmojiSelected;
  final VoidCallback? onStickerSent;

  const FullscreenEmojiPicker({
    super.key,
    required this.textController,
    required this.chatId,
    this.onEmojiSelected,
    this.onStickerSent,
  });

  /// Show the fullscreen picker as a modal
  static Future<void> show(
    BuildContext context, {
    required TextEditingController textController,
    required int chatId,
    VoidCallback? onEmojiSelected,
    VoidCallback? onStickerSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullscreenEmojiPicker(
        textController: textController,
        chatId: chatId,
        onEmojiSelected: onEmojiSelected,
        onStickerSent: onStickerSent,
      ),
    );
  }

  @override
  ConsumerState<FullscreenEmojiPicker> createState() =>
      _FullscreenEmojiPickerState();
}

class _FullscreenEmojiPickerState extends ConsumerState<FullscreenEmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final availableWidth = width - 32; // 16px padding each side
    const emojiSize = 44.0;
    return (availableWidth / emojiSize).floor().clamp(6, 20);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final columns = _calculateColumns(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  'Emoji & Stickers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balance close button
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Emoji'),
              Tab(icon: Icon(Icons.sticky_note_2_outlined), text: 'Stickers'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CustomEmojiPicker(
                  textController: widget.textController,
                  onEmojiSelected: (emoji) {
                    widget.onEmojiSelected?.call();
                  },
                  columns: columns,
                  emojiSize: 40,
                  showBackspace: true,
                  showSearch: true,
                  showRecents: true,
                ),
                StickerTab(
                  chatId: widget.chatId,
                  onStickerSent: () {
                    widget.onStickerSent?.call();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 2: Modify MessageInputArea Trigger

In `lib/widgets/message/message_input_area.dart`, update `_showEmojiPicker()`:

```dart
void _showEmojiPicker() {
  FullscreenEmojiPicker.show(
    context,
    textController: _textController,
    chatId: widget.chat.id,
    onEmojiSelected: () {
      // Keep picker open for multiple selections
    },
    onStickerSent: () {
      // Picker auto-closes on sticker send
    },
  );
}
```

### Step 3: Test

```bash
# Run the app
flutter run -d linux

# Navigate to any chat
# Tap emoji button in message input
# Verify fullscreen picker opens
# Test emoji selection, search, categories
# Test dismiss gestures (swipe down, back button, close button)
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/widgets/emoji_sticker/fullscreen_emoji_picker.dart` | New fullscreen wrapper |
| `lib/widgets/message/message_input_area.dart` | Trigger modification |
| `lib/widgets/emoji_sticker/custom_emoji_picker.dart` | Existing picker (reused) |

## Success Criteria Verification

- [ ] SC-001: Transition completes within 300ms (Material default)
- [ ] SC-002: 6+ columns on phone, 10+ on tablet
- [ ] SC-003: Single tap selects emoji
- [ ] SC-004: Search finds emojis quickly
- [ ] SC-005: Orientation changes handled
- [ ] SC-006: Search results appear within 100ms
