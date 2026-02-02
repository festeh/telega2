# Tasks: Custom Media Attachment Picker

**Input**: Design documents from `/specs/003-custom-media-picker/`
**Prerequisites**: plan.md, spec.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## User Stories (from spec.md)

- **US1**: Open the attachment panel (panel slides up with media grid)
- **US2**: Browse and select photos/videos from the grid
- **US3**: Multi-select media (numbered badges, max 10)
- **US4**: Take a photo with the camera
- **US5**: Pick a document/file
- **US6**: Send selected media (single + album grouping)
- **US7**: Add a caption

---

## Phase 1: Setup

**Purpose**: Add dependencies and create file structure

- [X] T001 Add `photo_manager` and `photo_manager_image_provider` dependencies to `pubspec.yaml` and run `flutter pub get`
- [X] T002 Create directory `lib/widgets/message/media_picker/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Provider layer and TDLib album support that all user stories depend on

**⚠️ CRITICAL**: US1-US7 depend on these completing first

- [X] T003 [P] Create media picker provider with permission handling, asset loading, and pagination in `lib/presentation/providers/media_picker_provider.dart`. Use `photo_manager` to request permissions, load the "Recent" album via `getAssetPathList(onlyAll: true)`, fetch assets with `getAssetListPaged(page, size: 50)`, and expose `List<AssetEntity>`, permission state, loading state, and a `loadMore()` method. Filter to `RequestType.common` (photos + videos).
- [X] T004 [P] Add `sendMessageAlbum` method to repository interface in `lib/domain/repositories/telegram_client_repository.dart`. Signature: `Future<void> sendMessageAlbum(int chatId, List<(String path, bool isVideo)> items, {String? caption, int? replyToMessageId})`
- [X] T005 Implement `sendMessageAlbum` in `lib/data/repositories/tdlib_telegram_client.dart`. Build an array of `inputMessageContent` objects (inputMessagePhoto or inputMessageVideo per item), attach caption to the first item only, and call TDLib's `sendMessageAlbum`. Follow the existing pattern from `sendPhoto`/`sendVideo` for error handling and message caching.
- [X] T006 Add `sendAlbum` method to `lib/presentation/notifiers/message_notifier.dart`. Signature: `Future<void> sendAlbum(int chatId, List<(String path, bool isVideo)> items, {String? caption})`. Follow existing `sendPhoto` pattern: set `isSending = true`, handle reply state, call repository, handle errors.

**Checkpoint**: Provider can load device media, TDLib can send albums. Ready for UI work.

---

## Phase 3: User Story 1 - Open the Attachment Panel (P1) 🎯 MVP

**Goal**: Tapping the attachment button shows a bottom panel with a media grid instead of the old bottom sheet

**Independent Test**: Tap paperclip button → panel slides up showing device photos/videos in a grid. Swipe down or tap outside to dismiss.

### Implementation for User Story 1

- [X] T007 [US1] Create `MediaPickerPanel` widget in `lib/widgets/message/media_picker/media_picker_panel.dart`. Use `DraggableScrollableSheet` inside a modal bottom sheet. Layout: drag handle at top, action row (camera + document + send button), then the media grid below. Accept callbacks for `onSend`, `onCamera`, `onDocument`. Handle permission state: if denied, show message with "Open Settings" button calling `PhotoManager.openSetting()`. On Linux desktop, skip gallery and show only Camera/Document buttons with a "Gallery not available on desktop" message.
- [X] T008 [US1] Modify `_showAttachmentOptions()` in `lib/widgets/message/message_input_area.dart`. Replace the current `showModalBottomSheet` (3-icon bottom sheet) with showing the new `MediaPickerPanel`. Wire up `onCamera` to existing `_pickFromCamera()`, `onDocument` to existing `_pickDocument()`.

**Checkpoint**: Panel opens with grid of photos. Camera and Document buttons work as before.

---

## Phase 4: User Story 2 - Browse Photos/Videos in Grid (P1)

**Goal**: Scrollable grid of device photos/videos with efficient thumbnail loading and video duration overlays

**Independent Test**: Open panel → see recent photos/videos in a 3-column grid. Scroll down to load more. Videos show duration badge.

### Implementation for User Story 2

- [X] T009 [P] [US2] Create `MediaThumbnail` widget in `lib/widgets/message/media_picker/media_thumbnail.dart`. Displays a single grid cell: thumbnail image filling the cell using `AssetEntityImage` with `ThumbnailSize.square(200)` and `BoxFit.cover`. If the asset is a video, show a duration overlay at bottom-right (white text on semi-transparent dark background, format "M:SS"). Accept `isSelected`, `selectionIndex`, and `onTap` parameters (selection UI built in US3).
- [X] T010 [US2] Create `MediaGrid` widget in `lib/widgets/message/media_picker/media_grid.dart`. A `GridView.builder` with 3 columns, 2px spacing. Consumes the media picker provider to get assets. Triggers `loadMore()` when scrolling near the bottom (e.g., last 10 items). Shows a loading indicator at the bottom while loading more. Shows empty state message when no media found.

**Checkpoint**: Grid displays photos/videos with thumbnails. Pagination works on scroll. Videos show duration.

---

## Phase 5: User Story 3 - Multi-Select Media (P1)

**Goal**: Tap to select/deselect items with numbered badges, max 10 items

**Independent Test**: Tap photos → numbered badge appears (1, 2, 3). Tap selected item → deselects and renumbers. Try selecting 11th → see error message.

### Implementation for User Story 3

- [X] T011 [US3] Add selection state and logic to `MediaPickerPanel` in `lib/widgets/message/media_picker/media_picker_panel.dart`. Manage `List<AssetEntity> selectedItems` in widget state. Pass selection state and `onTap` toggle callback down to `MediaGrid` and `MediaThumbnail`. On tap: if not selected and count < 10, add to list; if selected, remove and renumber; if count == 10, show snackbar "Maximum 10 items". Update send button to show selection count when items are selected.
- [X] T012 [US3] Add selection overlay to `MediaThumbnail` in `lib/widgets/message/media_picker/media_thumbnail.dart`. When `isSelected` is true: show a numbered blue circle at top-right with `selectionIndex` number, and apply a slight dark overlay to the thumbnail.

**Checkpoint**: Multi-select works with numbered badges. Max 10 enforced.

---

## Phase 6: User Story 4 & 5 - Camera and Document (P2)

**Goal**: Camera and Document buttons in the panel work correctly

**Independent Test**: Tap camera button → camera opens, photo sends. Tap document button → file picker opens, file sends.

### Implementation for User Stories 4 & 5

- [X] T013 [US4] [US5] Wire camera and document buttons in `MediaPickerPanel` in `lib/widgets/message/media_picker/media_picker_panel.dart`. Camera button calls the `onCamera` callback (which triggers `_pickFromCamera()` from message_input_area). Document button calls `onDocument` callback (which triggers `_pickDocument()`). Both dismiss the panel first. Camera button is hidden or disabled on Linux desktop.

**Checkpoint**: Camera and document picking work from within the new panel.

---

## Phase 7: User Story 6 - Send Selected Media (P1)

**Goal**: Send button sends all selected items. Single items use sendPhoto/sendVideo. Multiple items use sendMessageAlbum.

**Independent Test**: Select 1 photo → send → photo appears in chat. Select 3 photos → send → album appears. Select mix of photos and videos → send → grouped album.

### Implementation for User Story 6

- [X] T014 [US6] Implement send logic in `MediaPickerPanel` in `lib/widgets/message/media_picker/media_picker_panel.dart`. On send button tap: get file paths via `asset.file` for each selected item (show loading indicator while resolving). Determine type per item (`asset.type == AssetType.video`). If single item: call `sendPhoto` or `sendVideo` via messageProvider notifier. If multiple items: call `sendAlbum` via messageProvider notifier. Dismiss panel on success. Show error snackbar on failure. Pass `onSend` callback to message_input_area to handle the actual send calls.
- [X] T015 [US6] Wire send callback in `lib/widgets/message/message_input_area.dart`. Create `_sendSelectedMedia(List<AssetEntity> items)` method that resolves file paths, determines types, and calls the appropriate notifier methods (`sendPhoto`, `sendVideo`, or `sendAlbum`). Pass this as `onSend` callback to `MediaPickerPanel`.

**Checkpoint**: Single and multi-item sends work. Albums display correctly in chat.

---

## Phase 8: User Story 7 - Add a Caption (P2)

**Goal**: Text in the input field is sent as a caption with the selected media

**Independent Test**: Type text in input → select photo → send → message shows photo with caption text.

### Implementation for User Story 7

- [X] T016 [US7] Pass caption from input field to send logic in `lib/widgets/message/message_input_area.dart`. When `_sendSelectedMedia` is called, read the current text from the input controller. Pass it as `caption` parameter to `sendPhoto`/`sendVideo`/`sendAlbum`. Clear the text field after successful send.

**Checkpoint**: Captions work on single items and albums.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases and refinements

- [X] T017 [P] Handle permission changes in `lib/widgets/message/media_picker/media_picker_panel.dart`. If user grants permission after initially denying (returns from settings), refresh the media grid. Listen to app lifecycle resume events to re-check permission state.
- [X] T018 [P] Add loading indicator for file resolution in `lib/widgets/message/media_picker/media_picker_panel.dart`. When send is tapped, show a progress indicator while `asset.file` resolves paths (especially for large videos).
- [X] T019 Clean up old attachment code in `lib/widgets/message/message_input_area.dart`. Remove the old `_buildAttachmentOption` helper method, old bottom sheet styling code, and the `_pickFromGallery` method (replaced by the new panel). Keep `_pickFromCamera` and `_pickDocument` as they are still used.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1
- **US1 - Panel (Phase 3)**: Depends on Phase 2 (needs provider)
- **US2 - Grid (Phase 4)**: Depends on Phase 3 (needs panel to host grid)
- **US3 - Selection (Phase 5)**: Depends on Phase 4 (needs grid to select from)
- **US4/5 - Camera/Document (Phase 6)**: Depends on Phase 3 (needs panel)
- **US6 - Send (Phase 7)**: Depends on Phase 5 (needs selection) + Phase 2 (needs sendAlbum)
- **US7 - Caption (Phase 8)**: Depends on Phase 7 (needs send working)
- **Polish (Phase 9)**: Depends on all above

### Parallel Opportunities

- T003 and T004 can run in parallel (different files)
- T009 and T010 can overlap (different files, T009 is a leaf widget)
- T017 and T018 can run in parallel (same file but different concerns)
- Phase 6 (Camera/Document) can run in parallel with Phase 4/5 (Grid/Selection) since they touch different parts of the panel

---

## Implementation Strategy

### MVP First (US1 + US2 + US3 + US6)

1. Phase 1: Setup → add dependencies
2. Phase 2: Foundational → provider + sendAlbum
3. Phase 3: US1 → panel opens with grid
4. Phase 4: US2 → grid shows thumbnails with pagination
5. Phase 5: US3 → multi-select with badges
6. Phase 7: US6 → send works
7. **STOP AND VALIDATE**: Panel opens, shows photos, multi-select works, send works

### Then Add

8. Phase 6: US4/US5 → camera and document from panel
9. Phase 8: US7 → captions
10. Phase 9: Polish

---

## Notes

- Total tasks: 19
- Phase 2 (Foundational): 4 tasks — provider + TDLib album support
- US1 (Panel): 2 tasks
- US2 (Grid): 2 tasks
- US3 (Selection): 2 tasks
- US4/5 (Camera/Document): 1 task
- US6 (Send): 2 tasks
- US7 (Caption): 1 task
- Polish: 3 tasks
- MVP scope: Phases 1-5 + 7 (T001-T015) = panel with grid, selection, and send
