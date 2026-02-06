# Cleanup Plan: Bugs, Dead Code, and Simplifications

## Phase 1: Critical Bugs

### Bug 1: `getMessage()` always returns null
**File:** `lib/data/repositories/tdlib_telegram_client.dart:1190-1218`

**Description:** `getMessage()` calls `_sendRequest()` which sends the TDLib request but immediately returns `null` (line 900). It's a fire-and-forget method. So the `if (response == null)` check on line 1198 is always true, and the method always returns `null`. This breaks any feature that depends on fetching a single message (e.g. reply previews, edited message refresh).

**Fix:** Change `_sendRequest` to `_sendRequestAsync` on line 1192. `_sendRequestAsync` uses `@extra` correlation to wait for the actual TDLib response.

---

### Bug 2: `_handleMessageEditedUpdate()` silently does nothing
**File:** `lib/data/repositories/tdlib_telegram_client.dart:1879-1895`

**Description:** The handler reads `update['message']` expecting a full message object. But TDLib's `updateMessageEdited` event only contains `chat_id`, `message_id`, `edit_date`, and `reply_markup` — no `message` field. So `messageData` is always null, the method returns early on line 1882, and edited messages never update in the UI.

**Fix:** Extract `chat_id` and `message_id` from the update, then fetch the full updated message via `_sendRequestAsync({'@type': 'getMessage', ...})`. Then update the cache and emit `MessageEditedEvent` with the fetched message.

---

### Bug 3: `_loadUserSession()` discards the loaded session
**File:** `lib/data/repositories/tdlib_authentication.dart:328-336`

**Description:** The method reads `sessionData` from storage (line 330), checks it's non-null (line 331), logs (line 332), but never actually deserializes or assigns it to `_currentUser`. The session data is thrown away — sessions never restore after app restart.

**Fix:** After the null check, add `_currentUser = UserSession.fromJson(jsonDecode(sessionData));`.

---

### Bug 4: `UnifiedAuthState.clearError()` is a no-op
**File:** `lib/presentation/state/unified_auth_state.dart:49-72`

**Description:** `copyWith` uses `errorMessage: errorMessage ?? this.errorMessage` (line 63). Passing `null` for `errorMessage` (the default) always falls back to `this.errorMessage`, so the error is preserved. `clearError()` on line 70-72 calls `copyWith(errorMessage: null)` which has no effect — once an error is set, it can never be cleared.

**Fix:** Add a `bool clearErrorMessage = false` parameter to `copyWith`. Use: `errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage)`. Update `clearError()` to `copyWith(clearErrorMessage: true)`.

---

### Bug 5: `MessageState.copyWith()` silently clears `errorMessage`
**File:** `lib/presentation/state/message_state.dart:69`

**Description:** Opposite problem from Bug 4. Line 69 passes `errorMessage` directly without `??` fallback: `errorMessage: errorMessage,`. Any `copyWith()` call that doesn't pass `errorMessage` explicitly will reset it to `null`. For example, `setLoading(true)` on line 98 calls `copyWith(isLoading: loading)`, which silently clears any existing error as a side effect.

**Fix:** Same pattern as Bug 4 fix: use `errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage)` with a `bool clearErrorMessage = false` parameter. Update `clearError()` to use the flag.

---

### Bug 6: `ChatState.copyWith()` silently clears `errorMessage` (same issue)
**File:** `lib/presentation/state/chat_state.dart:39`

**Description:** Same problem as Bug 5. Line 39: `errorMessage: errorMessage,` — every `copyWith` call without explicit `errorMessage` clears it. `setLoading()`, `bumpVersion()`, `sortByLastActivity()`, `addChat()`, `updateChat()`, `removeChat()` all silently drop errors.

**Fix:** Same pattern: add `bool clearErrorMessage = false` parameter, use `errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage)`.

---

### Bug 7: `ChatState.operator==` only compares `chats.length`, not content
**File:** `lib/presentation/state/chat_state.dart:96-105`

**Description:** Line 100: `other.chats.length == chats.length`. Two states with the same number of chats but completely different data (different titles, photos, last messages) are considered equal. Riverpod uses `==` to decide whether to notify listeners, so UI rebuilds will be skipped when chat data changes without changing chat count.

**Fix:** Replace `other.chats.length == chats.length` with `identical(other.chats, chats)`. Since `copyWith` always creates new lists, reference inequality reliably means content changed. Also update `hashCode` to use `identityHashCode(chats)` instead of `chats.length`.

---

### Bug 8: `AuthNotifier` and `MessageNotifier` leak stream subscriptions
**File:** `lib/presentation/notifiers/auth_notifier.dart:18-31, 126-129`
**File:** `lib/presentation/notifiers/message_notifier.dart:19-39`

