# Plan: Group Album Messages in Chat

**Spec**: arch/specs/016-group-album-messages-in-chat/spec.md

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter (Material 3) + flutter_riverpod ^3
- TDLib: existing integration via `lib/data/repositories/tdlib_telegram_client.dart` — `Message.fromJson` already runs in this layer
- Layout primitives: existing `Row`/`Column`/`Flexible`/`AspectRatio`; no new dependency
- Reuses today's media widgets: `PhotoMessageWidget`, `VideoMessageWidget`, `AnimationMessageWidget`, `DocumentMessageWidget` (each already takes individual paths/sizes — they don't bind to `Message`, so they slot into a grid cleanly)
- Testing: `flutter_test` (existing pattern in `test/core/theme/...`)

## Structure

```
lib/
├── domain/
│   └── entities/
│       └── chat.dart                              # MODIFIED: Message.mediaAlbumId field + parse + copyWith
├── widgets/
│   └── message/
│       ├── message_list.dart                      # MODIFIED: groups consecutive same-album messages into rows; renders an Album row or single bubble per row
│       ├── message_bubble.dart                    # UNCHANGED for single messages — albums use a sibling widget
│       ├── album_message_bubble.dart              # NEW: bubble shell (reply / forwarded / sender / grid / caption / timestamp / reactions) for an album
│       ├── album_grid.dart                        # NEW: layout-only widget — given N media cells builds the fixed-pattern grid
│       └── album_grouping.dart                    # NEW: pure helper that turns List<Message> → List<MessageRow> (single | album)

test/
└── widgets/
    └── message/
        ├── album_grouping_test.dart               # NEW: grouping logic — same/different album_id, null, direction breaks, max-of-10 cap
        └── album_grid_layout_test.dart            # NEW: AlbumGrid layout function — N=2..10 produces expected row/column structure
```

## Approach

Implementation proceeds in three phases. Each phase ends shippable.

### Phase 1 — Data: surface `media_album_id`

1. **Add `mediaAlbumId` to `Message`**
   In `lib/domain/entities/chat.dart`, extend the `Message` class (currently lines 414–458) with a final `int? mediaAlbumId` field. Update the constructor (line 439), the call inside `fromJson` (line 777), and `copyWith` (lines 799–839). TDLib emits `media_album_id` as a string-encoded int64 at the message root level. Parse defensively:
   ```dart
   final rawAlbumId = json['media_album_id'];
   final mediaAlbumId = switch (rawAlbumId) {
     int v when v != 0 => v,
     String s => int.tryParse(s).let((v) => v == 0 ? null : v),
     _ => null,
   };
   ```
   Treat `0` as absent (TDLib uses `0` for "no album"). No change required in `lib/data/repositories/tdlib_telegram_client.dart` — `Message.fromJson` is the only parser call site.

2. **Done — no other state mutations**
   Crucially, `MessageState.messagesByChat` (`lib/presentation/state/message_state.dart`) is **not** changed. Albums stay as N individual `Message` objects in state. This preserves every existing per-message operation: read receipts, mark-as-read, sending state, edit, delete, reactions, replies. Grouping is a pure render-time transformation of the list.

### Phase 2 — Grouping helper + render-time integration

