# Plan: Render Emojis the Way tdesktop Does

**Spec**: none — direct from conversation. The user reported that some emojis in reaction chips render as blank placeholders with no error log (see `reaction_chip.dart` + `telegram_emoji_widget.dart`). The fix must mirror tdesktop's approach exactly: ship the same atlas assets, use the same lookup table, render through the same tile-extraction path, and never silently fall back.

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- Assets: 8 WEBP atlases lifted from `~/github/tdesktop/Telegram/Resources/emoji/emoji_{1..8}.webp` (~7.8 MB total) plus the canonical sequence list `~/github/tdesktop/Telegram/lib_ui/emoji.txt` (715 lines)
- Rendering: `dart:ui.Image` decoded once per atlas + `CustomPainter` (`canvas.drawImageRect`) for tile blitting — no per-emoji file I/O
- Codegen: one-shot Dart script under `tool/emoji/` that reads `emoji.txt` and emits a const Dart lookup table
- Logging: existing `AppLogger` (`lib/core/logging/app_logger.dart`)
- Testing: `flutter_test` + `dart test` for the pure codegen / lookup pieces

## Structure

```
assets/
└── emoji/
    ├── emoji_1.webp ... emoji_8.webp                # NEW: copied verbatim from tdesktop
    └── emoji.txt                                     # NEW: copied verbatim from tdesktop (input to codegen)

tool/
└── emoji/
    └── generate_catalog.dart                         # NEW: parses emoji.txt → emits lib/core/emoji/emoji_catalog.g.dart

lib/
├── core/
│   └── emoji/
│       ├── emoji_catalog.g.dart                      # NEW (generated, committed): const Map<String,EmojiTile> + sprite count
│       ├── emoji_catalog.dart                        # NEW: lookup API — find(String input) → EmojiTile?, plus key-canonicalization
│       ├── emoji_atlas.dart                          # NEW: loads & caches the 8 ui.Image atlas sheets
│       ├── emoji_asset_manager.dart                  # MODIFIED → DELETED: replaced by catalog + atlas
│       ├── emoji_cache.dart                          # DELETED: file cache no longer relevant
│       ├── emoji_data.dart                           # KEPT: picker categories/metadata only — disconnected from rendering
│       └── emoji_utils.dart                          # MODIFIED: containsEmoji / splitTextWithEmojis switched to catalog-aware tokenizer
├── widgets/
│   └── emoji_sticker/
│       └── telegram_emoji_widget.dart                # REWRITTEN: thin wrapper over EmojiAtlasPainter; same public API
└── presentation/
    └── providers/
        └── emoji_providers.dart                      # MODIFIED: drop emojiAssetPathProvider (FutureProvider) → sync catalog/atlas providers

test/
└── core/
    └── emoji/
        ├── emoji_catalog_test.dart                   # NEW: lookup correctness — single, FE0F-stripped, skin-toned, ZWJ family, regional flag
        ├── emoji_tokenizer_test.dart                 # NEW: splitTextWithEmojis covers same sequences as catalog
        └── emoji_atlas_painter_test.dart             # NEW: golden test that drawing emoji "👍" produces the expected tile from emoji_1.webp
```

## Approach

Three phases. Each phase ends shippable; reactions render correctly after Phase 2.

### Phase 1 — Catalog & atlas in the project

1. **Vendor the assets**
   Copy `emoji_1.webp` … `emoji_8.webp` and `emoji.txt` from `~/github/tdesktop/Telegram/Resources/emoji/` and `~/github/tdesktop/Telegram/lib_ui/` into `assets/emoji/`. Update `pubspec.yaml` — the existing `assets/emoji/` glob already covers them. Document the source commit of tdesktop in a one-line comment at the top of `tool/emoji/generate_catalog.dart`.