**Description:** Both notifiers have `dispose()` methods with cleanup logic, but neither registers cleanup via `ref.onDispose()`. Compare with `ChatNotifier` which correctly does `ref.onDispose(...)`. The `dispose()` methods are never called by anyone. Stream subscriptions (`_authSubscription`, `_eventSubscription`) are never cancelled.

**Fix:**
- In `AuthNotifier.build()`, add `ref.onDispose(() { _authSubscription?.cancel(); _authRepository?.dispose(); });` and remove the standalone `dispose()` method.
- In `MessageNotifier.build()`, add `ref.onDispose(() { _eventSubscription?.cancel(); });` and remove the standalone `dispose()` method.

---

### Bug 9: Nested `MaterialApp` widgets in `main.dart`
**File:** `lib/main.dart:120, 171`

**Description:** `_buildLoadingScreen()` (line 171) and the error handler (line 120) both return a `MaterialApp(...)`. But they're already rendered as children of the parent `MaterialApp` in `TelegramFlutterApp.build()` (line 48). Nested `MaterialApp`s create duplicate navigators, theme contexts, and media query scopes. This wastes resources and the outer app's theme is ignored.

**Fix:** Replace `MaterialApp(home: Builder(builder: (context) { ... Scaffold(...) }))` with just `Scaffold(...)` in both `_buildLoadingScreen()` and the error handler. The parent `MaterialApp` already provides the theme.

---

### Bug 10: Loading phrase flickers on every rebuild
**File:** `lib/main.dart:170`

**Description:** `_buildLoadingScreen()` creates `Random().nextInt(...)` every time it's called. Since it's called from `build()`, each provider state change triggers a new random phrase, causing the loading text to flicker.

**Fix:** Compute the phrase once in `initState` as a `late final` field on `_AppWrapperState`. Or store it as a field initialized in `initState`.

---

### Bug 11: `setState` on disposed widget in scroll animation callback
**File:** `lib/widgets/message/message_list.dart:118-124`

**Description:** In `_scrollToBottom`, the `.then()` callback after `animateTo()` calls `setState` (line 121) without checking `mounted`. If the widget is disposed during the animation (e.g. user navigates away), this crashes with "setState() called after dispose()".

**Fix:** Add `if (!mounted) return;` at the start of the `.then()` callback.

---

### Bug 12: Context used after `Navigator.pop` in reaction picker
**File:** `lib/widgets/message/message_list.dart:391-396`

**Description:** Inside the bottom sheet builder, `Navigator.pop(context)` is called (line 392), then `ExpandedReactionPicker.show(context)` uses the same `context` (line 393). But `context` here is the bottom sheet's `BuildContext`, which is deactivated after the pop. This causes a "Looking up a deactivated widget's ancestor" error.

**Fix:** Capture the outer `_MessageListState`'s context before the `showModalBottomSheet` call and use that for `ExpandedReactionPicker.show()` instead.

---

### Bug 13: `FocusNode` memory leak in fullscreen viewers
**File:** `lib/widgets/message/photo_message.dart:137`
**File:** `lib/widgets/message/video_message.dart:234`

**Description:** Both create `FocusNode()..requestFocus()` inline in `build()`. A new FocusNode is created on every rebuild, and none are disposed. FocusNode attaches to the focus tree and leaks memory.

**Fix:** Store the FocusNode as a field, create in `initState`, dispose in `dispose()`.

---

### Bug 14: `UnifiedAuthState.hashCode` uses XOR instead of `Object.hash`
**File:** `lib/presentation/state/unified_auth_state.dart:105-113`

**Description:** Uses `^` (XOR) to combine hash values. XOR is a poor hash combiner — it's symmetric (`a ^ b == b ^ a`) and self-cancelling (`a ^ a == 0`), causing high collision rates. Every other state class in the codebase uses `Object.hash()`.

**Fix:** Replace with `Object.hash(status, user, codeInfo, qrCodeInfo, errorMessage, isLoading, isInitialized)`.

---

## Phase 2: Dead Code Removal

### Step 1: Delete entire dead files
Remove these files that are never imported anywhere:
- `lib/core/emoji/emoji_animation_controller.dart` (150 lines)
- `lib/core/logging/formatters/file_formatter.dart` (59 lines)
- `lib/core/logging/outputs/rotating_file_output.dart` (139 lines)
- `lib/core/logging/logging.dart` (barrel file, 16 lines)
- `lib/presentation/notifiers/emoji_animation_notifier.dart` (96 lines)
- `lib/widgets/message/reaction_display.dart` (206 lines)
- `lib/widgets/emoji_sticker/basic_emoji_picker.dart` (339 lines)
- `lib/utils/date_utils.dart` (5 lines)

### Step 2: Remove dead classes/widgets from used files
- `PositionedReactionPicker` from `lib/widgets/message/reaction_picker.dart`
- `SliverEmojiGrid` and `CategoryEmojiGrid` from `lib/widgets/emoji_sticker/emoji_grid.dart`
- `SimpleEmojiText` from `lib/widgets/message/emoji_text.dart`
- `NetworkLogger` and `PerformanceLogger` from `lib/core/logging/specialized_loggers.dart`

