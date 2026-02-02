# Quickstart: Custom Emoji Rendering

**Feature**: 001-custom-emoji | **Date**: 2026-01-11

## Overview

This guide provides a quick reference for implementing Telegram-style custom emoji rendering.

---

## Key Files to Create

```
lib/
├── core/emoji/
│   ├── emoji_data.dart           # Static emoji metadata
│   ├── emoji_cache.dart          # File caching logic
│   └── emoji_asset_manager.dart  # TDLib integration
├── domain/entities/
│   └── emoji.dart                # Emoji entity class
├── data/repositories/
│   └── emoji_repository.dart     # Repository implementation
├── presentation/
│   ├── notifiers/emoji_notifier.dart
│   └── providers/emoji_providers.dart
└── widgets/
    ├── emoji_sticker/
    │   ├── telegram_emoji_widget.dart
    │   └── custom_emoji_picker.dart
    └── message/
        └── emoji_text.dart
```

---

## Step 1: Emoji Entity

```dart
// lib/domain/entities/emoji.dart

enum EmojiCategory {
  recent, smileys, people, animals, food,
  travel, activities, objects, symbols, flags
}

class Emoji {
  final String codepoint;
  final String name;
  final EmojiCategory category;
  final List<String> shortcodes;
  final bool hasAnimation;
  String? staticAssetPath;
  String? animatedAssetPath;

  Emoji({
    required this.codepoint,
    required this.name,
    required this.category,
    this.shortcodes = const [],
    this.hasAnimation = false,
    this.staticAssetPath,
    this.animatedAssetPath,
  });

  String get char => String.fromCharCodes(
    codepoint.split('-').map((c) => int.parse(c, radix: 16))
  );
}
```

---

## Step 2: Single Emoji Widget

```dart
// lib/widgets/emoji_sticker/telegram_emoji_widget.dart

class TelegramEmojiWidget extends ConsumerWidget {
  final String emoji;
  final double size;
  final bool animated;

  const TelegramEmojiWidget({
    required this.emoji,
    this.size = 24.0,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetPath = ref.watch(emojiAssetProvider(emoji));

    return assetPath.when(
      data: (path) => path != null
          ? _buildEmojiImage(path)
          : _buildFallback(),
      loading: () => _buildPlaceholder(),
      error: (_, __) => _buildFallback(),
    );
  }

  Widget _buildEmojiImage(String path) {
    if (path.endsWith('.tgs') && animated) {
      return Lottie.file(File(path), width: size, height: size);
    }
    return Image.file(File(path), width: size, height: size);
  }

  Widget _buildFallback() {
    return Text(emoji, style: TextStyle(fontSize: size * 0.8));
  }

  Widget _buildPlaceholder() {
    return SizedBox(width: size, height: size);
  }
}
```

---

## Step 3: Emoji Text Widget

```dart
// lib/widgets/message/emoji_text.dart

class EmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double emojiSize;

  const EmojiText({
    required this.text,
    this.style,
    this.emojiSize = 24.0,
  });

  static final _emojiRegex = RegExp(
    r'(\p{Emoji_Presentation}|\p{Extended_Pictographic})'
    r'(\u200d(\p{Emoji_Presentation}|\p{Extended_Pictographic}))*',
    unicode: true,
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans()),
      style: style,
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _emojiRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: TelegramEmojiWidget(
          emoji: match.group(0)!,
          size: emojiSize,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}
```

---

## Step 4: Riverpod Providers

```dart
// lib/presentation/providers/emoji_providers.dart

final emojiRepositoryProvider = Provider<EmojiRepository>((ref) {
  final client = ref.watch(telegramClientProvider);
  return TdlibEmojiRepository(client);
});

final emojiAssetProvider = FutureProvider.family<String?, String>(
  (ref, emoji) async {
    final repo = ref.watch(emojiRepositoryProvider);
    final codepoint = _emojiToCodepoint(emoji);
    return repo.getEmojiAssetPath(codepoint);
  },
);

final emojisByCategoryProvider = FutureProvider.family<List<Emoji>, EmojiCategory>(
  (ref, category) async {
    final repo = ref.watch(emojiRepositoryProvider);
    return repo.getEmojisByCategory(category);
  },
);

final recentEmojisProvider = FutureProvider<List<Emoji>>((ref) async {
  final repo = ref.watch(emojiRepositoryProvider);
  return repo.getRecentEmojis();
});
```

---

## Step 5: Integration Points

### Message Bubble

```dart
// In message_bubble.dart, replace:
Text(message.text, style: textStyle)

// With:
EmojiText(text: message.text, style: textStyle)
```

### Reaction Bar

```dart
// In reaction_bar.dart, replace:
Text(emoji, style: TextStyle(fontSize: 24))

// With:
TelegramEmojiWidget(emoji: emoji, size: 24)
```

### Emoji Picker Tab

```dart
// In emoji_tab.dart, replace EmojiPicker with CustomEmojiPicker
CustomEmojiPicker(
  onEmojiSelected: (emoji) {
    textController.text += emoji;
    onEmojiSelected?.call();
  },
)
```

---

## Step 6: Cache Management

```dart
// lib/core/emoji/emoji_cache.dart

class EmojiCache {
  final Directory cacheDir;
  final int maxSizeBytes;
  Map<String, EmojiCacheEntry> _entries = {};

  Future<String?> getCachedPath(String codepoint, {bool animated = false}) async {
    final entry = _entries[codepoint];
    if (entry == null) return null;

    // Update LRU timestamp
    entry.lastUsed = DateTime.now();
    await _saveMetadata();

    return animated ? entry.animatedPath : entry.staticPath;
  }

  Future<void> cacheAsset(String codepoint, String sourcePath, {bool animated = false}) async {
    await _ensureCacheSpace(File(sourcePath).lengthSync());

    final destPath = _getAssetPath(codepoint, animated);
    await File(sourcePath).copy(destPath);

    _entries[codepoint] = EmojiCacheEntry(
      codepoint: codepoint,
      staticPath: animated ? null : destPath,
      animatedPath: animated ? destPath : null,
      lastUsed: DateTime.now(),
    );
    await _saveMetadata();
  }

  Future<void> _ensureCacheSpace(int neededBytes) async {
    while (_totalSize + neededBytes > maxSizeBytes && _entries.isNotEmpty) {
      final oldest = _entries.values.reduce(
        (a, b) => a.lastUsed.isBefore(b.lastUsed) ? a : b
      );
      await _evict(oldest.codepoint);
    }
  }
}
```

---

## Testing Checklist

- [ ] Single emoji renders with custom image
- [ ] Animated emoji plays Lottie animation
- [ ] Text with emojis renders inline correctly
- [ ] Emoji picker shows custom-rendered emojis
- [ ] Recent emojis tab works
- [ ] Emoji search works
- [ ] Reactions display custom emojis
- [ ] Fallback to native emoji when asset unavailable
- [ ] Cache eviction works when full
- [ ] Offline mode uses cached assets

---

## Performance Tips

1. **Preload on startup**: Call `repo.preloadCommonEmojis()` in main()
2. **Fixed dimensions**: Always specify size for emoji widgets
3. **Disable animations**: Set `animated: false` in battery saver mode
4. **Lazy loading**: Emojis in non-visible messages won't load

---

## Dependencies

Already in pubspec.yaml:
- `lottie: ^3.3.2` - For TGS animations
- `path_provider: ^2.1.0` - For cache directory
- `flutter_riverpod: ^3.0.3` - State management
