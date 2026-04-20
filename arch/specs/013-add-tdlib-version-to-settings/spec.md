# TDLib Version on Settings Screen

## What Users Can Do

1. **Open settings from the chat list**

   - **Scenario: Open settings**
     - **Given:** User is signed in and viewing the chat list
     - **When:** User taps the settings entry in the left-pane menu (a new item alongside Error Log)
     - **Then:** A settings screen opens

2. **See which TDLib version the app is running**

   - **Scenario: Version loads successfully**
     - **Given:** User is on the settings screen
     - **When:** The screen has finished loading
     - **Then:** The TDLib version is shown as a labeled row (e.g. "TDLib version: 1.8.51")

   - **Scenario: Version cannot be read**
     - **Given:** The client has not reported a version yet, or the call fails
     - **When:** User is on the settings screen
     - **Then:** The row shows a neutral placeholder ("TDLib version: unknown") rather than crashing or hiding

3. **Copy the version string**

   - **Scenario: Copy version**
     - **Given:** A TDLib version is displayed
     - **When:** User long-presses (mobile) or taps a copy affordance (desktop) on the row
     - **Then:** The version string is copied to the clipboard and a brief confirmation is shown

4. **Log out from settings**

   - **Scenario: Logout moved to settings**
     - **Given:** User is on the settings screen
     - **When:** User taps "Log out" and confirms
     - **Then:** Session ends and user is returned to the auth screen
   - **Note:** Logout is removed from the chat header popup menu as part of this change.

5. **Leave the settings screen**

   - **Scenario: Return to chat list**
     - **Given:** User is on the settings screen
     - **When:** User taps back / close
     - **Then:** User returns to the chat list with no state lost

## Requirements

- [ ] A settings screen is reachable from a new item in the left-pane menu (alongside the existing Error Log entry)
- [ ] The settings screen displays the current TDLib version as text
- [ ] The version value comes from TDLib itself (not hard-coded)
- [ ] If the version is not yet available, the screen shows a clear placeholder and does not block other content
- [ ] The version string can be copied to the clipboard
- [ ] The screen works on both mobile and desktop layouts
- [ ] Opening the settings screen does not require any network round-trip beyond what's already running
- [ ] Logout action is available on the settings screen and removed from the chat header popup menu
- [ ] Initial scope is TDLib version only; other diagnostics (app version, user ID, data dir, log level) are deferred

## Open Questions

_None — resolved: scope is TDLib version only; entry point is a new item in the left-pane menu; logout moves from the chat header into settings._
