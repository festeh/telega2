# Feature Specification: Custom Emoji Rendering

**Feature Branch**: `001-custom-emoji`
**Created**: 2026-01-11
**Status**: Draft
**Input**: User description: "Use telegram-like custom emoji instead of native to ensure consistent appearance across all platforms"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Messages with Consistent Emojis (Priority: P1)

As a user viewing messages in any chat, I want to see emojis that look identical regardless of whether I'm using Android, iOS, or desktop, so that the sender's intended expression is preserved exactly.

**Why this priority**: This is the core value proposition - users currently see different emoji appearances on different platforms, leading to miscommunication and inconsistent experience.

**Independent Test**: Can be fully tested by viewing any message containing emojis on multiple platforms and confirming visual consistency.

**Acceptance Scenarios**:

1. **Given** a message contains standard Unicode emojis, **When** displayed on any platform (Android, iOS, desktop), **Then** the emoji renders identically using Telegram's custom emoji style
2. **Given** a message contains multiple emojis in sequence, **When** displayed, **Then** all emojis render with consistent style and proper spacing
3. **Given** a message contains emojis mixed with text, **When** displayed, **Then** emojis align properly with surrounding text baseline

---

### User Story 2 - Send Messages with Custom Emojis (Priority: P1)

As a user composing a message, I want to select and insert emojis that will appear consistently to all recipients, so that my intended expression is communicated accurately.

**Why this priority**: Equal to viewing - users need both send and receive consistency for the feature to be valuable.

**Independent Test**: Can be fully tested by sending a message with emojis from one device and viewing on another device/platform.

**Acceptance Scenarios**:

1. **Given** I am composing a message, **When** I open the emoji picker and select an emoji, **Then** the selected emoji appears in my input using custom Telegram-style rendering
2. **Given** I have inserted emojis in my message, **When** I send the message, **Then** recipients see the same emoji appearance I saw while composing
3. **Given** I am typing text with emoji, **When** I use emoji keyboard shortcuts or autocomplete, **Then** the inserted emoji uses custom rendering

---

### User Story 3 - Emoji Picker Experience (Priority: P2)

As a user, I want the emoji picker to display all available emojis in the consistent Telegram style, organized in familiar categories, so I can easily find and select the emoji I want.

**Why this priority**: While core rendering is P1, the picker UX is secondary - users could technically type emoji codes even without a polished picker.

**Independent Test**: Can be fully tested by opening emoji picker and browsing/searching for emojis.

**Acceptance Scenarios**:

1. **Given** I tap the emoji button, **When** the picker opens, **Then** I see emojis rendered in Telegram custom style (not native OS style)
2. **Given** the emoji picker is open, **When** I browse categories (smileys, people, animals, food, etc.), **Then** all emojis in each category display consistently
3. **Given** I am in the emoji picker, **When** I search for an emoji by name, **Then** matching emojis appear with custom rendering

---

### User Story 4 - Emoji Reactions on Messages (Priority: P2)

As a user, I want to react to messages with emojis that display consistently, so my reactions are clearly understood by all participants.

**Why this priority**: Reactions are a core messaging feature in Telegram - users expect them to render with the same custom style as message emojis.

**Independent Test**: Can be fully tested by adding a reaction to a message and viewing it on multiple platforms.

**Acceptance Scenarios**:

1. **Given** I long-press on a message, **When** the reaction picker appears, **Then** available reaction emojis display in custom Telegram style
2. **Given** I select a reaction emoji, **When** the reaction is applied, **Then** it appears on the message using custom rendering
3. **Given** a message has reactions from multiple users, **When** displayed, **Then** all reaction emojis render consistently in custom style
4. **Given** I view reaction details, **When** I see who reacted with what, **Then** emojis in the list use custom rendering

---

### User Story 5 - Animated Emoji Support (Priority: P3)

As a user, I want animated emojis to play their animations smoothly, so I can enjoy the full expressive capability of Telegram's emoji system.

**Why this priority**: Animated emojis are an enhancement over static rendering - the core consistency feature works without animations.

