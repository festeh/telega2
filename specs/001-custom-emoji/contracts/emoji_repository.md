# Contract: EmojiRepository

**Feature**: 001-custom-emoji | **Date**: 2026-01-11

## Overview

Repository interface for managing emoji assets - loading, caching, and providing emoji data for rendering.

---

## Interface Definition

```dart
abstract class EmojiRepository {
  /// Get all emojis in a category
  Future<List<Emoji>> getEmojisByCategory(EmojiCategory category);

  /// Get emoji by codepoint
  Future<Emoji?> getEmoji(String codepoint);

  /// Search emojis by name or shortcode
  Future<List<Emoji>> searchEmojis(String query);

  /// Get recent/frequently used emojis
  Future<List<Emoji>> getRecentEmojis({int limit = 30});

  /// Record emoji usage (updates recent list)
  Future<void> recordEmojiUsage(String codepoint);

  /// Get cached asset path for emoji (downloads if needed)
  Future<String?> getEmojiAssetPath(String codepoint, {bool animated = false});

  /// Preload common emojis into cache
  Future<void> preloadCommonEmojis();

  /// Get current cache size in bytes
  Future<int> getCacheSize();

  /// Clear emoji cache
  Future<void> clearCache();

  /// Stream of cache status updates
  Stream<EmojiCacheStatus> get cacheStatusStream;
}
```

---

## Methods

### getEmojisByCategory

**Purpose**: Retrieve all emojis for a picker category tab.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| category | EmojiCategory | Yes | Category to fetch |

**Returns**: `Future<List<Emoji>>` - Emojis in display order

**Errors**:
- None expected - returns empty list if category unknown

---

### getEmoji

**Purpose**: Get a single emoji by its Unicode codepoint.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| codepoint | String | Yes | Unicode codepoint (e.g., "1F600") |

**Returns**: `Future<Emoji?>` - Emoji or null if not found

---

### searchEmojis

**Purpose**: Search emojis by name or shortcode for picker search.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| query | String | Yes | Search term |

**Returns**: `Future<List<Emoji>>` - Matching emojis, sorted by relevance

**Behavior**:
- Case-insensitive matching
- Matches against `name` and `shortcodes`
- Returns max 50 results
- Empty query returns empty list

---

### getRecentEmojis

**Purpose**: Get user's recently used emojis for picker "Recent" tab.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| limit | int | No | 30 | Max emojis to return |

**Returns**: `Future<List<Emoji>>` - Recent emojis, most recent first

---

### recordEmojiUsage

**Purpose**: Record that user selected an emoji (for recent tracking).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| codepoint | String | Yes | Emoji that was used |

**Returns**: `Future<void>`

**Behavior**:
- Increments use count
- Updates lastUsed timestamp
- Persists to storage

---

### getEmojiAssetPath

**Purpose**: Get local file path for emoji asset, downloading if necessary.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| codepoint | String | Yes | - | Emoji codepoint |
| animated | bool | No | false | Request animated version |

**Returns**: `Future<String?>` - Local file path or null if unavailable

**Behavior**:
1. Check cache for existing file
2. If not cached, initiate TDLib download
3. Wait for download completion
4. Return local file path
5. Return null if download fails or emoji doesn't exist

---

### preloadCommonEmojis

**Purpose**: Background preload of frequently used emojis.

**Returns**: `Future<void>`

**Behavior**:
- Downloads top 100 most common emojis
- Non-blocking, errors are logged but not thrown
- Should be called on app startup

---

### getCacheSize

**Purpose**: Get current disk usage of emoji cache.

**Returns**: `Future<int>` - Size in bytes

---

### clearCache

**Purpose**: Delete all cached emoji assets.

**Returns**: `Future<void>`

**Behavior**:
- Deletes all files in cache directory
- Resets cache metadata
- Does not clear recent emoji history

---

### cacheStatusStream

**Purpose**: Stream updates about cache operations.

**Returns**: `Stream<EmojiCacheStatus>`

```dart
class EmojiCacheStatus {
  final int totalEmojis;
  final int cachedEmojis;
  final int cacheSizeBytes;
  final String? currentlyDownloading; // codepoint or null
}
```

---

## Data Types

### Emoji

```dart
class Emoji {
  final String codepoint;
  final String name;
  final EmojiCategory category;
  final List<String> shortcodes;
  final bool skinToneSupport;
  final bool hasAnimation;
  final String? staticAssetPath;
  final String? animatedAssetPath;
}
```

### EmojiCategory

```dart
enum EmojiCategory {
  recent,
  smileys,
  people,
  animals,
  food,
  travel,
  activities,
  objects,
  symbols,
  flags,
}
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Network unavailable | Return cached asset or null |
| TDLib not initialized | Throw StateError |
| Invalid codepoint | Return null |
| Cache full | Evict LRU entries, then cache |
| File I/O error | Log error, return null |
