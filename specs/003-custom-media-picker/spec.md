# Custom Media Attachment Picker

## What Users Can Do

1. **Open the attachment panel**
   User taps the attachment (paperclip) button in the chat input area. Instead of a small bottom sheet with three icons, a panel slides up from the bottom showing a photo/video grid.
   - Works when: Panel opens showing recent device photos and videos in a grid
   - Fails when: No media permission granted, show a clear prompt to grant access

2. **Browse and select photos/videos from the grid**
   User sees their recent photos and videos in a scrollable grid (like Telegram Android). They can tap to select one or multiple items. Selected items show a numbered badge (selection order).
   - Works when: Grid loads quickly, shows thumbnails, supports smooth scrolling
   - Fails when: Device has no photos/videos, show an empty state with a message

3. **Multi-select media**
   User taps multiple items to select them. Each selected item gets a numbered circle overlay (1, 2, 3...) showing send order. Tapping a selected item deselects it and renumbers the rest.
   - Works when: User selects up to 10 items (Telegram album limit)
   - Fails when: User tries to select more than 10, show a brief message

4. **Take a photo with the camera**
   A camera button in the panel opens the device camera. After capturing, the photo is sent directly (same as current behavior).
   - Works when: Camera opens, photo captured and sent
   - Fails when: On Linux desktop, show "Camera not available" message

5. **Pick a document/file**
   A file button in the panel opens the system file picker for any file type. After picking, the file is sent as a document (same as current behavior).
   - Works when: File picker opens, file selected and sent
   - Fails when: User cancels picker, nothing happens (no error)

6. **Send selected media**
   User taps the send button to send all selected items. Photos and videos are sent in original quality. Multiple items are grouped as an album when possible.
   - Works when: All selected items are sent in order, panel closes
   - Fails when: Send fails, show error message, keep panel open

7. **Add a caption**
   User can type a caption in the existing input field before sending. The caption attaches to the first item (or the album).
   - Works when: Caption appears on the sent message
   - Fails when: Caption is empty, send without caption (not an error)

## Requirements

- [ ] Replace the current bottom sheet (Gallery/Camera/Document icons) with an inline attachment panel
- [ ] Show device photos and videos in a grid (3-4 columns), sorted by date (newest first)
- [ ] Load thumbnails efficiently — no full-size images in the grid
- [ ] Support selecting 1 to 10 items with numbered selection badges
- [ ] Send all media in original quality (no compression toggle)
- [ ] Keep Camera and Document buttons accessible within the panel (as icons/buttons at the top or in a row)
- [ ] Support album grouping when sending multiple items (up to 10, matching Telegram's limit)
- [ ] Request media permissions at panel open time if not already granted
- [ ] Handle permission denial gracefully with a message and settings link
- [ ] Panel should be dismissible by swiping down or tapping outside
- [ ] Maintain current send behavior: photos via sendPhoto, videos via sendVideo, documents via sendDocument
- [ ] Work on Android (primary target) and degrade gracefully on Linux desktop (no gallery, just Camera/Document)

## Decisions

- Flat recent-media grid (no album/folder navigation)
- Video thumbnails show duration overlay
- No search/filter
