# Plan: In-App Error Log Viewer

## Tech Stack

- Language: Dart 3.10+
- Framework: Flutter + flutter_riverpod
- Storage: In-memory ring buffer (no persistence needed)
- Testing: Manual

## Structure

Where new code will live:

```
lib/
├── core/
│   └── logging/
│       └── error_log_buffer.dart        # In-memory ring buffer for error entries
├── presentation/
│   ├── providers/
│   │   └── app_providers.dart           # Add errorLogProvider
│   └── state/                           # (no new state file needed - buffer is the state)
├── screens/
│   └── error_log_screen.dart            # Full-screen error log viewer
└── widgets/
    └── home/
        └── left_pane.dart               # Wire menu button to open error log
```

## Approach

### 1. Create an in-memory error log buffer

Add `ErrorLogBuffer` to `lib/core/logging/error_log_buffer.dart`:

- A simple class that holds a fixed-size list of `ErrorLogEntry` records.
- Each entry stores: timestamp, level (warning/error/fatal), message string, module name, error object (as string), and stack trace (as string).
- Ring buffer with a max of ~200 entries. Oldest entries drop off when full.
- Singleton, like `AppLogger`.

### 2. Hook the buffer into AppLogger

In `AppLogger._log()`, when the level is `warning`, `error`, or `fatal`, also push the entry into `ErrorLogBuffer`.

This is a one-line addition to the existing `_log` method. No changes to the logging API or callers.

### 3. Create a Riverpod provider

Add a simple `ChangeNotifierProvider` (or `NotifierProvider`) in `app_providers.dart` that wraps `ErrorLogBuffer` and exposes the error list. The buffer notifies listeners when a new entry arrives.

### 4. Build the error log screen

`ErrorLogScreen` - a new screen at `lib/screens/error_log_screen.dart`:

- AppBar with title "Error Log" and a clear button.
- ListView of error entries, newest first.
- Each entry shows: timestamp, level badge (color-coded), module tag, message, and expandable error/stack trace details.
- Tap an entry to expand/collapse its full details.
- Empty state: "No errors logged" message.

### 5. Wire the menu button in LeftPane

The menu `IconButton` in `left_pane.dart` (line 43) currently has a TODO. Change it to navigate to `ErrorLogScreen`.

On mobile: `Navigator.push` to the error log screen.
On desktop: Same approach (push route), since error log is a secondary screen.

### 6. Add error count badge (optional, low effort)

Show a small red badge on the menu icon when there are unread errors. The badge count resets when the user opens the error log screen.

## Risks

- **Memory usage**: 200 entries with string messages is negligible. Not a concern.
- **Thread safety**: Flutter is single-threaded (main isolate), so the buffer doesn't need synchronization.
- **Log format coupling**: The buffer captures data before formatting, so it doesn't depend on `ConsoleFormatter`.

## Open Questions

- None. The approach is straightforward.
