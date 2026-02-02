# Tasks: Custom Emoji Rendering

**Input**: Design documents from `/specs/001-custom-emoji/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/` for source, `test/` for tests
- Based on plan.md structure with clean architecture

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure for emoji feature

- [x] T001 Create emoji directory structure: lib/core/emoji/, lib/domain/entities/, lib/data/repositories/
- [x] T002 [P] Create emoji_providers.dart skeleton in lib/presentation/providers/emoji_providers.dart
- [x] T003 [P] Create assets/emoji/ directory for bundled fallback emojis

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core emoji infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Emoji entity class with EmojiCategory enum in lib/domain/entities/emoji.dart
- [x] T005 [P] Create EmojiCacheEntry model in lib/core/emoji/emoji_cache.dart
- [x] T006 [P] Create static emoji data (codepoints, names, categories) in lib/core/emoji/emoji_data.dart
- [x] T007 Create EmojiCache class with LRU eviction logic in lib/core/emoji/emoji_cache.dart
- [x] T008 Create EmojiAssetManager for TDLib integration in lib/core/emoji/emoji_asset_manager.dart
- [x] T009 Create EmojiRepository interface in lib/domain/repositories/emoji_repository.dart
- [x] T010 Implement EmojiRepository in lib/data/repositories/emoji_repository_impl.dart
- [x] T011 Create Riverpod providers in lib/presentation/providers/emoji_providers.dart

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Messages with Consistent Emojis (Priority: P1) 🎯 MVP

**Goal**: Render emojis in message bubbles using custom Telegram-style images instead of native fonts

**Independent Test**: View any message containing emojis - should display custom-rendered images, not native platform emojis

### Implementation for User Story 1

- [x] T012 [US1] Create TelegramEmojiWidget for single emoji rendering in lib/widgets/emoji_sticker/telegram_emoji_widget.dart
- [x] T013 [US1] Implement emoji codepoint detection regex utility in lib/core/emoji/emoji_utils.dart
- [x] T014 [US1] Create EmojiText widget for text with inline custom emojis in lib/widgets/message/emoji_text.dart
- [x] T015 [US1] Implement fallback rendering when emoji asset not available in lib/widgets/emoji_sticker/telegram_emoji_widget.dart
- [x] T016 [US1] Integrate EmojiText into MessageBubble - modify lib/widgets/message/message_bubble.dart
- [x] T017 [US1] Add emoji preloading on app startup in lib/main.dart

**Checkpoint**: Messages now display emojis with custom Telegram-style rendering

---

## Phase 4: User Story 2 - Send Messages with Custom Emojis (Priority: P1)

**Goal**: Users can compose messages with emojis that preview in custom style before sending

**Independent Test**: Open message composer, insert emoji - should display custom-rendered in input field

### Implementation for User Story 2

- [x] T018 [US2] Create basic emoji grid widget for picker in lib/widgets/emoji_sticker/emoji_grid.dart
- [x] T019 [US2] Create simple emoji picker without search/categories in lib/widgets/emoji_sticker/basic_emoji_picker.dart
- [x] T020 [US2] Integrate basic picker into emoji_tab.dart - modify lib/widgets/emoji_sticker/emoji_tab.dart
- [x] T021 [US2] Ensure selected emoji inserts using custom rendering in message input
- [x] T022 [US2] Implement recent emoji tracking via SharedPreferences in lib/data/repositories/emoji_repository_impl.dart

**Checkpoint**: Users can compose and send messages with custom emoji preview

---

## Phase 5: User Story 3 - Emoji Picker Experience (Priority: P2)

**Goal**: Full-featured emoji picker with categories, search, and recent emojis

**Independent Test**: Open emoji picker, browse categories, search for emoji - all render in custom style

### Implementation for User Story 3

- [x] T023 [US3] Create category tab bar widget in lib/widgets/emoji_sticker/custom_emoji_picker.dart (integrated)
- [x] T024 [US3] Implement emoji search functionality in lib/widgets/emoji_sticker/emoji_search.dart
- [x] T025 [US3] Create full CustomEmojiPicker with categories in lib/widgets/emoji_sticker/custom_emoji_picker.dart
- [x] T026 [US3] Add recent emojis section to picker in lib/widgets/emoji_sticker/custom_emoji_picker.dart
- [x] T027 [US3] Replace emoji_picker_flutter usage with CustomEmojiPicker in lib/widgets/emoji_sticker/emoji_tab.dart
- [x] T028 [US3] Implement emoji search by name and shortcodes in lib/core/emoji/emoji_data.dart (already implemented)

