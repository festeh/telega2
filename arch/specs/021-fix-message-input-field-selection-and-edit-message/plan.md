# Plan: Fix message input selection bug + unify edit-message UX

**Branch**: `021-fix-message-input-field-selection-and-edit-message`
**Spec**: none — captured directly from user query:
> "Input field for messages behaves weirdly — when I select text cursors appear and don't come back. Additionally, edit message just sucks — we should use input field as in sending messages."

## Problem

Two issues, one shared root:

1. **Selection/cursor glitch in the composer.**
   When text is selected in the bottom message input on **Android**, selection handles ("cursors" — the teardrop pins at each end of the selection) appear and stay visible / don't dismiss after deselection. Symptom is unclear without a repro session, so step 1 of the work is reproducing and pinning the cause before fixing.

2. **Edit-message dialog is a separate, minimal `TextFormField` in an `AlertDialog`.**
   `lib/widgets/message/message_list.dart:551-591` re-implements message editing from scratch: no multiline, no emoji picker, no styling parity with the composer at `lib/widgets/message/message_input_area.dart`. The user wants edit to reuse the composer.

## Tech stack

- Dart 3.10+, Flutter (existing)
- State: flutter_riverpod (existing `messageProvider` / `MessageState`)
- No new dependencies

## Approach

Two phases — investigate-then-fix for the bug, refactor for the UX.

### Phase 1 — Reproduce and fix the selection bug

The composer's `_onTextChanged` calls `setState` on every keystroke
(`message_input_area.dart:63-68`), which rebuilds the whole `_buildInputArea`
including the `TextField`'s `decoration` and `suffixIcon`. On Android, the
selection-handle overlay is hosted in a separate `OverlayEntry` and is
sensitive to focus/scroll/rebuild events. Suspected candidates, ranked:

1. **`setState` rebuild churn dislodging the selection overlay.** Every keystroke rebuilds the row containing the `TextField` and creates a fresh `IconButton` for the suffix emoji button. On Android, this can leave the selection handles' overlay attached without a live anchor, so they stay visible when they shouldn't. Fix: drop `setState` from `_onTextChanged`; derive `_isMultiline` via `ValueListenableBuilder` on the controller wrapping only the `TextField`'s `textInputAction` (or just compute it inside `onSubmitted`). Avoid rebuilding the row per keystroke. Hoist `IconButton`s and decoration into stable references.
2. **Emoji picker `_focusNode.unfocus()` (line 526) without restoring focus on close.** When the picker closes the keyboard never reattaches and the selection toolbar can be left stranded. Fix: re-request focus on picker dismiss, and use `_focusNode.unfocus(disposition: UnfocusDisposition.scope)` so the system selection overlay is also dismissed.
3. **Stale Material selection controls on Android (Flutter framework quirk).** If the above don't fix it, fall back to passing `selectionControls: MaterialTextSelectionControls()` explicitly and/or wrap the `TextField` in a `TextSelectionTheme` to ensure handles dispose with focus.

**Plan of attack:** install a debug build on the user's Android device, repro the bug once with the user watching, then pick the matching fix. **Do not skip the repro step** — guessing wastes time, and the symptom phrasing ("cursors don't come back") is ambiguous between "handles stay visible" and "caret disappears".

### Phase 2 — Build a reusable `MessageTextInput` widget from scratch

Build a new, self-contained widget responsible for the text-input chrome only:
rounded border, hint, emoji suffix button, multiline behavior, keyboard action,
focus/selection. It owns its own `TextEditingController` and `FocusNode` (or
accepts them) and is platform-agnostic about *what* the submitted text means
— it just hands the text up via callbacks.

```dart
class MessageTextInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool enabled;
  final VoidCallback? onSubmit;          // pressed send / save
  final VoidCallback? onEmojiTap;        // suffix emoji button
  // No attachment button — that lives in the parent composer, not here.
}
```

Then refactor:

- `MessageInputArea` (send composer) uses `MessageTextInput` for its text field. The attachment button, send button, reply preview, and emoji picker integration stay in `MessageInputArea` — they're send-specific.
- A new `MessageEditBar` widget replaces the `AlertDialog` in `message_list.dart`. It also uses `MessageTextInput`, but with a save button instead of send, a small "Editing: …" banner above, and a leading **cross (close) button** to cancel edit mode. No attachment button. No media picker.
- The `MessageEditBar` is rendered **in place of** `MessageInputArea` at the bottom of `ChatScreen` when `editingMessage` is set on `messageProvider`. (Simplest layout change: `ChatScreen` switches between the two widgets based on state.)

