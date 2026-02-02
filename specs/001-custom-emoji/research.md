# Research: Custom Emoji Rendering

**Feature**: 001-custom-emoji | **Date**: 2026-01-11

## Summary

This document consolidates research findings for implementing Telegram-style custom emoji rendering in a Flutter app.

---

## 1. Emoji Asset Source

### Decision: Use TDLib API + Bundled Fallback

**Rationale**: Since this is a Telegram client using TDLib, the official API is the correct and licensed approach for obtaining emoji assets.

### TDLib Methods Available

| Method | Purpose |
|--------|---------|
| `getAnimatedEmoji(emoji)` | Get animated emoji for standard Unicode emoji |
| `getStickerSet` with `inputStickerSetAnimatedEmoji` | Fetch full animated emoji sticker set |
| `downloadFile(fileId)` | Download actual sticker/emoji files |
| `updateFile` events | Receive download progress/completion |

### Asset Formats

| Type | Format | Resolution | Max Size | Notes |
|------|--------|------------|----------|-------|
| Static | PNG/WebP | 100x100 | - | Simple images |
| Animated | TGS (gzip Lottie) | 512x512 | 64KB | Up to 60fps, loops |
| Video | WebM (VP9) | 100x100 | 256KB | Up to 30fps, no audio |

### Fallback Strategy

Bundle a subset of common emojis (Noto Color Emoji, open source) for:
- First-run experience before cache is populated
- Offline use when emoji hasn't been downloaded yet

**Alternatives Considered**:
- Bundle all Telegram emojis: Rejected due to licensing (Apple-derived) and app size
- Use only native emojis: Rejected - defeats the purpose of cross-platform consistency

---

## 2. Inline Text Rendering

### Decision: WidgetSpan with RichText

**Rationale**: Flutter's native `WidgetSpan` allows embedding any widget (including images) inline with text flow. No external dependencies needed.

### Implementation Approach

```dart
Text.rich(
  TextSpan(
    children: [
      TextSpan(text: 'Hello '),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Image.file(emojiFile, width: 24, height: 24),
      ),
      TextSpan(text: ' world!'),
    ],
  ),
)
```

### Key Considerations

1. **Alignment**: Use `PlaceholderAlignment.middle` for proper vertical centering
2. **Fixed dimensions**: Always specify width/height to avoid layout thrashing
3. **Caching**: Use `Image.file` for cached emojis, pre-load into memory if needed

### Emoji Detection

Use regex to find emoji codepoints in text:

```dart
final emojiRegex = RegExp(
  r'(\p{Emoji_Presentation}|\p{Extended_Pictographic})(\u200d(\p{Emoji_Presentation}|\p{Extended_Pictographic}))*',
  unicode: true,
);
```

**Alternatives Considered**:
- `extended_text` package: More features but adds dependency for something Flutter can do natively
- Custom `TextPainter`: Too low-level, WidgetSpan solves the problem

---

## 3. Animation Rendering

### Decision: lottie package (already in deps)

**Rationale**: Project already uses `lottie: ^3.3.2`. TGS files are gzip-compressed Lottie JSON and can be rendered directly.

### Implementation

```dart
// For TGS files (gzip Lottie)
Lottie.file(
  File(tgsPath),
  width: 24,
  height: 24,
  repeat: true,
)

// For network/memory
Lottie.memory(tgsBytes)
```

### Performance Notes

- Use `repeat: true` for looping animations
- Set explicit dimensions
- Consider `frameRate: FrameRate.max` for smooth 60fps
- Disable animations in battery saver mode

**Alternatives Considered**:
- `lottie_tgs` package: More explicit TGS support but `lottie` handles it fine
- WebM via `video_player`: Already in deps, use for video emoji format

---

## 4. Caching Strategy

### Decision: File-based cache with LRU eviction

**Rationale**: Simple, persistent, leverages TDLib's file management.

### Cache Structure

