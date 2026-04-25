# Home + Chat UX Upgrade with Appearance Settings

## What Users Can Do

1. **Open Appearance settings**

   - **Scenario: Find the controls**
     - **Given:** User is signed in and viewing Settings
     - **When:** User taps a new "Appearance" entry
     - **Then:** A dedicated Appearance screen opens, showing three sections — Accent color, Bubble style, Density — each with the current selection clearly marked

2. **Change the accent color**

   - **Scenario: Pick a different accent**
     - **Given:** User is on the Appearance screen
     - **When:** User taps a different swatch in the accent palette
     - **Then:** The new accent applies immediately across the home and chat screens — primary buttons, links, the send button, focus rings, unread badges, and reaction highlights — with no app restart

   - **Scenario: First-time default**
     - **Given:** A fresh install with no saved preference
     - **When:** User opens the app for the first time
     - **Then:** The accent matches the existing Telegram blue baseline so nothing looks unfamiliar

3. **Change the bubble style**

   - **Scenario: Pick a different style**
     - **Given:** User is on the Appearance screen
     - **When:** User selects one of the three bubble styles
     - **Then:** All chat bubbles render with the new shape immediately, including any chat that is currently open

4. **Change the density**

   - **Scenario: Switch to compact**
     - **Given:** User is on the Appearance screen
     - **When:** User selects "Compact"
     - **Then:** Home list rows tighten, avatars on the chat list shrink by one defined step, chat message spacing tightens, and font scale drops by one defined step — without reducing any interactive element below a 44×44 hit area

   - **Scenario: Switch to comfortable**
     - **Given:** User is on the Appearance screen
     - **When:** User selects "Comfortable"
     - **Then:** Spacing relaxes back to the airier default values

5. **Customization persists across restarts**

   - **Scenario: Choices survive a restart**
     - **Given:** User has set a custom accent, bubble style, and density
     - **When:** User quits the app and reopens it
     - **Then:** All three choices are restored exactly, with no flicker through the previous defaults during launch

6. **Browse the chat list**

   - **Scenario: Refined visual hierarchy**
     - **Given:** User opens the chat list
     - **When:** User scrolls
     - **Then:** Avatar size, name weight, last-message preview color, timestamp alignment, unread badge, and dividers all read against a single shared spacing, radius, and typography scale

   - **Scenario: Smooth list updates**
     - **Given:** User is viewing the chat list and a new message arrives in another chat
     - **When:** That chat's row updates
     - **Then:** The unread badge animates in, the row reorders smoothly if its position changed, and the user's current scroll position is preserved

7. **Open and read a chat**

   - **Scenario: Coherent open transition**
     - **Given:** User is on the chat list
     - **When:** User taps a chat row
     - **Then:** A coherent forward transition plays into the chat screen; tapping back plays the inverse

   - **Scenario: Refined message visuals**
     - **Given:** User is reading a chat
     - **When:** User scrolls through history
     - **Then:** Message bubbles, sender names, timestamps, read receipts, reactions, attachments, and the composer all use the same spacing, radius, and typography scales

8. **Send a message**

   - **Scenario: Send-message feedback**
     - **Given:** User has typed a message in the composer
     - **When:** User taps the send button
     - **Then:** A short haptic fires, the message animates into the chat with optimistic state, and the composer field clears smoothly

9. **Receive a message**

   - **Scenario: New message arrives in an open chat**
     - **Given:** User is viewing a chat with the latest message visible
     - **When:** A new inbound message arrives
     - **Then:** The new bubble animates in from the bottom

   - **Scenario: New message arrives while scrolled up**
     - **Given:** User has scrolled up in a chat
     - **When:** A new inbound message arrives
     - **Then:** A scroll-to-bottom indicator appears smoothly with an unread count; tapping it scrolls smoothly to the latest message

10. **React to a message**

    - **Scenario: Tap a reaction**
      - **Given:** User views a message with reactions
      - **When:** User taps an existing reaction
      - **Then:** A short scale or color animation acknowledges the tap and the count updates

11. **App respects reduced-motion preference**

    - **Scenario: System reduced-motion is on**
      - **Given:** The OS reports a reduced-motion preference
      - **When:** User navigates and uses the app
      - **Then:** Decorative motion (entrance bounces, scale-on-tap, badge wiggles) is removed or shortened; structural transitions remain at brief durations so navigation still feels responsive

## Requirements

### Customization knobs

- [ ] Settings has a new "Appearance" entry, positioned as the first item in the Settings screen
- [ ] The accent palette includes the existing Telegram blue as the default, plus at least 5 additional curated presets
- [ ] The accent palette is curated only; no custom hex input is offered in v1
- [ ] The bubble style options include exactly 3 visually distinct variants
- [ ] The density options are exactly Compact and Comfortable; Comfortable is the default
- [ ] On Compact, avatar size on the home list reduces by one defined step relative to Comfortable
- [ ] Selected values apply live across the home and chat screens without an app restart
- [ ] Selected values persist across app restarts and survive force-close
- [ ] On Compact, every interactive element on the home list and chat screen retains a minimum 44×44 hit area
- [ ] Every accent in the preset palette meets a minimum 4.5:1 contrast ratio against the dark surface for text and primary action elements
- [ ] If no preference is saved, the app boots into the existing baseline look (current blue, classic bubble, Comfortable)
- [ ] Users upgrading from a prior version migrate silently to the default values; no migration prompt or onboarding for the new options is shown

### Visual polish (home + chat)

- [ ] A single spacing scale is defined and used by both the home list and the chat screen
- [ ] A single radius scale is defined and used by both screens
- [ ] A single typography scale (sizes, weights, line heights) is defined and used by both screens
- [ ] One icon family with a single sizing system is used across home and chat
- [ ] Chat-list rows render avatar, name, last-message preview, timestamp, and unread badge with a defined visual hierarchy
- [ ] Message bubbles render content, sender (in groups), timestamp, and read state with a defined visual hierarchy
- [ ] The composer reads as a single deliberate control containing attachments, text input, emoji, and send/voice button

### Motion & feedback

- [ ] Micro-interactions (tap, toggle, selection change) complete in 150–300ms
- [ ] Sending a message triggers a short haptic and an animated insertion into the chat
- [ ] Receiving a message in an open chat animates the new bubble in
- [ ] The scroll-to-bottom button appears smoothly when the user scrolls up; tapping it scrolls smoothly to the latest message
- [ ] Opening a chat from the home list uses a coherent forward transition; tapping back plays the inverse
- [ ] All decorative motion is shortened or removed when the OS reports a reduced-motion preference

### Scope

- [ ] Initial scope is the home (chat list) and chat screens plus a new Appearance screen under Settings; the auth screen, error-log screen, and the Settings root layout are not visually changed in this feature
- [ ] Light mode, wallpaper customization, and per-chat customization are out of scope and deferred
- [ ] No comprehensive accessibility audit is included beyond the contrast, touch-target, and reduced-motion requirements above
- [ ] No new performance work is included beyond what is needed to keep the new motion smooth on mid-range devices

## Open Questions

_None — resolved: 3 bubble-style variants in v1; curated presets only with no custom hex picker; Density also reduces avatar size on the home list (alongside spacing and typography); Appearance is the first entry in Settings; pre-existing installs migrate silently to defaults with no prompt; no inline preview row is needed since changes apply live across the app._