2. **Write the codegen script** (`tool/emoji/generate_catalog.dart`)
   The script is plain Dart, runnable as `dart run tool/emoji/generate_catalog.dart`. It:
   - Reads `assets/emoji/emoji.txt`. Each non-comment, non-blank line is a section: a comma-separated list of double-quoted emoji strings.
   - Walks every emoji in the order it appears, assigning a sequential index `n = 0, 1, 2, ...`. Computes `(sprite, row, col) = (n ~/ 512, (n % 512) ~/ 32, n % 32)`. This matches tdesktop's 32-col × 16-row × 8-sheet packing (see `emoji_config.h:90-101`, `generator.cpp:371-451`).
   - For each emoji string, derives a **canonical key** by stripping trailing `U+FE0F` from each base character (tdesktop's `BareIdFromInput`, `data.cpp:144-150`). Records whether `FE0F` was originally present so the widget can re-append it for accessibility text.
   - Emits `lib/core/emoji/emoji_catalog.g.dart`:
     ```dart
     // GENERATED — do not edit. Regenerate via: dart run tool/emoji/generate_catalog.dart
     class EmojiTile {
       final int sprite, row, col;
       final bool hasPostfix;
       const EmojiTile(this.sprite, this.row, this.col, this.hasPostfix);
     }
     const int kEmojiSpriteCount = 8;
     const int kEmojiTilePx = 72;
     const Map<String, EmojiTile> kEmojiCatalog = { ... };
     ```
     The map key is the **canonical** UTF-16 string (FE0F stripped) so lookups are O(1).

3. **Verification**
   At the end of the codegen run, assert that the highest assigned `sprite` is `< 8`. If the catalog overruns 8 sheets, tdesktop has added new emoji and we must update the atlas count — fail loudly. Also assert no two distinct emoji strings collapse to the same canonical key (sanity check on the FE0F stripping).

### Phase 2 — Rendering through the atlas

4. **`EmojiCatalog` lookup API** (`lib/core/emoji/emoji_catalog.dart`)
   ```dart
   class EmojiCatalog {
     static EmojiTile? find(String input) {
       final key = _canonicalize(input);            // strip FE0F, normalize
       return kEmojiCatalog[key];
     }
     static String _canonicalize(String s) { /* drop U+FE0F (️) */ }
   }
   ```
   Pure, sync, no I/O. The previous `FutureProvider` pipeline goes away entirely.

5. **`EmojiAtlas` loader** (`lib/core/emoji/emoji_atlas.dart`)
   Singleton that loads the 8 `ui.Image`s lazily and caches them:
   ```dart
   class EmojiAtlas {
     static final _sheets = <int, Future<ui.Image>>{};
     static Future<ui.Image> sheet(int index) =>
       _sheets.putIfAbsent(index, () => _decode('assets/emoji/emoji_${index + 1}.webp'));
   }
   ```
   `_decode` uses `rootBundle.load` + `ui.instantiateImageCodec`. Each sheet is decoded **once** per app session.

6. **Riverpod providers** (`lib/presentation/providers/emoji_providers.dart`)
   Replace the existing `emojiAssetPathProvider` (FutureProvider) with:
   ```dart
   final emojiAtlasProvider = FutureProvider.family<ui.Image, int>((ref, sprite) =>
     EmojiAtlas.sheet(sprite));
   ```
   Catalog lookup is a plain function — no provider needed.

7. **Rewrite `TelegramEmojiWidget`** (`lib/widgets/emoji_sticker/telegram_emoji_widget.dart`)
   Same constructor signature so call sites (`emoji_text.dart:90,125`, `reaction_chip.dart:109`, picker grids) need no changes.
   ```dart
   Widget build(BuildContext context, WidgetRef ref) {
     final tile = EmojiCatalog.find(emoji);
     if (tile == null) {
       _logger.warn('emoji.catalog.miss', data: {'emoji': emoji, 'codepoints': emoji.runes.toList()});
       return const SizedBox.shrink();   // no fallback — exactly tdesktop's behaviour
     }
     final sheet = ref.watch(emojiAtlasProvider(tile.sprite));
     return sheet.when(
       data: (img) => SizedBox(
         width: size, height: size,
         child: CustomPaint(painter: _EmojiTilePainter(img, tile, size)),
       ),
       loading: () => SizedBox(width: size, height: size),  // invisible — first paint of the session only
       error: (e, _) {
         _logger.error('emoji.atlas.load_failed', error: e, data: {'sprite': tile.sprite});
         return const SizedBox.shrink();
       },
     );
   }
   ```
   `_EmojiTilePainter` calls `canvas.drawImageRect(img, src, dst, paint)` where `src = Rect.fromLTWH(col*72, row*72, 72, 72)` and `dst = Rect.fromLTWH(0, 0, size, size)`. `Paint()..filterQuality = FilterQuality.medium` matches tdesktop's `Qt::SmoothTransformation`.

8. **Tokenizer alignment** (`lib/core/emoji/emoji_utils.dart`)
   `splitTextWithEmojis` currently matches with a regex on broad Unicode ranges and so disagrees with the catalog at sequence boundaries (a ZWJ family currently splits into N tiles). Replace with a catalog-driven tokenizer: for each position in the string, attempt the longest catalog match first (greedy walk; tdesktop's `Find()` does the same). Falls back to the regex only as a literal text segment. Once this lands, `EmojiText` automatically renders ZWJ sequences as a single tile.

### Phase 3 — Cleanup and logging

9. **Delete the old PNG bundle and supporting code**
   - `rm -r assets/emoji/[0-9A-F]*.png` (3707 files, ~37 MB → ~7.8 MB after this phase)
   - Delete `lib/core/emoji/emoji_asset_manager.dart` and `lib/core/emoji/emoji_cache.dart`
   - Delete the disk-cache directory on first run of the new code (one-shot migration in `EmojiAtlas` init: `getApplicationCacheDirectory()/emoji/{static,animated}` → `Directory.delete(recursive: true)` if it exists; non-fatal on failure)
   - Drop the `pendingLoads` map and `Completer` plumbing; nothing remains async

10. **Wire the logger end-to-end**
    Two structured warnings cover the entire surface area:
    - `emoji.catalog.miss` — emoji char passed in but not in our catalog. Fires once per (chat-render, emoji) pair so reactions don't spam, but every novel miss surfaces.
    - `emoji.atlas.load_failed` — atlas WEBP failed to decode. Should never happen in production; catastrophic if it does.
    Custom-emoji (TDLib animated reactions) keeps its own, separate code path — `_fetchCustomEmojis` and `ReactionGlyph` in `reaction_chip.dart`. **Out of scope** for this plan: that's a real bug too but distinct from the catalog issue causing the reported failure.

## Risks

- **Atlas layout drift**: if tdesktop's C++ codegen reorders or deduplicates emoji during atlas generation, naive sequential indexing in our Dart codegen will misalign — every tile would render a wrong emoji. Mitigation: in Phase 1, after generating, render a known-good sample (👍, 🌶, 🤔) into a debug screen and visually confirm against tdesktop running on the same machine. If misaligned, read `Telegram/codegen/codegen/emoji/generator.cpp:664-699` and replicate the exact ordering.
- **WEBP decode on Flutter**: Flutter's image codec supports static WEBP since 3.x but lacks animated WEBP — tdesktop's atlases are static, so this is fine. Verified via `flutter doctor` + the existing `assets/emoji/*.webp` paths already present in the bundle. If a runtime decode error surfaces, fallback is to convert atlases to PNG once at codegen time.
- **Bundle size on iOS/Android install**: drops from 37 MB → ~8 MB. Net positive, no risk.
- **Picker UI dependency**: `emoji_grid.dart` and `emoji_repository_impl.dart` currently use the path-based asset manager for the picker grid. These call sites already render through `TelegramEmojiWidget` via the emoji char — they don't actually need the path. Phase 2 step 7 makes the path obsolete; the picker layer stops calling `getEmojiAssetPath`. Verify by grepping for direct callers of `emojiAssetPathProvider` after rewrite.
- **Variant-selector edge cases**: text input from chats sometimes ships emoji *with* `FE0F`, sometimes without (e.g., `☺` vs `☺️`). Canonical-key lookup with FE0F stripped on both sides handles both. Tested explicitly in `emoji_catalog_test.dart`.

## Open Questions

- **Codegen invocation**: do we want a `dart run tool/emoji/generate_catalog.dart` step in CI to verify `emoji_catalog.g.dart` is up-to-date, or is "regenerate manually when tdesktop is bumped" sufficient? Default: manual, since tdesktop's emoji.txt updates rarely (~1-2× per year).
- **Postfix re-application**: tdesktop appends `FE0F` to emoji text for `hasPostfix=true` entries when copying to clipboard. We don't have a copy-emoji feature yet, so storing `hasPostfix` is forward-looking. Worth keeping in the generated table to avoid a future regen.
- **Animated standard emojis**: tdesktop ships `.tgs` Lottie animations for some standard emojis ("👍" pulse, etc.) downloaded on demand from the server, not bundled. The current code half-handles this via `animated: true` + Lottie. Out of scope here — Phase 2 step 7 keeps `animated` in the constructor but ignores it (always renders the static tile). If the user later wants animated standard reactions, we add a TDLib `getAnimatedEmoji` flow on top, parallel to the custom-emoji path — does not block this work.
