# Contract: Emoji Widgets

**Feature**: 001-custom-emoji | **Date**: 2026-01-11

## Overview

Widget contracts for rendering custom Telegram-style emojis.

---

## TelegramEmojiWidget

Single emoji renderer that displays custom Telegram emoji image.

### Constructor

```dart
const TelegramEmojiWidget({
  required String emoji,      // Unicode emoji character or codepoint
  double size = 24.0,         // Display size in logical pixels
  bool animated = true,       // Play animation if available
  VoidCallback? onTap,        // Optional tap handler
  Widget? placeholder,        // Widget shown while loading
  Widget? errorWidget,        // Widget shown on load failure
})
```

### Behavior

| State | Display |
|-------|---------|
| Loading | `placeholder` or shimmer effect |
| Loaded (static) | WebP/PNG image |
| Loaded (animated) | Lottie animation |
| Error | `errorWidget` or native emoji fallback |

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| emoji | String | required | Emoji to render |
| size | double | 24.0 | Width and height |
| animated | bool | true | Enable animations |
| onTap | VoidCallback? | null | Tap callback |
| placeholder | Widget? | null | Loading placeholder |
| errorWidget | Widget? | null | Error fallback |

---

## EmojiText

Rich text widget that replaces Unicode emojis with custom rendered images.

### Constructor

```dart
const EmojiText({
  required String text,           // Text containing emojis
  TextStyle? style,               // Base text style
  double emojiSize = 24.0,        // Size for emoji images
  bool animateEmojis = true,      // Enable emoji animations
  TextAlign textAlign = TextAlign.start,
  int? maxLines,
  TextOverflow overflow = TextOverflow.clip,
})
```

### Behavior

1. Parse input text to find emoji codepoints
2. Split into segments: text and emoji
3. Build `TextSpan` with `WidgetSpan` for each emoji
4. Render via `Text.rich`

### Example

```dart
// Input
EmojiText(text: "Hello 👋 World 🌍!")

// Renders as
Text.rich(TextSpan(children: [
  TextSpan(text: "Hello "),
  WidgetSpan(child: TelegramEmojiWidget(emoji: "👋", size: 24)),
  TextSpan(text: " World "),
  WidgetSpan(child: TelegramEmojiWidget(emoji: "🌍", size: 24)),
  TextSpan(text: "!"),
]))
```

---

## CustomEmojiPicker

Full emoji picker with custom rendering, replacing native emoji_picker_flutter.

### Constructor

```dart
const CustomEmojiPicker({
  required void Function(String emoji) onEmojiSelected,
  double height = 250.0,
  bool showSearchBar = true,
  bool showCategoryTabs = true,
  bool showRecentTab = true,
  EmojiCategory initialCategory = EmojiCategory.recent,
})
```

### Structure

```
┌─────────────────────────────────┐
│ [🔍 Search emojis...]          │ ← Search bar (optional)
├─────────────────────────────────┤
│ 🕐 😀 👤 🐱 🍔 ✈️ ⚽ 💡 ♠️ 🏁 │ ← Category tabs
├─────────────────────────────────┤
│ ┌───┬───┬───┬───┬───┬───┬───┐  │
│ │😀 │😃 │😄 │😁 │😆 │😅 │🤣 │  │ ← Emoji grid
│ ├───┼───┼───┼───┼───┼───┼───┤  │   (custom rendered)
│ │😂 │🙂 │🙃 │😉 │😊 │😇 │🥰 │  │
│ └───┴───┴───┴───┴───┴───┴───┘  │
└─────────────────────────────────┘
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| onEmojiSelected | Function(String) | required | Callback when emoji tapped |
| height | double | 250.0 | Picker height |
| showSearchBar | bool | true | Show search input |
| showCategoryTabs | bool | true | Show category navigation |
| showRecentTab | bool | true | Include recent emojis tab |
| initialCategory | EmojiCategory | recent | Starting category |

---

## ReactionPicker

Quick emoji picker for message reactions.

### Constructor

```dart
const ReactionPicker({
  required void Function(String emoji) onReactionSelected,
  List<String>? quickReactions,   // Default quick reaction emojis
  bool showExpandButton = true,   // Show "..." to open full picker
})
```

### Structure

```
┌─────────────────────────────────┐
│ 👍  ❤️  😂  😮  😢  😡  [...]   │
└─────────────────────────────────┘
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| onReactionSelected | Function(String) | required | Reaction selected callback |
| quickReactions | List\<String\>? | null | Custom quick reactions (default: 👍❤️😂😮😢😡) |
| showExpandButton | bool | true | Show expand to full picker |

---

## ReactionDisplay

Displays reactions on a message with custom emoji rendering.

### Constructor

```dart
const ReactionDisplay({
  required List<MessageReaction> reactions,
  void Function(String emoji)? onReactionTap,
  bool compact = false,
})
```

### MessageReaction

```dart
class MessageReaction {
  final String emoji;
  final int count;
  final bool isSelected;  // Current user reacted with this
}
```

### Structure

```
Normal:
┌───────┬───────┬───────┐
│ 👍 5  │ ❤️ 3  │ 😂 2  │
└───────┴───────┴───────┘

Compact:
👍5 ❤️3 😂2
```

---

## Integration Points

### Message Bubble

Replace text rendering in `message_bubble.dart`:

```dart
// Before
Text(message.text)

// After
EmojiText(text: message.text, style: textStyle)
```

### Reaction Bar

Replace reaction display in `reaction_bar.dart`:

```dart
// Before
Text(emoji, style: TextStyle(fontSize: 24))

// After
TelegramEmojiWidget(emoji: emoji, size: 24)
```

### Emoji Tab

Replace picker in `emoji_tab.dart`:

```dart
// Before
EmojiPicker(...)  // emoji_picker_flutter

// After
CustomEmojiPicker(onEmojiSelected: ...)
```
