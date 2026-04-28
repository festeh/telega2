# Plan: Reduce Logging Noise

**Spec**: arch/specs/019-improve-logging-reduce-noise/spec.md

## Tech Stack

- Language: Dart 3.10+ / Flutter
- Logging library: existing `package:logger` v2 (kept — no library swap)
- Env var source: `Platform.environment` from `dart:io`, read once at app startup
- Storage: none (filter settings live in memory for the lifetime of the process)
- Testing: existing `flutter_test`

## Structure

```
lib/core/logging/
├── app_logger.dart            # MODIFY — gate per-module inside _log
├── error_log_buffer.dart      # MODIFY — add info breadcrumb ring buffer
├── log_filter_config.dart     # NEW — env parser + per-module level map
├── log_level.dart             # KEEP
├── log_module.dart            # MODIFY — add `messages`, `chats` if missing
├── logging_config.dart        # MODIFY — read env, build filter, drive init
└── specialized_loggers.dart   # MODIFY — demote bridge per-call logs to trace

lib/main.dart                  # MODIFY — call env-aware init, raise native level if asked

lib/presentation/notifiers/
├── message_notifier.dart      # MODIFY — demote granular update logs to trace
└── chat_notifier.dart         # MODIFY — same review where applicable

lib/widgets/.../
├── animation_message.dart     # MODIFY — replace debugPrint with logger.warning
├── sticker_message.dart       # MODIFY — same
└── sticker_grid_item.dart     # MODIFY — same

test/core/logging/
└── log_filter_config_test.dart # NEW — env parsing, fallback, invalid input
```

## Approach

How each spec requirement maps to code:

1. **Five named levels with clear roles**
   `package:logger` already defines `trace, debug, info, warning, error, fatal`. Document the role of each in `log_level.dart` (a comment block). No new level type needed.

2. **Each subsystem has its own independent level**
   Confirm `LogModule` enum lists every subsystem named in the spec. Add `messages` and `chats` if absent. Existing `tdlib` covers the bridge.

3. **Per-subsystem level filter**
   New `LogFilterConfig` holds `Level defaultLevel` and `Map<LogModule, Level> overrides`. In `AppLogger._log`, before emitting:
   - If `level >= warning`: always emit (errors/warnings bypass the filter — satisfies "errors and warnings always reach")
   - Else: look up the module's effective level (override falls back to default) and emit only if `level >= effective`
   The underlying `Logger` runs at `Level.trace` so it never re-filters.

4. **Muted means silent**
   No aggregator, no heartbeat, no summary lines anywhere. Skip the temptation.

5. **Bridge per-request/response/update at trace**
   Change `TdlibLogger.logRequest`, `logResponse`, `logUpdate` from `debug`/`info` to `Level.trace`. Signatures stay the same. `logConnectionState` and `logAuthState` stay at `info` — those are rare, worth seeing.

6. **Per-message updates at trace**
   In `message_notifier.dart`, switch routine `_logger.debug(...)` calls (photo updated, sticker updated, video updated, animation updated, document updated, reactions updated, etc.) to `_logger.trace(...)`. Keep "loaded N messages" milestones at `debug`.

7. **Auth visible at default**
   Global default is `info` in debug builds. Auth's existing `info`-level events show automatically — no per-subsystem override needed.

8. **Release default**
   `LogFilterConfig.buildDefault()` returns `warning` when `kReleaseMode`, `info` otherwise. Matches today's behavior.

9. **Env variable parsing (`TELEGA_LOG`)**
   Format: `info,bridge=trace,messages=debug`. Algorithm:
   - Split on `,`, trim each token
   - If a token has no `=`, it sets the default level
   - If a token is `module=level`, it sets a per-module override
   - Unknown level names → log one warning, ignore the token, keep build defaults
   - Unknown module names → log one warning, ignore the token
   Read once via `Platform.environment['TELEGA_LOG']`.

10. **Invalid value → fallback + one warning**
    Build a `LogFilterConfig` with the build-mode defaults whenever parsing fails. The warning goes through the logger itself after init.