**Checkpoint**: Emoji picker fully functional with categories, search, and recents

---

## Phase 6: User Story 4 - Emoji Reactions on Messages (Priority: P2)

**Goal**: Message reactions display and picker use custom emoji rendering

**Independent Test**: Long-press message, select reaction - displays custom emoji style

### Implementation for User Story 4

- [x] T029 [US4] Create ReactionPicker widget with quick reactions in lib/widgets/message/reaction_picker.dart
- [x] T030 [US4] Update ReactionBar to use TelegramEmojiWidget - modify lib/widgets/message/reaction_bar.dart
- [x] T031 [US4] Create ReactionDisplay widget for message reactions in lib/widgets/message/reaction_display.dart
- [x] T032 [US4] Integrate reaction picker into message long-press menu - modified lib/widgets/message/message_list.dart
- [x] T033 [US4] Add expand button to open full emoji picker for reactions

**Checkpoint**: Reactions use custom emoji rendering throughout

---

## Phase 7: User Story 5 - Animated Emoji Support (Priority: P3)

**Goal**: Animated emojis (TGS/Lottie) play smoothly in messages

**Independent Test**: View message with animated emoji - animation plays at 60fps

### Implementation for User Story 5

- [x] T034 [US5] Add Lottie rendering support to TelegramEmojiWidget in lib/widgets/emoji_sticker/telegram_emoji_widget.dart (already implemented)
- [x] T035 [US5] Implement animation state management (play/pause) in lib/presentation/notifiers/emoji_animation_notifier.dart
- [x] T036 [US5] Add battery saver mode detection to disable animations in lib/core/emoji/emoji_animation_controller.dart
- [x] T037 [US5] Optimize animation performance for multiple visible animated emojis (AnimatedEmojiTracker in emoji_animation_controller.dart)
- [x] T038 [US5] Add animated emoji support to EmojiText widget in lib/widgets/message/emoji_text.dart (already has animateEmojis parameter)

**Checkpoint**: Animated emojis render smoothly with performance optimizations

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, optimization, and cleanup

- [ ] T039 [P] Implement skin tone modifier support (DEFERRED - not needed for now)
- [ ] T040 [P] Add loading placeholder shimmer effect for emojis (DEFERRED)
- [ ] T041 [P] Implement cache size monitoring and settings UI (DEFERRED)
- [ ] T042 Handle copy/paste with emojis - preserve emoji data (DEFERRED)
- [ ] T043 Add error handling for corrupted cache detection and recovery (DEFERRED)
- [ ] T044 Performance optimization for large message lists with many emojis (basic optimization via AnimatedEmojiTracker)
- [x] T045 Remove emoji_picker_flutter dependency from pubspec.yaml after full migration

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 - complete sequentially (US1 first as it's viewing, US2 depends on picker basics)
  - US3 and US4 are both P2 - can proceed after US1/US2
  - US5 is P3 - enhancement layer after core functionality
- **Polish (Phase 8)**: Depends on US1-US4 being complete

### User Story Dependencies

```
Foundational (Phase 2)
       │
       ├───► US1: View Messages (P1) - Core rendering
       │          │
       │          ▼
       ├───► US2: Send Messages (P1) - Basic picker
       │          │
       │          ├───► US3: Full Picker (P2)
       │          │
       │          └───► US4: Reactions (P2)
       │                    │
       │                    ▼
       └─────────────► US5: Animations (P3)
```

### Parallel Opportunities

**Within Phase 2 (Foundational)**:
- T005 and T006 can run in parallel (different files)

**Within Phase 8 (Polish)**:
- T039, T040, T041 can run in parallel (different files)

---

## Parallel Example: Foundational Phase

```bash
# Launch parallel foundational tasks:
Task: "Create EmojiCacheEntry model in lib/core/emoji/emoji_cache.dart"
Task: "Create static emoji data in lib/core/emoji/emoji_data.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1 (View Messages)
4. **STOP and VALIDATE**: Messages display custom emojis
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (View) → Messages show custom emojis (MVP!)
3. Add US2 (Send) → Basic picker works
4. Add US3 (Full Picker) → Categories, search, recents
5. Add US4 (Reactions) → Reactions use custom emojis
6. Add US5 (Animations) → Animated emojis play
7. Polish phase → Edge cases and optimization

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Current app uses emoji_picker_flutter - migration happens gradually