```
{app_documents}/emoji_cache/
├── static/
│   └── {codepoint}.webp
├── animated/
│   └── {codepoint}.tgs
└── metadata.json  # codepoint -> file mapping, LRU timestamps
```

### Cache Policy

| Parameter | Value | Notes |
|-----------|-------|-------|
| Max size | 50MB | Configurable |
| Eviction | LRU | Remove least recently used when full |
| TTL | None | Emojis don't change, cache indefinitely |
| Preload | Top 100 emojis | Most common emojis cached on first run |

### Integration with TDLib

TDLib manages its own file downloads. We'll:
1. Track emoji file IDs in our cache metadata
2. Use `downloadFile` to request downloads
3. Listen to `updateFile` for completion
4. Copy/reference the cached file path from TDLib

**Alternatives Considered**:
- In-memory only: Rejected - loses cache on app restart
- SQLite: Overkill for simple codepoint→file mapping

---

## 5. Emoji Picker

### Decision: Custom picker replacing emoji_picker_flutter

**Rationale**: Current `emoji_picker_flutter` uses native fonts. Need to replace grid items with custom-rendered emoji images.

### Approach

1. Keep category structure and search from existing picker
2. Replace emoji grid items with `TelegramEmojiWidget`
3. Maintain recent/frequently used tracking

### Data Source

Use static emoji data (codepoints, names, categories) from:
- Unicode CLDR data (open source)
- Or extract from `emoji_picker_flutter` internals

**Alternatives Considered**:
- Fork `emoji_picker_flutter`: More maintenance burden
- Build from scratch: Unnecessary, can wrap existing category/search logic

---

## 6. Reaction Emojis

### Decision: Same rendering pipeline as message emojis

**Rationale**: Reactions are just emojis in a different context. Reuse `TelegramEmojiWidget`.

### Integration Points

| Component | Change |
|-----------|--------|
| `reaction_bar.dart` | Replace `Text(emoji)` with `TelegramEmojiWidget` |
| Reaction picker | Use same custom emoji grid as main picker |
| Reaction counts | Show emoji image + count |

---

## 7. Performance Optimizations

### Preloading

```dart
// On app start, preload common emojis
final commonEmojis = ['😀', '❤️', '👍', '😂', ...];
for (final emoji in commonEmojis) {
  emojiCache.preload(emoji);
}
```

### ListView Optimization

- Use `ListView.builder` for messages (already done)
- Emojis in visible messages render on-demand
- Use `RepaintBoundary` sparingly for complex emoji-heavy messages

### First-Run Mitigation

Known Flutter issue: first emoji render is slow. Mitigate by:
1. Rendering invisible emoji during splash screen
2. Using bundled fallback images (no font rendering delay)

---

## Package Dependencies

### Required (already in pubspec.yaml)

- `lottie: ^3.3.2` - Animated emoji (TGS) rendering
- `path_provider: ^2.1.0` - Cache directory access
- `video_player: ^2.9.3` - WebM emoji format (if used)

### Potentially Useful

| Package | Purpose | Decision |
|---------|---------|----------|
| `cached_network_image` | Image caching | Not needed - using file cache |
| `emoji_regex` | Emoji detection | Not needed - simple regex sufficient |
| `extended_text` | Rich text features | Not needed - WidgetSpan sufficient |

---

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| Where do emoji assets come from? | TDLib API (official, licensed) |
| How to render inline with text? | WidgetSpan in RichText |
| How to handle animations? | lottie package (already available) |
| How to cache? | File-based with LRU eviction |
| What about reactions? | Same rendering system |

---

## References

- [TDLib animatedEmoji API](https://core.telegram.org/tdlib/docs/classtd_1_1td__api_1_1animated_emoji.html)
- [Telegram Animated Emojis](https://core.telegram.org/api/animated-emojis)
- [Flutter WidgetSpan](https://api.flutter.dev/flutter/widgets/WidgetSpan-class.html)
- [lottie package](https://pub.dev/packages/lottie)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