11. **No rebuild required**
    `Platform.environment` is read fresh on every process launch. A hot restart picks up new values. (Hot reload does not — call this out in the README/code comment.)

12. **Info breadcrumb ring buffer**
    Extend `ErrorLogBuffer`:
    - Existing collection keeps warning/error/fatal entries (unchanged)
    - New `Queue<ErrorLogEntry>` capped at 20 holds the most recent `info` entries
    - When a warning+ entry arrives, the breadcrumbs travel alongside it when the buffer is read
    Filter still applies — entries land in the buffer only after passing the per-module gate, so a muted subsystem produces no breadcrumbs.

13. **Native (TDLib C++) bridge level on demand**
    In `main.dart`, after env parsing:
    - If the env var contains a `bridge.native=<level>` token, send the TDLib `setLogVerbosityLevel` request mapping the chosen level to a native verbosity number
    - Otherwise leave the existing FATAL (silent) setting in place
    Wrap in a try/catch — a failed native call must not block startup.

14. **Codebase hygiene — single log path**
    Replace four `debugPrint(...)` calls with `AppLogger.instance.warning(...)`:
    - `lib/widgets/.../animation_message.dart:83`
    - `lib/widgets/.../sticker_message.dart:68`
    - `lib/widgets/.../sticker_grid_item.dart:130`
    - One inside `app_logger.dart:44` (`Failed to create file output`) stays as-is — it runs before the logger itself is up.
    Add a lint rule or grep check in CI later if the project wants drift protection (out of scope here).

15. **Redaction preserved**
    `TdlibLogger._sanitizeRequest/_sanitizeResponse/_sanitizeUpdate` are untouched. Demoting log levels does not change what those methods emit. Breadcrumbs reuse the same `_log` path, so they inherit redaction automatically.

16. **README documentation**
    Add a short "Logging" section to `README.md` covering:
    - The `TELEGA_LOG` env variable and its grammar (`default,module=level,...`)
    - The list of recognized module names, including the `bridge`/`tdlib` alias
    - The `bridge.native=<level>` token for the native (C++) side, with the note that native logs print on a separate path
    - Default behavior in debug vs. release builds
    - The "hot restart picks up changes; hot reload does not" caveat
    A few worked examples make this concrete:
    - `TELEGA_LOG=warning` — quiet
    - `TELEGA_LOG=info,bridge=trace` — see every TDLib call while keeping the rest at info
    - `TELEGA_LOG=debug,messages=trace,bridge.native=info` — heavy debugging session

## Risks

- **`Platform.environment` is desktop-friendly, mobile-thin.** On iOS/Android, app launch env vars are limited or absent. Mitigation: document that runtime env override is a desktop feature; mobile builds fall back to the build-mode default. The user's daily target is desktop, so this is acceptable.

- **Singleton `AppLogger` makes filter changes hard to test.** Mitigation: keep `LogFilterConfig.parse(String)` as a pure static function and test it directly. Don't try to test the singleton end-to-end.

- **TDLib native log call may fail or change shape.** Mitigation: try/catch around the native level setter; on failure, log one warning and continue with FATAL. The default is "silent" — a failed promotion is harmless.

- **Demoting bridge/message logs hides info someone relied on.** Mitigation: the env var restores everything (`TELEGA_LOG=trace`). Add a one-line note to the project README so the next surprised developer finds the answer.

- **Hot reload does not re-read env vars.** Mitigation: comment in `logging_config.dart` and a line in the README. Hot restart works; full rebuild not required.

- **Breadcrumb ring buffer leaks memory if not capped properly.** Mitigation: use `Queue` with explicit `removeFirst()` when length > 20. Unit-test the cap.

## Decisions

- **Env variable name**: `TELEGA_LOG`.
- **Subsystem aliases**: `LogModule.tdlib` stays. The env-var parser accepts both `bridge` and `tdlib` as names for the same subsystem. Both names appear in the README so developers know either works.
- **`fatal` level**: kept on the public logger surface alongside `trace, debug, info, warning, error`. Reserved for crash-class events.
