# Plan: GIF Support

**Branch**: `009-gif-support`

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- Playback: video_player (already in pubspec.yaml — TDLib stores GIFs as MP4)
- TDLib types: `messageAnimation`, `inputMessageAnimation`

## Structure

Files to change:

```
lib/
├── domain/
│   ├── entities/chat.dart              # Add AnimationInfo, wire into Message
│   ├── events/message_events.dart      # Add MessageAnimationUpdatedEvent
│   └── repositories/telegram_client_repository.dart  # Add sendAnimation()
├── data/
│   └── repositories/tdlib_telegram_client.dart  # Parse, track, download, send animations
├── presentation/
│   └── notifiers/message_notifier.dart  # Handle animation download events
└── widgets/
    └── message/
        ├── animation_message.dart       # NEW — auto-playing GIF widget
        ├── message_bubble.dart          # Swap placeholder for AnimationMessageWidget
        └── message_input_area.dart      # Send .gif files as animations
```

## Approach

### 1. Add AnimationInfo to data model (`chat.dart`)

Create `AnimationInfo` class matching the existing `VideoInfo` pattern:
- Fields: `path`, `fileId`, `width`, `height`, `duration`, `thumbnailPath`, `thumbnailFileId`
- Add `copyWith` method
- Add `animation` field to `Message`, its constructor, and `copyWith`

### 2. Parse `messageAnimation` from TDLib (`chat.dart`)

In `Message.fromJson`, add `parseAnimationInfo()` following the `parseVideoInfo()` pattern:
- Extract `contentMap['animation']` map
- Read `animation['animation']` for the file (path, fileId)
- Read `animation['thumbnail']` for the thumbnail (path, fileId)
- Read width, height, duration
- Extract caption text from `messageAnimation` content type (currently returns hardcoded `'🎞️ GIF'`)

### 3. Track animation file downloads (`tdlib_telegram_client.dart`)

Follow the video/photo tracking pattern:
- Add `_animationFileToMessage` map (fileId → chatId + messageId)
- In `_addOrUpdateMessage()`, register animation fileId when present
- Add `_updateMessageAnimationByFileId()` method — same shape as video version
- Call it from file download completion handler (alongside photo/sticker/video)

### 4. Add animation download event (`message_events.dart`)

Add `MessageAnimationUpdatedEvent` class with `chatId`, `messageId`, `animationPath` — same pattern as `MessageVideoUpdatedEvent`.

### 5. Handle event in message notifier (`message_notifier.dart`)

Add a `case MessageAnimationUpdatedEvent` in the event switch, calling `_handleMessageAnimationUpdated()` — same shape as `_handleMessageVideoUpdated()` but operates on `message.animation`.

### 6. Create AnimationMessageWidget (`animation_message.dart` — NEW)

Auto-playing inline GIF widget using `video_player`:
- Show thumbnail while the file downloads (with download progress ring)
- Once file is available, auto-play in a loop with no sound, no controls
- Tap opens full-screen viewer (reuse the existing `_FullScreenVideoPlayer` pattern but with looping + muted)
- Use `calculateMediaDimensions()` from `media_utils.dart` for sizing
- Show "GIF" badge in bottom-left corner

Key difference from VideoMessageWidget: GIFs auto-play inline, muted, looping, with no play button overlay.

### 7. Wire up in message bubble (`message_bubble.dart`)

Replace the placeholder `_buildMediaMessage(context, Icons.gif, 'GIF')` with a real widget call that renders `AnimationMessageWidget` with data from `message.animation`.

### 8. Send GIF files as animations (`message_input_area.dart`)

- In `_sendDocument()`: detect `.gif` extension and call `sendAnimation()` instead of `sendPhoto()`
- Add `sendAnimation()` to repository interface and TDLib client, using `inputMessageAnimation` TDLib type

### 9. Add sendAnimation to repository (`telegram_client_repository.dart` + `tdlib_telegram_client.dart`)

Add `sendAnimation(chatId, MediaItem, {caption, replyToMessageId})`:
- Same pattern as `sendPhoto()` but uses `inputMessageAnimation` with `animation` key

## Risks

- **Memory with auto-play**: Multiple GIFs in view could use significant memory. Mitigation: only auto-play GIFs that are visible (the widget's lifecycle handles this — `video_player` controllers are created in `initState` and disposed in `dispose`).
- **Large GIF files**: Some GIFs are very large. Mitigation: TDLib handles download progress — show the progress ring like we do for videos.

## Open Questions

- None — the pattern is well-established by photo/video support. This is a direct extension.