### State changes

- `MessageState` gains `Message? editingMessage` plus `setEditing` / `clearEditing` (mirroring the existing `replyingToMessage` pattern at `message_state.dart:14-118`).
- `MessageNotifier` gains `startEditing(Message)` / `cancelEditing()`. The existing `editMessage(...)` clears `editingMessage` on success.
- Entering edit clears reply state; entering reply clears edit state. Mutually exclusive.

### Edit UX (concrete)

```
┌─────────────────────────────────────────────┐
│  ✎  Editing message                         │ ← banner
│     Original text preview…                  │
├─────────────────────────────────────────────┤
│ [✕]  [ Edit text here.............. 😊 ] [✓]│ ← input row
└─────────────────────────────────────────────┘
   ↑                                          ↑
   cancel cross                               save check
```

- **✕ (leading)** — cancels edit, restores any pre-edit draft text.
- **✓ (trailing)** — saves. Disabled if text is empty or unchanged.
- Multiline + Enter-to-save behavior matches the send composer.
- No attachment button. Media editing is out of scope for this branch.

### Selection bug fixes land in `MessageTextInput`

Since `MessageTextInput` is built fresh, apply the fixes from Phase 1 directly:

- No `setState` per keystroke. Use `ValueListenableBuilder` on the controller for any text-derived state (e.g., `_isMultiline`, save-button enabled).
- Hoist `IconButton`s and `InputDecoration` into stable references so the suffix doesn't churn.
- Stable widget keys so the `TextField` identity survives state changes.

### File-level changes

```
lib/
├── widgets/message/
│   ├── message_text_input.dart      # NEW — reusable text input chrome
│   ├── message_edit_bar.dart        # NEW — edit-mode bottom bar
│   ├── message_input_area.dart      # uses MessageTextInput; loses inline TextField
│   └── message_list.dart            # _editMessage(): becomes
│                                    #   ref.read(messageProvider.notifier).startEditing(message)
├── screens/
│   └── chat_screen.dart             # render MessageEditBar when editingMessage != null,
│                                    # else MessageInputArea
└── presentation/
    ├── state/message_state.dart     # + editingMessage, setEditing, clearEditing
    └── notifiers/message_notifier.dart
                                     # + startEditing, cancelEditing;
                                     # editMessage clears editingMessage on success
```

## Decisions

- **Reusable widget built from scratch.** New `MessageTextInput` is the canonical text-input chrome; both send and edit consume it.
- **Media editing out of scope.** Edit applies to text messages only. If the menu currently exposes Edit on captioned media, gate it to text-only as part of this branch.
- **Cancel via cross button.** Leading ✕ in the edit bar cancels and restores any pre-edit draft. No Esc keybinding for now.

## Open questions

- **Repro the selection bug on Android first.** The fix in Phase 1 is best-guess until repro confirms which suspect (#1/#2/#3) matches.

## Risks

- **Selection bug may be a Flutter framework bug on Android**, not in our code. Mitigation: time-box the investigation. If it's a framework issue, document it, apply the cleanest workaround (likely a `selectionControls` override or focus-on-unfocus dispatch), and move on.
- **Edit mode + reply mode collision.** If a user was replying and then taps Edit on another message, what happens? Decision: entering edit mode clears reply state; entering reply state clears edit state. Mutually exclusive, last action wins. Document in the notifier.
- **Lost draft text on edit cancel.** When the user has typed a draft, taps Edit, then cancels — current drafts are lost (the controller is overwritten with the message text). Mitigation: stash the pre-edit draft text in the notifier when entering edit mode and restore it on cancel. Small, worth doing.
- **Bottom bar swap may animate awkwardly.** Switching between `MessageInputArea` and `MessageEditBar` via state could flicker if the keyboard is open. Mitigation: use an `AnimatedSwitcher` with a short fade, or render both with one always at zero opacity. Decide during implementation based on what looks right.

## Test plan

- Manual: select text in composer → deselect → caret returns; selection handles dismiss. (Android, the failure platform.)
- Manual: tap Edit on an outgoing text message → composer shows banner with original text → modify → send → message updates, banner clears, input empty. Verify on a real chat.
- Manual: type a draft → tap Edit on a message → cancel → original draft restored.
- Manual: enter reply mode → tap Edit → reply banner replaced by edit banner (and vice versa).
- Manual: edit empty / edit unchanged → no-op, exits edit mode without server call.
- Run `flutter analyze` and any existing widget tests for `MessageInputArea`.
