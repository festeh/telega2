# Plan: Home + Chat UX Upgrade with Appearance Settings

**Spec**: arch/specs/015-supercharge-ux-with-ui-pro-max/spec.md

## Tech Stack

- Language: Dart 3.11+
- Framework: Flutter (Material 3), flutter_riverpod ^3.0.3 for state
- Storage: shared_preferences ^2.2.0 (already a dependency)
- Tokens: `ThemeExtension<TelegaTokens>` plus the existing `lib/core/constants/ui_constants.dart` (extended to expose density-aware values)
- Motion: Flutter built-ins — `HapticFeedback`, `AnimatedList` or `TweenAnimationBuilder` for per-item entrance, `AnimatedSwitcher` for chrome, `MediaQuery.disableAnimations` for reduced-motion respect
- Reference: `.claude/skills/ui-ux-pro-max/scripts/search.py` to seed `design-system/MASTER.md` as the polish-pass anchor

## Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_theme.dart                # MODIFIED: AppTheme.dark becomes a function of AppearanceSettings
│       ├── appearance.dart               # NEW: AppearanceSettings value class + enums (AccentPreset, BubbleStyle, Density)
│       ├── appearance_notifier.dart      # NEW: Riverpod AsyncNotifier, persists to shared_preferences
│       └── telega_tokens.dart            # NEW: ThemeExtension carrying density-resolved spacing/radius/avatar/bubble tokens
├── screens/
│   ├── appearance_screen.dart            # NEW: Appearance settings screen (Accent / Bubble / Density)
│   ├── settings_screen.dart              # MODIFIED: Appearance entry first
│   ├── home_screen.dart                  # MODIFIED: header reads tokens; open-chat route uses a coherent forward transition
│   └── chat_screen.dart                  # MODIFIED: tokens for spacing
├── widgets/
│   ├── home/left_pane.dart               # MODIFIED: density-aware list rhythm
│   ├── chat/
│   │   ├── chat_list.dart                # MODIFIED: density-aware row spacing + smooth row update animation
│   │   └── chat_list_item.dart           # MODIFIED: density-aware avatar size, padding, typography hierarchy
│   └── message/
│       ├── message_bubble.dart           # MODIFIED: bubble shape from BubbleStyle; tokens for margins/radius/colors
│       ├── message_list.dart             # MODIFIED: per-item entrance animation; scroll-to-bottom indicator
│       ├── message_input_area.dart       # MODIFIED: haptic on send; refined composer visuals
│       └── reaction_bar.dart             # MODIFIED: short scale/color animation on tap
└── main.dart                             # MODIFIED: MaterialApp watches appearance provider; theme rebuilds on knob change

design-system/
└── MASTER.md                             # NEW (artifact): seeded via ui-ux-pro-max; reference for the polish pass
```

## Approach

Implementation proceeds in four phases. Each phase ends shippable.

### Phase 1 — Appearance state and theme pipeline

1. **Settings screen has an Appearance entry, first item**
   In `lib/screens/settings_screen.dart`, prepend a `ListTile` titled "Appearance" with an icon (e.g., `Icons.palette_outlined`), pushing `AppearanceScreen()`. Move the existing "About" header to second.

2. **AppearanceSettings value class**
   In `lib/core/theme/appearance.dart`, define:
   - `enum AccentPreset { telegramBlue, indigo, teal, magenta, amber, crimson, emerald }` (telegramBlue = `#3390EC`, default; six additional presets satisfy "≥5 additional curated presets")
   - `enum BubbleStyle { classicTail, flatRounded, minimalLine }` (3 distinct variants)
   - `enum Density { comfortable, compact }` (Comfortable default)
   - `class AppearanceSettings { AccentPreset accent; BubbleStyle bubble; Density density; }` with `copyWith`, `==`, `toJson`/`fromJson`, and a `defaults` static.

3. **Selected values persist across restarts and survive force-close**
   In `lib/core/theme/appearance_notifier.dart`, expose an `AsyncNotifierProvider<AppearanceNotifier, AppearanceSettings>`. On `build`, read three string keys from `SharedPreferences`; if any missing, fall back to `AppearanceSettings.defaults`. Mutator methods (`setAccent`, `setBubble`, `setDensity`) write through to prefs synchronously after state update.