### Step 3: Remove dead methods/functions from used files
- `_pickFromCamera`, `_pickDocument` and unused `image_picker`/`file_picker` imports from `lib/widgets/message/message_input_area.dart`
- `simpleEmojiRegex`, `countEmojis()`, `getOnlyEmojiCount()`, `isOnlyEmojis()` from `lib/core/emoji/emoji_utils.dart`
- `setTelegramClient()`, `setAnimatedEmojiLoader()`, `GetAnimatedEmojiFunc` typedef from `lib/core/emoji/emoji_asset_manager.dart`
- `commonEmojiCodepoints` from `lib/core/emoji/emoji_data.dart`
- `Chat.toJson()`, `Message.toJson()` from `lib/domain/entities/chat.dart`
- `LogModuleExtension.emoji` getter, `LogContext.copyWith()` from `lib/core/logging/log_level.dart`
- `LogModule.storage`, `LogModule.ui` enum values from `lib/core/logging/log_level.dart` (only if no risk of breaking enum serialization)

### Step 4: Remove dead providers/notifiers/factories
- `isAuthenticatedProvider` from `lib/presentation/providers/app_providers.dart`
- `emojiNotifierProvider`, `EmojiNotifier`, `recordEmojiUsageProvider`, `codepointToEmojiChar()` from `lib/presentation/providers/emoji_providers.dart`
- `ChatState.error()` factory from `lib/presentation/state/chat_state.dart`
- `ChatState.removeChat()` from `lib/presentation/state/chat_state.dart`
- `UnifiedAuthState.error()` factory from `lib/presentation/state/unified_auth_state.dart`
- `MessageState.error()`, `MessageState.loaded()`, `MessageState.clearChatMessages()` from `lib/presentation/state/message_state.dart`

---

## Phase 3: Simplifications

### Simplify 1: `LeftPane` — `ConsumerStatefulWidget` that doesn't use `ref`
**File:** `lib/widgets/home/left_pane.dart`
Change to `StatelessWidget` since it has no state and doesn't use `ref`.

### Simplify 2: `ChatListItem` — unnecessary `SingleTickerProviderStateMixin`
**File:** `lib/widgets/chat/chat_list_item.dart:23`
Remove `with SingleTickerProviderStateMixin` — no animation controller exists.

### Simplify 3: `ChatList` — redundant `Consumer` wrapper
**File:** `lib/widgets/chat/chat_list.dart:44-58`
Already a `ConsumerStatefulWidget` so `ref` is available directly. Remove the inner `Consumer` widget and use `ref` from the state.

### Simplify 4: `AuthScreen` — use `SingleTickerProviderStateMixin`
**File:** `lib/screens/auth_screen.dart:19`
Only one `TabController` exists, so `SingleTickerProviderStateMixin` suffices instead of the multi-ticker `TickerProviderStateMixin`.

### Simplify 5: Deduplicate `_getChatStatusText` and `_showLogoutDialog`
**Files:** `lib/screens/home_screen.dart`, `lib/screens/chat_screen.dart`
These methods are identical in both files. Extract to a shared utility or mixin.

### Simplify 6: Remove unreachable code in `ChatListItem._getInitials`
**File:** `lib/widgets/chat/chat_list_item.dart:152`
The final `return title[0].toUpperCase()` is unreachable — the `words.length` branches above cover all cases when title is non-empty.

### Simplify 7: Inline `_resortChats()` wrapper
**File:** `lib/presentation/notifiers/chat_notifier.dart:126`
One-line wrapper around `_scheduleSortIfNeeded()`. Inline it at the call site.

### Simplify 8: Extract sticker-loading guard in `EmojiStickerNotifier`
**File:** `lib/presentation/notifiers/emoji_sticker_notifier.dart:35-68`
The check `state.installedStickerSets.isEmpty && !state.isLoadingStickerSets` + `loadInstalledStickerSets()` is repeated 3 times. Extract to `_ensureStickerSetsLoaded()`.

### Simplify 9: Replace `debugPrint` with `AppLogger` in `EmojiStickerNotifier`
**File:** `lib/presentation/notifiers/emoji_sticker_notifier.dart:79-107`
7 `debugPrint` calls that should use `AppLogger` like the rest of the codebase. Remove the `import 'package:flutter/foundation.dart'` if no longer needed.

### Simplify 10: Extract `_currentState` getter in `MessageNotifier`
**File:** `lib/presentation/notifiers/message_notifier.dart`
The pattern `state.value ?? MessageState.initial()` is repeated 9+ times. Extract to a getter: `MessageState get _currentState => state.value ?? MessageState.initial();`.