3. **Pure grouping function**
   Create `lib/widgets/message/album_grouping.dart`:
   ```dart
   sealed class MessageRow {
     const MessageRow();
   }
   class SingleMessageRow extends MessageRow {
     final Message message;
     const SingleMessageRow(this.message);
   }
   class AlbumRow extends MessageRow {
     final List<Message> messages;        // 2–10, sorted oldest→newest within the row
     int get albumId => messages.first.mediaAlbumId!;
     const AlbumRow(this.messages);
   }

   List<MessageRow> groupAlbums(List<Message> messages) { ... }
   ```
   Input is the existing newest-first list from `MessageState`. The function walks the list and merges runs that all satisfy:
   - `mediaAlbumId != null && mediaAlbumId != 0`
   - same `mediaAlbumId` as the previous in the run
   - same `chatId`
   - same `senderId` (defensive — Telegram albums are always single-sender)
   - same calendar day (so a date separator never splits a run; in practice albums arrive within seconds, but guard against the edge case)
   - same `isOutgoing` flag
   - run length ≤ 10 (Telegram's hard cap; defensive)
   
   Anything else flushes the current run as either a `SingleMessageRow` (length 1) or an `AlbumRow` (length ≥ 2). Output preserves the input's newest-first ordering at the row level. Within an `AlbumRow`, sort by date ascending so the grid reads top-left → bottom-right in send order.

4. **Integrate into `MessageList`**
   In `lib/widgets/message/message_list.dart`:
   - Replace the existing `ListView.builder(itemCount: messages.length, …)` (lines 223–240) with one that consumes `final rows = groupAlbums(messages);` and iterates rows.
   - Update `_shouldShowDateSeparator` (lines 367–389) to take row index + `rows`, comparing against the *first message in the next-older row* rather than the next-older message in the flat list.
   - Update entrance-animation tracking: `_seenMessageIds` already keys by message ID; for an `AlbumRow`, treat the row as "seen" iff *every* message ID in the album has already been seen. The first time a new message in an existing album arrives, the album gets a fresh entrance animation — acceptable, since the visible content materially changed.
   - The `ListView.builder` key per row: `ValueKey('album-${albumId}')` for `AlbumRow`, `ValueKey(message.id)` for single rows. Stable keys keep scroll position correct across grouping changes.

5. **Mark-as-read still uses the flat list**
   Leave `_markLatestAsRead(messages)` (line 99) untouched — it operates on the flat `List<Message>` from state and finds the latest incoming. Grouping is purely visual.

### Phase 3 — `AlbumGrid` layout + `AlbumMessageBubble` shell

6. **Layout function**
   Create `lib/widgets/message/album_grid.dart`. Export a pure layout descriptor and a widget:
   ```dart
   class AlbumGrid extends StatelessWidget {
     final List<Widget> cells;            // already-built media widgets, one per album item
     final double maxWidth;               // typically MediaSize.maxWidth (250)
     final double gap;                    // 2.0 — matches official Telegram's hairline gap
     const AlbumGrid({super.key, required this.cells, required this.maxWidth, this.gap = 2.0});
     ...
   }
   ```
   The layout uses fixed patterns by `cells.length`:
   - **2** — one row, two equal columns (each `(maxWidth - gap) / 2` wide, height fixed to `maxWidth × 0.66`)
   - **3** — left column one big cell (full height), right column two stacked cells; widths split 60/40
   - **4** — 2×2 grid, each cell `(maxWidth - gap) / 2` square
   - **5** — top row 2 cells, bottom row 3 cells; row heights split 1.0 : 0.66
   - **6** — 2×3 grid (2 rows of 3 cells)
   - **7..10** — 3-column flow with the last row possibly under-filled; row height fixed to `maxWidth / 3` square
   
   These match the simple `tdesktop` patterns *visually close enough* without porting the full mosaic algorithm. The dispatch is a `switch` on `cells.length`. Constants live at the top of the file (`_AlbumPattern` records).
   
   Size each grid cell by handing the inner media widget a `SizedBox(width:, height:)` with the cell's resolved dimensions — `PhotoMessageWidget` already accepts width/height as the photo's intrinsic size; for grid cells we wrap each in a `ClipRRect` (no rounded corners on inner cells, only outer) and a `SizedBox` overriding the visual dimensions.

7. **Album bubble shell**
   Create `lib/widgets/message/album_message_bubble.dart`. Mirrors `MessageBubble` but takes an `AlbumRow`:
   ```dart
   class AlbumMessageBubble extends ConsumerWidget {
     final AlbumRow album;
     final bool showSender;
     final void Function(Message) onLongPress;   // long-press on any cell → message-options for that cell's message
     ...
   }
   ```
   Layout (top → bottom):
   - Reply preview (use the first message in `album.messages` whose `replyToMessageId != null`; reuse `_buildReplyPreview` logic by extracting it into a shared helper)
   - "Forwarded from …" line (any message; all should match)
   - Sender name (groups, when `showSender` and `!isOutgoing`)
   - **Grid** (the one media-bearing path) OR **vertical stack** (documents/audio path; just a `Column` of the same media widgets as today, separated by `Spacing.sm`)
   - Caption — first message with non-empty `content`, rendered with the same `EmojiText(...)` style as today's caption code
   - Timestamp — pulled from `album.messages.last.date`
   - Reactions — concatenated rows: for each message in the album that has reactions, render its reaction strip below the grid with the existing `_buildReactionsRow` helper (passing the specific message). Stacked vertically when more than one item has reactions.
   
   The bubble shape, fill, padding, and tokens come from `TelegaTokens` exactly as `MessageBubble` does today (read at line 37 of `message_bubble.dart`). Reuse the same `bubbleRadius`, `bubbleHorizontalPadding`, `bubbleVerticalPadding`, and gutter logic to keep visual parity.
   
   **Mixed-type detection** drives grid-vs-stack: if every message's `type` is in `{photo, video, animation}`, use `AlbumGrid`; otherwise use the vertical stack.

8. **Cell-level interactions**
   For each cell, build the corresponding media widget *as today* (via `PhotoMessageWidget(...)`, `VideoMessageWidget(...)`, etc.). Wrap each cell in a `GestureDetector(onLongPress: () => onLongPress(message))` so long-press routes to that specific message's options sheet. Tap is already handled by the inner media widget (it opens the per-item full-screen viewer); we don't intercept it.
   
   The pre-existing failure overlay on individual `PhotoMessageWidget` / `VideoMessageWidget` already shows download/upload progress and failures. Sending failures (`message.sendingState == failed`) are not surfaced today on those widgets directly — surface them in the album by wrapping each cell in a small `Stack` with a corner badge when the underlying message's `sendingState == failed`.

9. **Wire up `MessageList`**
   In `_buildMessageRow` (line 266) of `message_list.dart`, branch on the row type:
   - `SingleMessageRow` → existing `MessageBubble(...)` path, unchanged.
   - `AlbumRow` → `AlbumMessageBubble(album: row, showSender: !row.messages.first.isOutgoing, onLongPress: (m) => _showMessageOptions(context, m))`.
   
   Pass the row through the existing `TweenAnimationBuilder` entrance wrapper (already keyed by `_seenMessageIds`).

### Tests

10. **Grouping logic**
    `test/widgets/message/album_grouping_test.dart`:
    - 3 messages, same `mediaAlbumId`, same direction → one `AlbumRow` with all three.
    - 3 messages, different `mediaAlbumId`s → three `SingleMessageRow`s.
    - Mixed null and non-null `mediaAlbumId` interleaved → singles for the nulls, an album for the run.
    - Same `mediaAlbumId` but different senders → two albums (or split into singles, depending on length).
    - Run of 12 same-album messages → first 10 form an album, remaining 2 → singles (defensive cap).
    - One message with `mediaAlbumId == 0` → single (treated as absent).

11. **Layout function**
    `test/widgets/message/album_grid_layout_test.dart`:
    - For each N in 2..10, build an `AlbumGrid` and assert that the resulting widget tree contains the expected number of `Row`/`Column` cells and that the outer total width equals `maxWidth`.
    - Gap accumulates correctly (`maxWidth - cellWidthsSum == gap × (gridDimension - 1)`).

12. **Entity round-trip**
    `test/domain/entities/message_album_id_test.dart`:
    - `Message.fromJson` with `media_album_id: '12345678901234567'` → `mediaAlbumId == 12345678901234567`.
    - `media_album_id` absent → `mediaAlbumId == null`.
    - `media_album_id: 0` (or `'0'`) → `mediaAlbumId == null`.
    - `Message.copyWith(mediaAlbumId: 42).mediaAlbumId == 42`.

## Risks

- **TDLib field representation**: `media_album_id` is documented as `int64` and historically serialized as a string in the JSON layer. Other Dart TDLib parsers in this codebase use the same string-or-int pattern. Mitigation: the parser at step 1 handles both; tests cover both shapes. A misparse just means albums don't group — visually identical to today.
- **Streaming arrival jank**: When an album's messages arrive one by one, the grid resizes as items appear (1 → 2 → 3 → 4 photos). Mitigation: this matches official Telegram's send-side behavior; the entrance animation re-keys on the album growing, which is desirable. If profiling shows jank, debounce grouping by ~200ms (queue album messages and only emit an `AlbumRow` once the run stabilizes).
- **Pagination/scroll position drift**: Switching from per-message to per-row item counts could disturb scroll restoration on `loadMoreMessages`. Mitigation: stable `ValueKey('album-$albumId')` per row and `ValueKey(messageId)` per single message keeps Flutter's scroll mechanics correct. The existing `loadMoreMessages` trigger (line 84 of `message_list.dart`) compares scroll offsets, not item indices, so it's unaffected.
- **Mark-as-read regressions**: `_markLatestAsRead` walks the flat `messages` list — unchanged. No regression.
- **Reactions on grouped items look cramped**: stacking per-item reaction rows below a 4-photo grid is visually busy. Acceptable for v1 (reactions on individual album items are uncommon in practice). Future iteration: cluster reactions by item with a small thumbnail prefix.
- **Reply via long-press on a specific photo**: works because the long-press handler receives the cell's specific `Message`, and `_showMessageOptions` is called with that message. Reply preview shown on the *replier's* future message will quote the original specific photo as today.
- **Fixed-pattern layout vs. official mosaic**: 3- and 5-photo layouts will look different from official Telegram for portrait-heavy mixes (official biases toward orientation; ours doesn't). Mitigation: matches the spec's explicit decision (mosaic deferred). Visually acceptable for v1.
- **Album with one item (1-message "album")**: shouldn't happen — TDLib only sets `media_album_id` when there are 2+ items. Defensive: if a run has length 1 it's emitted as `SingleMessageRow`, never as a degenerate `AlbumRow`.
- **Date separator placement**: grouping requires checking same-day, which makes the separator logic slightly more involved. Step 4 adapts `_shouldShowDateSeparator` to operate on rows rather than messages. Tested by the integration in step 11 indirectly (and visually verified).
- **Animation flicker on chat reopen**: existing `_seenMessageIds` is pre-populated with the initial message set on first non-empty load (lines 207–213). Albums made of only pre-seen messages don't entrance-animate, matching today's behavior. New album items received while open *do* trigger entrance animation on the album row — acceptable.

## Open Questions

_None — resolved:_

- **Grouping layer**: Render-time, in `MessageList`. State remains per-message so reactions/edits/deletes/marks all work unchanged. Confirmed during exploration: `MessageState.messagesByChat` is the only message store and every per-message operation reads from it.
- **Layout algorithm**: Simple fixed pattern by `cells.length` for v1. Mosaic Layouter (full `tdesktop` algorithm) deferred — the spec explicitly out-of-scopes it.
- **Caption / reply / forwarded ownership**: Deterministic — first message in date order with the relevant non-null/non-empty value. Encoded as a helper inside `AlbumMessageBubble`.
- **Reactions**: Per-item rows below the grid in v1. The official Telegram clustering is a known refinement.
- **Tap on a photo**: Opens that single photo in the existing `_FullScreenImageViewer`. No swipeable gallery in v1.
- **Mixed-type albums (photo + document)**: Vertical stack, matching official client behavior for non-grid-friendly combinations.
- **TDLib JSON representation of `media_album_id`**: Parser tolerates both `int` and `String` (TDLib documents `int64`; the JSON-bridge serializes as string).
