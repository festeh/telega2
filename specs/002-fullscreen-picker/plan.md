# Implementation Plan: Fullscreen Emoji/Sticker Picker

**Branch**: `002-fullscreen-picker` | **Date**: 2026-01-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-fullscreen-picker/spec.md`

## Summary

Transform the inline emoji/sticker picker into a fullscreen modal overlay that provides more browsing space while maintaining all existing functionality (emoji selection, sticker selection, search, categories, recents).

## Technical Context

**Language/Version**: Dart 3.10+, Flutter 3.x
**Primary Dependencies**: flutter_riverpod (state management), existing CustomEmojiPicker/EmojiStickerPicker components
**Storage**: N/A (uses existing emoji repository for recents)
**Testing**: Flutter widget tests (flutter_test)
**Target Platform**: Linux desktop (primary), Android, iOS
**Project Type**: Mobile/Desktop Flutter app
**Performance Goals**: 300ms transition animation, 100ms search response, 60fps scrolling
**Constraints**: Must preserve existing inline picker behavior, support keyboard and gesture dismissal
**Scale/Scope**: ~4 modified files, 1 new widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Single codebase: PASS (Flutter project)
- Minimal abstraction: PASS (extending existing picker, not creating new abstraction layer)
- Reuse existing: PASS (reusing CustomEmojiPicker, EmojiGrid, search components)

## Project Structure

### Documentation (this feature)

```text
specs/002-fullscreen-picker/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (minimal - UI only)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── widgets/
│   ├── emoji_sticker/
│   │   ├── emoji_sticker_picker.dart     # MODIFY: Add fullscreen variant
│   │   ├── fullscreen_emoji_picker.dart  # NEW: Fullscreen modal wrapper
│   │   ├── custom_emoji_picker.dart      # MODIFY: Responsive columns/sizing
│   │   ├── emoji_tab.dart                # MODIFY: Pass through responsive params
│   │   └── ...
│   └── message/
│       └── message_input_area.dart       # MODIFY: Trigger fullscreen modal
├── presentation/
│   ├── state/
│   │   └── emoji_sticker_state.dart      # MINIMAL: Add fullscreen flag if needed
│   └── notifiers/
│       └── emoji_sticker_notifier.dart   # MINIMAL: Add showFullscreen method
```

**Structure Decision**: Extending existing Flutter widget structure with minimal additions. Primary change is adding a new fullscreen wrapper widget that reuses existing picker components.

## Complexity Tracking

No violations. Feature uses existing patterns:
- Modal bottom sheet pattern (already used for attachments, reactions)
- Responsive sizing (CustomEmojiPicker already has columns/emojiSize params)
- Riverpod state management (existing emojiStickerProvider)

## Architecture Overview

### Current State
- `EmojiStickerPicker` is displayed inline below `MessageInputArea`
- Height dynamically matches keyboard height (300px default)
- Toggle via emoji button in text field suffix

### Target State
- Emoji button opens fullscreen modal overlay using `Navigator.push` or `showModalBottomSheet` with `isScrollControlled: true`
- Modal covers entire screen with:
  - Header bar with close button
  - Search bar
  - Category tabs
  - Expanded emoji/sticker grid
- Swipe down or back button dismisses
- Emoji selection inserts into message input and keeps modal open

### Key Design Decisions

1. **Modal vs Route**: Use fullscreen modal bottom sheet (simpler, maintains parent context for text insertion)
2. **Responsive Grid**: Calculate columns based on screen width (6 min phone, 10+ tablet)
3. **State Preservation**: Keep text controller reference for direct emoji insertion
4. **Animation**: Use Material page transition (300ms) for smooth open/close

## Implementation Phases

### Phase 0: Research (minimal - straightforward UI change)
- Confirm Flutter fullscreen modal patterns
- Review existing responsive sizing in CustomEmojiPicker

### Phase 1: Design
- Define responsive column calculation
- Design header layout with close button
- Define animation transitions

### Phase 2: Tasks (via /speckit.tasks)
- Create FullscreenEmojiPicker widget
- Add responsive column calculation
- Modify trigger to open fullscreen modal
- Add gesture dismissal support
- Test orientation changes
