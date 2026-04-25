# Group Album Messages in Chat

When a sender posts multiple photos, videos, or other media at once, Telegram delivers them as separate messages that share a `media_album_id`. Today telega2 renders each message as its own bubble, stacked vertically. This feature renders those grouped messages as a single visual post — matching the official Telegram clients.

## What Users Can See

1. **Album of photos renders as one grouped post**

   - **Scenario: Two-photo album**
     - **Given:** A chat contains two photos sent together as an album
     - **When:** The user opens the chat
     - **Then:** Both photos appear inside one bubble, side-by-side, instead of as two stacked bubbles

   - **Scenario: Three-to-ten-photo album**
     - **Given:** A chat contains 3–10 photos sent together as an album
     - **When:** The user opens the chat
     - **Then:** The photos appear inside one bubble in a tiled grid that fits the chat's media width, with no gap between photos in the grid larger than the in-bubble spacing

2. **Mixed photo+video albums group the same way**

   - **Scenario: Photos and videos together**
     - **Given:** A chat contains an album combining photos and videos
     - **When:** The user opens the chat
     - **Then:** Photos and videos appear together in one grouped bubble; videos retain their play button and duration label

3. **Document/audio albums stack vertically inside one bubble**

   - **Scenario: Multi-document album**
     - **Given:** A chat contains an album of two or more documents
     - **When:** The user opens the chat
     - **Then:** The documents appear stacked inside one shared bubble, with one timestamp at the bottom

4. **Caption appears once per album**

   - **Scenario: Album with one caption**
     - **Given:** An album where one item carries a text caption
     - **When:** The album renders
     - **Then:** The caption appears once below the grid (not repeated under each item)

5. **Reply-to and forwarded-from appear once per album**

   - **Scenario: Forwarded album**
     - **Given:** An album forwarded from another chat
     - **When:** It renders
     - **Then:** The "Forwarded from …" line appears once at the top of the grouped bubble, not above every photo

6. **Long-press still targets the specific item**

   - **Scenario: React to one photo in an album**
     - **Given:** An album of three photos
     - **When:** The user long-presses one photo
     - **Then:** The action sheet (reply / react / copy / forward / delete) targets that specific photo, not the album as a whole

7. **Tap opens that media item full-screen**

   - **Scenario: Tap a photo in an album**
     - **Given:** An album rendered as a grid
     - **When:** The user taps a photo
     - **Then:** That photo opens full-screen using the existing viewer (gallery sweep across album items is out of scope for v1)

8. **Single (non-album) messages render unchanged**

   - **Scenario: Lone photo**
     - **Given:** A photo sent on its own (no `media_album_id`)
     - **When:** The chat renders
     - **Then:** It renders exactly as it does today — single bubble, no grid

9. **Streaming arrival fills the grid**

   - **Scenario: Album arrives while chat is open**
     - **Given:** The user is viewing a chat and a sender posts a 4-photo album
     - **When:** The photos arrive (typically within milliseconds of each other)
     - **Then:** As each photo's message arrives, the grid grows to include it, with the same entrance animation used for single messages

10. **Date separators don't split an album**

    - **Scenario: Album spans midnight (extreme edge case)**
      - **Given:** An album whose messages somehow span a date boundary
      - **When:** It renders
      - **Then:** The date separator appears above the album as a whole, not between its items

## Requirements

### Data

- [ ] The `Message` entity exposes the `media_album_id` carried by TDLib (null when absent or zero)
- [ ] `Message.fromJson` extracts `media_album_id` from the TDLib payload, tolerating both string and int representations
- [ ] `Message.copyWith` carries `mediaAlbumId` through

### Grouping

- [ ] Consecutive messages from the same sender that share a non-zero `mediaAlbumId` render as one grouped bubble
- [ ] Messages with `mediaAlbumId == null` or `0` render exactly as they do today
- [ ] Grouping happens at the render layer — the underlying message list is not collapsed; per-message state (read receipts, sending state, individual deletes) remains intact

### Layout

- [ ] Photo / video / animation albums of 2–10 items render in a tiled grid bounded by the existing `MediaSize` width
- [ ] Document and audio albums of 2+ items render as a vertical stack inside one bubble
- [ ] Mixed albums that combine media types fall back to the vertical stack
- [ ] Each grid cell maintains aspect ratio reasonably (no wild stretching) using a fixed-pattern layout for N=2/3/4/5/6 and a 3-column wrap for N=7–10

### Per-album metadata

- [ ] Caption text shown once below the grid, taken from the first message in the album that has non-empty content
- [ ] Reply preview shown once at the top of the grouped bubble, taken from the first message in the album that has a `replyToMessageId`
- [ ] "Forwarded from …" shown once at the top, taken from any item (all are expected to match)
- [ ] Sender name (in groups) shown once at the top
- [ ] Timestamp shown once at the bottom-right of the grouped bubble, taken from the latest message in the album

### Per-item interactions

- [ ] Long-pressing any item opens the existing message-options sheet targeting that item's specific message
- [ ] Tapping a photo opens the existing single-photo full-screen viewer for that photo
- [ ] Tapping a video opens the existing single-video full-screen player for that video
- [ ] A failed-to-send sub-message surfaces its own send-failure indicator on its grid cell

### Reactions

- [ ] Per-item reactions remain attributable to the specific message that owns them; they appear in a row below the grid (a known v1 simplification — official Telegram clusters reactions by item rather than by album)

### Animation

- [ ] The grouped bubble plays the existing entrance animation once per album, not once per item
- [ ] Pre-existing albums in chat history do not re-animate when the chat reopens

### Out of scope (v1)

- [ ] Full mosaic-layout algorithm matching official Telegram exactly (using a simpler fixed-pattern layout instead)
- [ ] Swipeable gallery across album items in full-screen viewer (taps still open one item at a time)
- [ ] Editing/regrouping albums — albums are inferred at render time and never persisted
- [ ] Tests for visual fidelity of grids beyond unit-level assertions on the layout function

## Open Questions

_None — resolved:_

- **Layout algorithm**: simple fixed pattern (N=2 row, N=3 one-big-two-stacked, N=4 grid, N=5/6 two rows, N=7–10 three-column wrap). Mosaic algorithm deferred.
- **Caption / reply ownership**: deterministic — first message in date order with non-empty content / non-null reply-to.
- **Reactions**: per-item below the grid; attribution via long-press is preserved.
- **Tap behaviour**: opens that one item full-screen (no gallery).
- **Mixed-type albums**: vertical stack fallback (matches official client behaviour for mixed albums).
