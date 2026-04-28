# Reduce Logging Noise

The audience is the developer running the app and reading the console. The
goal: every log line that appears at default settings should be worth reading.

## What Users Can Do

1. **See a clean console during routine development**

   - **Scenario: Normal app usage**
     - **Given:** The developer runs the app in debug mode with default settings
     - **When:** They open chats, scroll history, send messages, switch accounts
     - **Then:** The console shows only meaningful events — auth state changes, errors, warnings, and explicit milestones — not a stream of routine network or update traffic

   - **Scenario: Long sync after restart**
     - **Given:** The app is catching up on hundreds of pending updates from the server
     - **When:** Updates arrive in bursts
     - **Then:** The console stays quiet at default verbosity (one summary line is acceptable; per-update lines are not)

2. **Turn on detail for one area without flooding the rest**

   - **Scenario: Investigating the message pipeline**
     - **Given:** The developer suspects a problem with chat updates
     - **When:** They raise verbosity for the messages subsystem
     - **Then:** The console shows every message-related event in detail, while other subsystems stay at their default level

   - **Scenario: Investigating the network bridge**
     - **Given:** The developer wants to see every request and response to the Telegram client library
     - **When:** They raise verbosity for the bridge subsystem
     - **Then:** Bridge requests and responses appear; messages, UI, and storage stay quiet

3. **Always see errors and warnings**

   - **Scenario: A failure happens in a muted subsystem**
     - **Given:** Verbosity for that subsystem is at its default (quiet) level
     - **When:** The subsystem reports an error or warning
     - **Then:** It still appears in the console and in the in-app error buffer

4. **Change verbosity without restarting**

   - **Scenario: Switching focus mid-session**
     - **Given:** The app is already running
     - **When:** The developer changes the active level for a subsystem
     - **Then:** Subsequent log calls obey the new setting immediately, with no rebuild and no restart

5. **Trust that every log line takes the same path**

   - **Scenario: A widget hits a recoverable failure**
     - **Given:** A UI widget catches an exception it can recover from
     - **When:** It reports the failure
     - **Then:** The report goes through the central logger and respects current verbosity, sanitization, and buffering — no direct console writes that bypass the system

## Requirements

### Verbosity model

- [ ] The system defines at least five named levels with clear roles: `trace`, `debug`, `info`, `warning`, `error`. Each call site picks the level that matches what it reports
- [ ] Each subsystem has its own independent level (at least: bridge, messages, chats, auth, UI, storage, performance)
- [ ] A muted subsystem emits nothing — no periodic summaries, no heartbeat lines
- [ ] At default debug-build verbosity, the console shows zero per-request, per-response, and per-update lines from the Telegram client bridge during routine use
- [ ] At default debug-build verbosity, the console shows zero lines for routine per-message state changes (photo updated, sticker updated, reaction added, etc.) — these calls remain in code at `trace`, off by default
- [ ] Errors and warnings always reach the console and the in-app error buffer, regardless of subsystem verbosity
- [ ] Authentication events stay visible at default verbosity (they are low-volume and high-signal)
- [ ] Release builds keep the existing "warning and above" default

### Runtime control

- [ ] Verbosity is configured through an environment variable read at app startup, in the style of Rust's `RUST_LOG`
- [ ] The variable accepts a default level plus per-subsystem overrides in one expression (for example: `info,bridge=trace,messages=debug`)
- [ ] An invalid or unrecognized variable value falls back to the build-mode default and surfaces a single warning
- [ ] No rebuild is required to change verbosity — restarting the app with a new value is enough

### Error buffer

- [ ] The in-app error buffer keeps capturing every warning and error
- [ ] Alongside warnings and errors, the buffer keeps a small ring buffer of the most recent `info`-level breadcrumbs (size around 20 lines) so an error has surrounding context when read back
- [ ] Breadcrumbs respect redaction the same way other log lines do

### Native bridge logs

- [ ] The Telegram client library's native (C++) logs default to silent (today's FATAL setting)
- [ ] The same env variable can raise the native level on demand using a dedicated subsystem name (for example `bridge.native=debug`)
- [ ] Native logs may continue to print on their own path with their own format — unifying them with the central logger is out of scope for this change

### Codebase hygiene

- [ ] Every log call in the codebase goes through the central logger — no stray direct-print calls remain
- [ ] Existing redaction of phone numbers, tokens, and other secrets keeps working at every level

### Out of scope

- Exporting the recent log buffer to a file from inside the app
- Unifying the format of native (C++) bridge logs with the Dart logger output