4. **Theme rebuilds on knob change**
   Modify `lib/core/theme/app_theme.dart`: replace the static `static ThemeData get dark` with `static ThemeData dark(AppearanceSettings s)`. Compute the `ColorScheme.dark` exactly as today but override `primary` with the accent's `Color`, derive `primaryContainer` by darkening the accent in HSL space (~lightness × 0.45), derive `inversePrimary` by lightening (~lightness × 1.6, clamped). Attach `TelegaTokens.from(s)` as a `ThemeExtension`.
   In `lib/main.dart`, make `TelegramFlutterApp` watch `appearanceProvider` and pass `AppTheme.dark(settings)` to both `theme` and `darkTheme`. The full tree rebuilds; descendants reading `Theme.of(context).extension<TelegaTokens>()` get fresh tokens.

5. **If no preference is saved, app boots into baseline**
   `AppearanceSettings.defaults = AppearanceSettings(accent: AccentPreset.telegramBlue, bubble: BubbleStyle.classicTail, density: Density.comfortable)` — matches today's look. Migration is implicit: existing users have no saved keys, so they hit defaults silently. No prompt.

### Phase 2 — Per-knob token plumbing

6. **TelegaTokens ThemeExtension**
   In `lib/core/theme/telega_tokens.dart`, define a `@immutable class TelegaTokens extends ThemeExtension<TelegaTokens>` carrying:
   - Density-resolved spacing: `gapXs/sm/md/lg/xl`, `listRowVerticalPadding`, `bubbleVerticalPadding`, `bubbleHorizontalPadding`, `composerVerticalPadding`
   - Density-resolved sizes: `chatListAvatarSize` (Comfortable 50, Compact 40), `bodyFontScale` (1.0 / 0.94)
   - Radius scale per `BubbleStyle`: classicTail `(18, 18, 4, 18)` for outgoing tail / `(18, 18, 18, 4)` for incoming; flatRounded `12` all corners; minimalLine `0` (border-only)
   - `bubbleStyle: BubbleStyle` (so widgets that paint differently per style — minimalLine paints a 1px outline, others fill — can branch)
   - Touch-target floor: `minTouchTarget = 44.0`, applied as a `clampMin` helper on density-driven sizes.

7. **Bubble style applies live**
   In `lib/widgets/message/message_bubble.dart`, replace the hardcoded `margin: EdgeInsets.only(left: 50, right: 10, …)` with values pulled from tokens. Read `tokens.bubbleStyle` to choose the `ShapeBorder`: classicTail uses `RoundedRectangleBorder` with asymmetric radii; flatRounded uses uniform 12; minimalLine paints a `BorderSide` outline with no fill (and adapts text color to `onSurface`). Bubbles already rebuild on `Theme` change via the `Theme.of` lookup, so a knob change in the open chat re-renders without further wiring.

8. **Density also reduces avatar size on the chat list**
   In `lib/widgets/chat/chat_list_item.dart`, replace `AvatarSize.sm` (currently 40 hardcoded) with `tokens.chatListAvatarSize`. Also pull row vertical padding, gap-to-name, and the typography from tokens (`bodyFontScale` multiplies the existing font sizes).

9. **44×44 floor under Compact**
   Token resolution applies `clampMin(44)` to every interactive element's effective hit area: chevrons/IconButtons in the chat list row, send button, attachment button, reaction chips. Visual size may shrink — hit area must not. Use `Listener` + `MaterialTapTargetSize.padded` for icon buttons; pad with transparent area.

10. **Accent contrast ≥ 4.5:1**
    Constrain the seven preset accents at definition time so each meets 4.5:1 on `surface = #1C1C1E` for text and primary action elements. Add a unit test in `tests/` (or `test/`, following existing convention) that asserts contrast for each preset using a small `wcagContrast(Color a, Color b)` helper.

### Phase 3 — Appearance screen UI

11. **Three sections, current selection marked, no preview row**
    In `lib/screens/appearance_screen.dart`, build a `ListView` with three sections:
    - **Accent color**: a `Wrap` of round swatches (one per `AccentPreset`); the current pick has a thin ring of `colorScheme.onSurface`.
    - **Bubble style**: three rows, each a name + a tiny static bubble silhouette (one outbound chip the size of an icon — this is *not* a live preview, just an iconic representation, satisfying the "no preview row" decision). Selected row shows a check.
    - **Density**: two `RadioListTile`s (Comfortable / Compact).
    Tap on any option calls the matching mutator on the appearance notifier; theme re-derives and the underlying screens (visible only after navigating back) update. While the user remains on this screen, only the local "current selection" indicators move.

