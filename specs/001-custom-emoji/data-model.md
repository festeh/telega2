# Data Model: Custom Emoji Rendering

**Feature**: 001-custom-emoji | **Date**: 2026-01-11

## Entities

### Emoji

Represents a single emoji with its rendering assets.

| Field | Type | Description |
|-------|------|-------------|
| codepoint | String | Unicode codepoint(s), e.g., "1F600" or "1F468-200D-1F469-200D-1F467" |
| name | String | Human-readable name, e.g., "grinning face" |
| category | EmojiCategory | Category for picker organization |
| shortcodes | List\<String\> | Search aliases, e.g., [":grin:", ":smile:"] |
| skinToneSupport | bool | Whether skin tone modifiers apply |
| hasAnimation | bool | Whether animated version exists |
| staticAssetPath | String? | Path to static WebP/PNG file (null if not cached) |
| animatedAssetPath | String? | Path to TGS/WebM file (null if not cached) |
| tdlibFileId | int? | TDLib file ID for downloading |

### EmojiCategory

Enumeration of emoji categories for picker organization.

| Value | Display Name | Icon |
|-------|--------------|------|
| recent | Recent | clock |
| smileys | Smileys & Emotion | emoji_emotions |
| people | People & Body | people |
| animals | Animals & Nature | pets |
| food | Food & Drink | restaurant |
| travel | Travel & Places | directions_car |
| activities | Activities | sports_soccer |
| objects | Objects | lightbulb |
| symbols | Symbols | emoji_symbols |
| flags | Flags | flag |

### EmojiCacheEntry

Metadata for a cached emoji asset.

| Field | Type | Description |
|-------|------|-------------|
| codepoint | String | Primary key - emoji codepoint |
| staticPath | String? | Local file path for static asset |
| animatedPath | String? | Local file path for animated asset |
| lastUsed | DateTime | For LRU eviction |
| downloadedAt | DateTime | When asset was cached |
| fileSize | int | Size in bytes for cache management |

### RecentEmoji

Tracks recently used emojis for the picker.

| Field | Type | Description |
|-------|------|-------------|
| codepoint | String | Emoji codepoint |
| useCount | int | Number of times used |
| lastUsed | DateTime | Most recent usage timestamp |

---

## Relationships

```
EmojiCategory 1──* Emoji
     │
     └── Each category contains multiple emojis

Emoji 1──1 EmojiCacheEntry
     │
     └── Each emoji may have a cache entry

Emoji *──* RecentEmoji
     │
     └── Usage tracking (same codepoint links them)
```

---

## State Transitions

### Emoji Asset State

```
┌─────────────┐
│  NotCached  │ ◄─── Initial state, no local file
└──────┬──────┘
       │ downloadFile()
       ▼
┌─────────────┐
│ Downloading │ ◄─── TDLib download in progress
└──────┬──────┘
       │ updateFile (complete)
       ▼
┌─────────────┐
│   Cached    │ ◄─── Local file available
└──────┬──────┘
       │ evictFromCache()
       ▼
┌─────────────┐
│  NotCached  │
└─────────────┘
```

### Cache Eviction Rules

1. Check total cache size on each new download
2. If exceeds `maxCacheSize` (50MB default):
   - Sort entries by `lastUsed` ascending
   - Delete oldest entries until under limit
3. Update `lastUsed` on each emoji render

---

## Validation Rules

### Emoji

- `codepoint`: Required, non-empty, valid Unicode sequence
- `name`: Required, non-empty
- `category`: Required, valid enum value
- `staticAssetPath`: If present, file must exist
- `animatedAssetPath`: If present, file must exist

### EmojiCacheEntry

- `codepoint`: Required, matches existing Emoji
- `staticPath` or `animatedPath`: At least one must be present
- `fileSize`: Must be > 0

### RecentEmoji

- `codepoint`: Required, matches existing Emoji
- `useCount`: Must be >= 1
- `lastUsed`: Cannot be in the future

---

## Storage Format

### Cache Metadata (JSON)

```json
{
  "version": 1,
  "entries": {
    "1F600": {
      "staticPath": "/cache/emoji/static/1F600.webp",
      "animatedPath": "/cache/emoji/animated/1F600.tgs",
      "lastUsed": "2026-01-11T10:30:00Z",
      "downloadedAt": "2026-01-10T08:00:00Z",
      "fileSize": 12345
    }
  },
  "totalSize": 25000000,
  "maxSize": 52428800
}
```

### Recent Emojis (SharedPreferences)

```json
{
  "recentEmojis": [
    {"codepoint": "1F600", "useCount": 42, "lastUsed": "2026-01-11T10:30:00Z"},
    {"codepoint": "2764", "useCount": 38, "lastUsed": "2026-01-11T09:15:00Z"}
  ]
}
```

---

## Indexes

| Entity | Index | Purpose |
|--------|-------|---------|
| Emoji | codepoint | Primary lookup |
| Emoji | category | Picker category filtering |
| Emoji | shortcodes | Search functionality |
| EmojiCacheEntry | lastUsed | LRU eviction |
| RecentEmoji | lastUsed DESC | Recent picker section |
