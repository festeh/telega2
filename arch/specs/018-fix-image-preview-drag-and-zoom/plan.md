# Plan: Fix Image Preview Drag and Zoom

**Spec**: arch/specs/018-fix-image-preview-drag-and-zoom/spec.md

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter (existing)
- New dependency: `extended_image: ^10.0.1` (fluttercandies, MIT)
- Existing: `media_kit` / `media_kit_video` (video playback), `flutter_riverpod` (state)
- Testing: `flutter_test` (existing — no new test infra)

## Structure

Files this plan touches:

```text
pubspec.yaml                                       # add extended_image
lib/widgets/message/photo_message.dart             # rewrite _FullScreenImageViewer
lib/widgets/message/animation_message.dart         # rewrite _FullScreenAnimation (add zoom + dismiss)
lib/core/constants/ui_constants.dart               # remove unused GestureThreshold class
```

No new files. No changes to in-bubble widgets, message routing, providers, or constants outside `GestureThreshold`.

## Approach

### Setup

- **Add dependency**: `flutter pub add extended_image` (locks to current major).
- **Page route**: keep the existing `Navigator.push(PageRouteBuilder)` for both viewers. The route stays opaque-false with `barrierColor: Colors.black87`; the slide-dismiss visual lives inside the page, not in the route.

### Photo viewer (`_FullScreenImageViewer`)

The viewer becomes three nested widgets, top to bottom:

1. **`ExtendedImageSlidePage`** — handles swipe-to-dismiss and the background fade.
   - `slideAxis: SlideAxis.vertical` (both up and down — matches Telegram and today's behavior).
   - `slideType: SlideType.onlyImage` so the close button stays put while the image slides.
   - `slidePageBackgroundHandler` returns `Colors.black.withOpacity(...)` driven by the `offset` argument so the background fades during a partial drag.
2. **`ExtendedImage.file`** with `mode: ExtendedImageMode.gesture` — handles pinch-zoom, pan-when-zoomed, and the rubber-band animation back to allowed scale.
   - `initGestureConfigHandler`: `GestureConfig(minScale: 1.0, maxScale: 4.0, animationMinScale: 0.9, animationMaxScale: 4.5, initialScale: 1.0, inPageView: false, initialAlignment: InitialAlignment.center)`.
   - `onDoubleTap`: animates `state.handleDoubleTap` between 1.0 and 2.0, centered on `state.pointerDownPosition`.
3. **Overlay stack** — `SafeArea` + close button (top-right) + `KeyboardListener` for Escape. Unchanged from today.

The image and the close button live in a `Stack` so the button receives taps even when the image is mid-drag.

### Tap rules ("tap image does nothing, tap empty space closes")

`ExtendedImage` in gesture mode swallows pointer events on the image bounds. Wrap the page background (the area outside the image) in a `GestureDetector(onTap: _close, behavior: HitTestBehavior.translucent)`. Because the image is opaque to hit-testing, taps on the image won't bubble up; taps on the letterboxed background will.

### GIF / video viewer (`_FullScreenAnimation`)

The video equivalent uses the same `ExtendedImageSlidePage` shell but a different inner widget:

1. **`ExtendedImageSlidePage`** — same config as the photo viewer.
2. **`InteractiveViewer`** wrapping the `Video(controller: _videoController)` widget — provides pinch-zoom and pan-when-zoomed for video frames.
   - `minScale: 1.0`, `maxScale: 4.0`, `panEnabled: true`, `scaleEnabled: true`.
   - A `TransformationController` tracks scale; `ExtendedImageSlidePage` watches its own gesture state, but we also gate slide-dismiss on `controller.value` ≈ identity using `slideOffsetHandler` (only allow slide when the inner `InteractiveViewer` is at default scale).
3. Overlay stack (close button + Escape) — unchanged.

Double-tap on video: `GestureDetector(onDoubleTapDown: ...)` listens for double-taps, animates the `TransformationController` between identity and a 2x scale centered on the tap position.

### Reset on reopen

Both viewers create their state objects (`ExtendedImageSlidePage`, `TransformationController`, `Player`) inside `initState`. Since `Navigator.push` builds a new route each time the user taps a thumbnail, state is fresh by construction. No persistent controllers in singletons or providers.

### Cleanup

- Remove `GestureThreshold` and `dismissDrag` from `lib/core/constants/ui_constants.dart` once `photo_message.dart` no longer references them. Confirmed via grep: only one call site.
- Delete the old `_dragOffset` state field, `Transform.translate`, and the outer `GestureDetector` in both viewers.

### Per-spec-requirement mapping

1. **Pan a zoomed photo** → `ExtendedImage` gesture mode handles pan internally above scale 1.
2. **Pinch zoom 1x–4x** → `GestureConfig(minScale: 1.0, maxScale: 4.0)`.
3. **Rubber-band release** → `animationMinScale: 0.9, animationMaxScale: 4.5` (overshoot allowed during drag, snaps back on release).
4. **Double-tap toggle** → `onDoubleTap` callback animates between 1.0 and 2.0 around `pointerDownPosition`.
5. **Tap close button / Escape** → existing `IconButton` and `KeyboardListener` survive the rewrite.
6. **Tap on image does nothing, tap on empty space closes** → outer `GestureDetector(onTap: _close, behavior: translucent)` with `ExtendedImage` opaque to hit-tests in the middle.
7. **Swipe-dismiss only when not zoomed** → `ExtendedImageSlidePage` queries the inner gesture state and skips slide-dismiss when scale > 1 (built-in behavior).
8. **Cancel partial swipe** → built into `ExtendedImageSlidePage`'s release animation.
9. **Both vertical directions** → `slideAxis: SlideAxis.vertical`.
10. **Background fades during dismiss-drag** → `slidePageBackgroundHandler` reads the slide offset and computes opacity.
11. **Reset on reopen** → fresh `Navigator` route per open; no persistent state.
12. **GIF / video viewer** → same shell, swap `ExtendedImage` for `InteractiveViewer(child: Video(...))`.
13. **Min scale 1x** (no 0.5x) → `GestureConfig.minScale: 1.0`.

## Risks

- **`ExtendedImageSlidePage` + non-image inner widget**: documented behavior is around `ExtendedImage` children. Need to verify slide-dismiss still works correctly when wrapping `InteractiveViewer + Video`. Mitigation: build the photo viewer first, prove the pattern, then port it to video; if the package can't see inside `InteractiveViewer` to suppress dismiss-when-zoomed, fall back to a manual `slideOffsetHandler` that reads our `TransformationController`.
- **Video pan + slide-dismiss gesture conflict**: same root cause as the bug we're fixing — two layers competing for vertical drags. Should be resolved by gating slide-dismiss on `controller.value.getMaxScaleOnAxis() == 1.0`. Verify on touch and trackpad.
- **`extended_image` pulls extra deps** (`extended_image_library`, `vector_math`, `meta`): all standard, no native code, no platform setup.
- **Hit-test ordering for "tap-on-image-doesn't-close"**: `ExtendedImage` in gesture mode does swallow pointer down events, but verify a quick tap (no scale change) doesn't fall through to the outer `GestureDetector`. If it does, swap the outer `onTap` for `onTapUp` and check the local position against the image bounds.
- **`Image.file` → `ExtendedImage.file` rendering parity**: the in-bubble `PhotoMessageWidget` thumbnail is unchanged (it uses `Image.file` and we're not touching it). The full-screen viewer's `ExtendedImage.file` may render slightly differently (gamma, fit). `BoxFit.contain` parity should be fine; verify visually.
- **Manual testing only**: there are no existing tests for either viewer, and gesture tests in Flutter widget tests are notoriously flaky. The spec's acceptance is "feels right" — verify on a real touch device, on the desktop app, and via trackpad pinch.

## Open Questions

_None._