### Phase 4 — Visual polish + motion

12. **Seed the design-system reference**
    Run `python3 .claude/skills/ui-ux-pro-max/scripts/search.py "messaging chat dark elegant" --design-system --persist -p "telega2" --stack flutter` once at phase start. The output `design-system/MASTER.md` is the reference for spacing/typography/radius decisions in the polish pass — not a generated theme. Skip silently if Python is unavailable; current `ui_constants.dart` becomes the de facto reference instead.

13. **One spacing / radius / typography scale across home and chat**
    Audit pass on `chat_list_item.dart`, `left_pane.dart`, `message_bubble.dart`, `message_list.dart`, `message_input_area.dart`, `home_screen.dart#_buildChatHeader`. Replace hardcoded `EdgeInsets`, `SizedBox(width: …)`, and `BorderRadius.circular(…)` with values from `Spacing.*`, `Radii.*`, and `tokens.*` (density-aware where appropriate). Replace ad-hoc `TextStyle(fontSize: 16, …)` with theme text styles.

14. **Defined visual hierarchy on chat-list rows and message bubbles**
    Chat row: avatar — name (titleMedium) — preview (bodyMedium muted) — timestamp (labelSmall) right-aligned, unread badge (labelSmall on primary) right-aligned below timestamp. Message bubble: sender name (groups only, labelMedium primary), content (bodyLarge), inline timestamp + read receipt at bottom-right (labelSmall onSurface 0.5α).

15. **Single icon family, single sizing system**
    Audit and standardize on Material `Icons.*_outlined` (already dominant in the codebase) at `IconSize.sm` (20) for inline / `IconSize.md` (28) for primary actions. Replace any stray non-outlined icons.

16. **Composer reads as one deliberate control**
    In `lib/widgets/message/message_input_area.dart`, group attachment + text input + emoji + send/voice into a single rounded surface (`tokens.composerSurface`) with internal vertical padding from tokens.

17. **Micro-interactions in 150–300ms**
    Set `kAppearanceTransitionDuration = Duration(milliseconds: 200)` as the default for any new `AnimatedContainer`/`AnimatedSwitcher`/`AnimatedSize`. Existing 150ms `AnimatedContainer` in `chat_list_item.dart` already complies. Audit pass for outliers.

18. **Haptic + animated insertion on send**
    In `MessageInputArea`'s `onSend`, call `HapticFeedback.lightImpact()` before invoking the message-send notifier. The message appears optimistically via the existing notifier; wrap each list item in `message_list.dart` with a `TweenAnimationBuilder<double>` keyed by `message.id` that animates `opacity 0→1` and `translateY 8→0` on first build (200ms ease-out). This avoids the larger `AnimatedList` migration.

19. **Animated-in receive in open chat**
    Same per-item `TweenAnimationBuilder` covers the receive case — any newly inserted item entrance-animates regardless of source.

20. **Reaction tap acknowledgement**
    In `lib/widgets/message/reaction_bar.dart`, wrap each reaction chip in an `AnimatedScale` driven by a transient `_pressedKey` field. On tap, set `_pressedKey = reaction.id`, schedule a 200ms reset to `1.0`. Pair with an `AnimatedContainer` color tween from `surfaceContainerHigh` → `primary.withValues(alpha: 0.18)` and back. Both bounded by `motionDurationFor(...)` so reduced-motion strips them.

21. **Scroll-to-bottom indicator while scrolled up**
    Add a stateful `_scrolledUp` flag to `MessageList`, derived from `ScrollController.position.pixels > threshold`. When true, render a floating `FloatingActionButton.small` (positioned bottom-right of the scroll area) inside an `AnimatedSwitcher` with the standard 200ms duration. Tapping animates `controller.animateTo(0, duration: 250ms, curve: easeOutCubic)`.

22. **Coherent open-chat transition**
    In `home_screen.dart#_buildMobileLayout`, replace the bare `MaterialPageRoute` with a `PageRouteBuilder` using a slide-up + fade transition (250ms). Back uses the inverse (Flutter handles automatically via the same builder). Desktop layout already swaps panes — leave as-is.