**Independent Test**: Can be fully tested by viewing messages with animated emojis and observing animation playback.

**Acceptance Scenarios**:

1. **Given** a message contains an animated emoji, **When** displayed, **Then** the emoji animates smoothly
2. **Given** multiple animated emojis are visible, **When** scrolling through chat, **Then** animations perform without lag or stutter
3. **Given** the app is in battery saver mode, **When** animated emojis are displayed, **Then** they show as static images to conserve resources

---

### Edge Cases

- What happens when an emoji is not available in the custom set? System falls back gracefully to a placeholder or nearest available emoji
- How does the system handle emoji skin tone modifiers? Skin tone variants render correctly with custom style
- What happens during slow network when emoji assets haven't loaded? Show placeholder while loading, then swap to custom emoji
- How does the system handle new Unicode emojis not yet in the custom set? Display with fallback indicator, queue for asset update
- What happens if emoji cache becomes corrupted? Detect corruption and re-download affected assets

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render all standard Unicode emojis using Telegram-style custom images instead of native platform fonts
- **FR-002**: System MUST display identical emoji appearance across Android, iOS, and desktop platforms
- **FR-003**: System MUST load and cache emoji assets locally for offline availability
- **FR-004**: System MUST render emojis inline with text at appropriate size relative to font size
- **FR-005**: System MUST support emoji skin tone modifiers with correct custom rendering
- **FR-006**: System MUST support animated emoji formats (TGS/Lottie) for emojis that have animations
- **FR-007**: System MUST provide an emoji picker displaying emojis in custom Telegram style
- **FR-008**: System MUST organize emoji picker into standard categories (Smileys, People, Animals, Food, Travel, Activities, Objects, Symbols, Flags)
- **FR-009**: System MUST support emoji search by name/keyword within the picker
- **FR-010**: System MUST handle missing or failed emoji assets gracefully with appropriate fallback
- **FR-011**: System MUST preserve emoji in message text when copying/pasting
- **FR-012**: System MUST support recent/frequently used emoji section in picker
- **FR-013**: System MUST render message reaction emojis using custom Telegram style
- **FR-014**: System MUST display reaction picker with custom emoji rendering
- **FR-015**: System MUST show reaction counts and user lists with consistent emoji rendering

### Key Entities

- **Emoji Asset**: A custom-rendered image (static or animated) representing a Unicode emoji codepoint. Key attributes: codepoint, asset URL, format (PNG/WebP/TGS), size variants, animation data
- **Emoji Category**: A grouping of related emojis for picker organization. Key attributes: name, display order, contained emoji codepoints
- **Emoji Cache**: Local storage of downloaded emoji assets for offline use. Key attributes: codepoint-to-file mapping, cache size, last updated timestamp
- **Recent Emojis**: User's recently used emojis for quick access. Key attributes: codepoint, usage count, last used timestamp

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Emojis display identically across all supported platforms (visual consistency verified by screenshot comparison)
- **SC-002**: Emoji assets load and display within 100ms after first download (cached access)
- **SC-003**: Initial emoji asset download completes within reasonable time on standard connections
- **SC-004**: Emoji picker opens and displays within 300ms of user tap
- **SC-005**: Animated emojis play at smooth frame rate without causing UI jank
- **SC-006**: Emoji cache size remains reasonable (configurable limit with automatic cleanup)
- **SC-007**: Users can find and insert any standard emoji within 10 seconds using picker or search

## Assumptions

- Telegram provides publicly accessible emoji assets (or they can be bundled with the app)
- The existing emoji picker component can be replaced or wrapped with custom rendering
- Flutter's text rendering system allows custom inline image replacement for emoji codepoints
- Standard Telegram emoji set covers all commonly used Unicode emojis
- Device storage is sufficient for emoji asset cache (estimated 10-50MB)
- Network connectivity is available for initial asset download (with graceful offline fallback after caching)

## Out of Scope

- Custom emoji creation or upload by users
- Premium/paid custom emoji packs (Telegram Premium feature)
- Sticker functionality (separate from standard emojis)
- Emoji suggestions based on message content
