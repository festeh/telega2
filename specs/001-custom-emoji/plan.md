# Implementation Plan: Custom Emoji Rendering

**Branch**: `001-custom-emoji` | **Date**: 2026-01-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-custom-emoji/spec.md`

## Summary

Replace native platform emoji rendering with Telegram-style custom emoji images to ensure visual consistency across Android, iOS, and desktop. This involves creating a custom emoji rendering system that downloads, caches, and displays emoji assets as images (static PNG/WebP or animated TGS/Lottie) instead of using system fonts.

## Technical Context

**Language/Version**: Dart 3.10+, Flutter
**Primary Dependencies**: flutter_riverpod (state), lottie (animations), path_provider (storage), existing TDLib integration
**Storage**: Local file cache via path_provider, SharedPreferences for metadata
**Testing**: flutter_test (unit/widget tests)
**Target Platform**: Android, iOS, Linux desktop (cross-platform Flutter)
**Project Type**: Mobile/Desktop Flutter application
**Performance Goals**: <100ms cached emoji render, <300ms picker open, 60fps animations
**Constraints**: <50MB cache size, offline-capable after initial download
**Scale/Scope**: ~3500 Unicode emojis, 9 categories, reactions support

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution template is not yet configured for this project. Proceeding with standard Flutter best practices:

- [x] Follow existing project architecture patterns (Riverpod, clean architecture)
- [x] No unnecessary abstractions - reuse existing widgets where possible
- [x] Keep changes focused on emoji rendering scope
- [x] Maintain backward compatibility with existing message display

## Project Structure

### Documentation (this feature)

```text
specs/001-custom-emoji/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── emoji/                    # NEW: Core emoji utilities
│       ├── emoji_asset_manager.dart
│       ├── emoji_cache.dart
│       └── emoji_data.dart
├── domain/
│   └── entities/
│       └── emoji.dart            # NEW: Emoji entity
├── data/
│   └── repositories/
│       └── emoji_repository.dart # NEW: Emoji asset loading
├── presentation/
│   ├── notifiers/
│   │   └── emoji_notifier.dart   # NEW: Emoji state management
│   └── providers/
│       └── emoji_providers.dart  # NEW: Riverpod providers
└── widgets/
    ├── emoji_sticker/
    │   ├── emoji_tab.dart        # MODIFY: Use custom rendering
    │   ├── custom_emoji_picker.dart    # NEW: Custom emoji grid
    │   └── telegram_emoji_widget.dart  # NEW: Single emoji renderer
    └── message/
        ├── message_bubble.dart   # MODIFY: Custom emoji in text
        ├── reaction_bar.dart     # MODIFY: Custom emoji reactions
        └── emoji_text.dart       # NEW: Text with inline custom emoji

assets/
└── emoji/                        # Bundled emoji assets (fallback)
    └── [category]/
        └── [codepoint].webp
```

**Structure Decision**: Follows existing Flutter project structure with clean architecture. New emoji-related code organized under `core/emoji/` for utilities, `domain/entities/` for data models, and `widgets/` for UI components. Minimal changes to existing files.

## Complexity Tracking

No constitution violations. Design follows existing patterns.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Asset Source | TDLib emoji documents + bundled fallback | Telegram provides emoji via API; bundle subset for offline first-run |
| Rendering | Image.asset/Image.file with Lottie for animated | Flutter-native approach, lottie package already in deps |
| Text Integration | Custom InlineSpan or RichText with WidgetSpan | Flutter supports inline widgets in text |
| Caching | File-based with LRU eviction | Simple, persistent, proven approach |