23. **List update smoothness on home**
    In `chat_list.dart`, wrap each row in an `AnimatedSize` keyed by the chat ID so reorders/badge changes don't snap. Verify scroll position is preserved (Flutter's `ListView` handles this when keys are stable).

24. **Reduced motion respect**
    Add a small helper `motionDurationFor(BuildContext c, Duration normal) => MediaQuery.maybeDisableAnimationsOf(c) == true ? Duration.zero : normal`. Use it in steps 17–23's animation declarations. `Duration.zero` skips decorative animation; structural transitions are bounded by 250ms anyway, which is acceptable when reduced-motion is on (per the spec's "remain at brief durations" wording).

## Risks

- **`ColorScheme.fromSeed` mutes brand accents in dark mode** — Mitigation: skip `fromSeed`. Override only `primary` directly with the accent and compute `primaryContainer` / `inversePrimary` via simple HSL math from the same accent. Keep the rest of the existing hand-tuned dark scheme.
- **Switching `ListView` → `AnimatedList` would regress pagination/scroll restoration** — Mitigation: use per-item `TweenAnimationBuilder` keyed by `message.id` (step 18) instead of an `AnimatedList` rewrite. Existing list mechanics stay intact.
- **Touch-target shrinkage on Compact** — Mitigation: density tokens shrink *visual* sizes but every interactive element wraps a 44×44 hit area via `MaterialTapTargetSize.padded` or transparent padding. Asserted by widget tests.
- **Hardcoded values scattered across 90+ Dart files** — Mitigation: bound the density-aware sweep to chat-list item, message bubble, message list, composer, home header. Other surfaces remain on the static `ui_constants.dart` values (which is fine — Density only affects home + chat per spec).
- **Theme rebuild on knob change visibly stutters during chat scroll** — Mitigation: rebuild cost is one `MaterialApp` rebuild and `Theme` propagation; descendants are cheap. If profiling shows jank, lift the `tokens` to a separate `Provider.autoDispose` consumed at the leaves so message-bubble subtree rebuilds without the whole `MaterialApp`.
- **Haptic is no-op on Linux desktop** — Acceptable. Flutter handles this silently. No mitigation.
- **`ui-ux-pro-max` script unavailable (no Python)** — Mitigation: step 12 is advisory. If Python is missing, fall back to `ui_constants.dart` as the polish-pass reference. The spec's testable requirements don't depend on the script's output.
- **Bubble shape change while chat is mid-render** — Mitigation: `Theme` is an `InheritedWidget`; descendants rebuild deterministically. Any in-flight `TweenAnimationBuilder` finishes its current cycle, then new shape applies. No data corruption possible.
- **Accent palette growth tax** — Adding presets later means re-asserting contrast. Mitigation: contrast unit test (step 10) catches any future palette additions that fail the bar.

## Open Questions

_None — resolved:_

- **Token migration**: Full migration within scope. Every density-dependent layout value in the home + chat surfaces (chat-list row, message bubble, message list, composer, home header, Appearance screen) reads from `TelegaTokens`. Hardcoded `EdgeInsets`/`SizedBox`/`BorderRadius` literals in those files are removed. Density-invariant values (`IconSize.*`, `Radii.full`, gesture thresholds) stay in `ui_constants.dart`. No half-migrated call sites in touched files.
- **Accent derivation**: HSL math. `primaryContainer` derives from each accent via lightness × 0.45; `inversePrimary` via lightness × 1.6 clamped. Single contrast unit test (step 10) is the gate for any future palette additions.
- **Entrance animation**: Per-item `TweenAnimationBuilder` keyed by `message.id`. No `AnimatedList` migration.
- **Bubble option visual**: A small static silhouette chip per style on the Appearance screen — iconic, not interactive (compatible with "no preview row").
- **Test layout**: `test/core/theme/appearance_persistence_test.dart` (prefs round-trip), `test/core/theme/contrast_test.dart` (every accent ≥ 4.5:1 on dark surface), `test/core/theme/telega_tokens_test.dart` (Comfortable vs Compact resolution; 44×44 floor), `test/widgets/message/message_bubble_shape_test.dart` (correct `ShapeBorder` per `BubbleStyle`).
