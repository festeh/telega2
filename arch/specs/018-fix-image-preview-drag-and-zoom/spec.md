# Fix Image Preview Drag and Zoom

The full-screen image viewer currently mishandles touch gestures. Any vertical drag drags the whole image toward dismissal — even when the user has zoomed in and just wants to pan around the picture. The result is that zoom feels broken: you can pinch in, but the moment you try to look around the zoomed image, the viewer slides it off-screen and closes.

This feature fixes the gesture conflict and brings the viewer up to a polish level users expect from a modern photo viewer (and from official Telegram). Swipe-to-dismiss stays, but only when the image is at default zoom — once you've zoomed in, drags pan the image instead. The same fix applies to the full-screen GIF/video viewer, which copies the same broken pattern.

## What Users Can Do

1. **Zoom into a photo and pan around it**

   - **Scenario: Pan a zoomed photo**
     - **Given:** The user has opened a photo full-screen and pinched to zoom in
     - **When:** The user drags the image with one finger
     - **Then:** The image pans within the viewport. The viewer does not close.

   - **Scenario: Pinch zoom**
     - **Given:** The user is viewing a photo at default size
     - **When:** The user pinches with two fingers
     - **Then:** The image scales between 1x and at least 4x, centered on the pinch focal point

   - **Scenario: Release zoom past max or below min**
     - **Given:** The user has pinched past the allowed zoom range
     - **When:** The user lifts both fingers
     - **Then:** The image animates back to the nearest allowed scale

2. **Double-tap to toggle zoom**

   - **Scenario: Double-tap to zoom in**
     - **Given:** The user is viewing a photo at default size
     - **When:** The user double-taps anywhere on the image
     - **Then:** The image zooms in to a comfortable preset (around 2x), centered on the tap point

   - **Scenario: Double-tap to zoom out**
     - **Given:** The user is viewing a photo zoomed in
     - **When:** The user double-taps anywhere on the image
     - **Then:** The image returns to default size, centered

3. **Swipe to dismiss only when not zoomed**

   - **Scenario: Swipe-down dismiss at default zoom**
     - **Given:** The user is viewing a photo at default size
     - **When:** The user drags the image past a threshold
     - **Then:** The viewer closes. The background fades out as the image moves.

   - **Scenario: Cancel a partial swipe**
     - **Given:** The user is dragging the image but has not crossed the threshold
     - **When:** The user releases the finger
     - **Then:** The image animates back to center. The viewer stays open.

   - **Scenario: Drag is ignored as dismiss when zoomed**
     - **Given:** The user has zoomed in
     - **When:** The user drags
     - **Then:** The drag pans the image. The viewer does not close, regardless of drag distance.

4. **Close via close button or keyboard**

   - **Scenario: Tap close button**
     - **Given:** The viewer is open at any zoom level
     - **When:** The user taps the close button in the top-right corner
     - **Then:** The viewer closes immediately

   - **Scenario: Press Escape**
     - **Given:** The viewer is open on a platform with a keyboard
     - **When:** The user presses the Escape key
     - **Then:** The viewer closes immediately

5. **Reopen with a clean slate**

   - **Scenario: Reopen after zooming**
     - **Given:** The user opened a photo, zoomed in, and closed the viewer
     - **When:** The user reopens the same photo (or a different one)
     - **Then:** The viewer opens at default zoom, centered. No leftover transform from the previous session.

6. **Swipe to dismiss the GIF / video viewer**

   - **Scenario: Swipe-dismiss a GIF/video**
     - **Given:** The full-screen GIF/video viewer is open
     - **When:** The user swipes past the threshold
     - **Then:** The viewer closes. Playback stops.

   - **Scenario: Cancel a partial GIF/video swipe**
     - **Given:** The user is dragging the GIF/video but has not crossed the threshold
     - **When:** The user releases the finger
     - **Then:** The video animates back to center and keeps playing.

## Requirements

### Gesture rules

- [ ] At default zoom (scale = 1), a drag past a threshold closes the viewer
- [ ] At default zoom, a partial drag that stops before the threshold animates the image back to center
- [ ] When the image is zoomed in (scale > 1), drags pan the image inside the viewport instead of dragging the whole viewer
- [ ] Pinch-to-zoom works at any time, with a 1x to at least 4x range (no zoom-out below 1x)
- [ ] A double-tap on the image toggles between default zoom and a zoomed preset (around 2x), centered on the tap location
- [ ] A single tap on empty space outside the image bounds closes the viewer
- [ ] A single tap on the image itself does not close the viewer

### Visual feedback

- [ ] During a swipe-to-dismiss drag, the background fades from opaque to translucent in proportion to drag distance
- [ ] On dismiss-drag release without crossing the threshold, the image and background animate back to their resting state in under 250 ms
- [ ] Zoom and pan transitions feel responsive — no perceptible lag between finger movement and image movement
- [ ] Each viewer session starts at default zoom, regardless of what the user did in any prior session

### Scope of fix

- [ ] Fix applies to the full-screen photo viewer
- [ ] Fix applies to the full-screen GIF / video / animation viewer (same broken pattern lives there)
- [ ] In-bubble thumbnails are not affected — they keep their current tap-to-open behavior
- [ ] The close button stays in place and keeps working at every zoom level

### Out of scope (v1)

- [ ] Swiping left/right between photos in a chat or album
- [ ] Hero / shared-element animation from thumbnail to full-screen
- [ ] Save / share / forward actions inside the viewer
- [ ] Rotation gesture
- [ ] Zooming past 4x or below 1x (minimum stays at 1x; today's 0.5x minimum goes away because it's confusing)
- [ ] Pinch-zoom on GIFs / videos — only photos zoom; videos stay at default size with swipe-to-dismiss + close button. Adding zoom on top of an `InteractiveViewer`-wrapped video would re-introduce the gesture-arena conflict between pan-when-zoomed and swipe-to-dismiss that this feature is fixing for photos

## Open Questions

_None — resolved:_

- **Swipe-dismiss direction**: both vertical directions (up and down), matching official Telegram and today's behavior.
- **Implementation foundation**: use the `extended_image` package (actively maintained by fluttercandies, MIT, ~2k likes, 246k weekly downloads). It handles pinch-zoom, pan-when-zoomed, double-tap, and the slide-to-dismiss page transition out of the box. Considered alternatives — `photo_view` (~2y stale), `photo_view_plus` (brand-new single-maintainer fork, no track record), `easy_image_viewer` (~22mo stale) — were rejected.
