# Telegram Flutter Client

A modern Telegram client built with Flutter and TDLib, featuring Gateway API authentication for cost-effective verification without traditional SMS.

## Features

### ✅ Implemented (Authentication Demo)
- **TDLib Integration**: Native Telegram Database Library integration via FFI
- **Gateway API Support**: Verification codes delivered through Telegram instead of SMS
- **Dual Authentication Methods**:
  - Phone number + Telegram code verification
  - QR code authentication (secondary option)
- **Cross-Platform**: Linux desktop support with clean Material Design UI
- **Session Persistence**: Automatic session management and restoration
- **Error Handling**: Comprehensive error handling and user feedback
- **2FA Support**: Two-factor authentication (password) handling

### 🚧 Planned Features
- Chat list and conversation view
- Message sending and receiving
- File and media sharing
- Notifications
- Group and channel management
- Voice and video calls

## Architecture

```
telegram_flutter_client/
├── lib/
│   ├── core/
│   │   ├── tdlib_client.dart      # TDLib FFI wrapper and client
│   │   └── auth_manager.dart      # Authentication state management
│   ├── models/
│   │   ├── auth_state.dart        # Authentication state models
│   │   └── user_session.dart      # User session data model
│   ├── screens/
│   │   ├── auth_screen.dart       # Authentication screen with tabs
│   │   └── home_screen.dart       # Post-authentication home screen
│   ├── widgets/
│   │   └── auth_widgets.dart      # Reusable authentication widgets
│   └── utils/
│       └── tdlib_bindings.dart    # TDLib FFI bindings
├── linux/
│   └── lib/
│       └── libtdjson.so           # TDLib native library
└── setup_tdlib.sh                # Setup script
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.4.4 or higher)
- Linux development tools
- TDLib binary for your platform

### 2. Clone and Setup
```bash
git clone <repository-url>
cd telegram_flutter_client
flutter pub get
```

### 3. TDLib Setup
```bash
# Run the setup script for instructions
./setup_tdlib.sh
```

You'll need to:
1. **Obtain TDLib binary** (`libtdjson.so` for Linux)
   - Download from [TDLib releases](https://github.com/tdlib/td)
   - Or build from source following [TDLib build guide](https://tdlib.github.io/td/build.html)
   - Place the binary in `linux/lib/libtdjson.so`

2. **Get API credentials**
   - Visit [my.telegram.org/apps](https://my.telegram.org/apps)
   - Create a new application
   - Update `api_id` and `api_hash` in `lib/core/tdlib_client.dart`

### 4. Run the Application
```bash
flutter run -d linux
```

## Authentication Flow

### Gateway API vs SMS
This client uses Telegram's **Gateway API** for authentication, which offers several advantages over traditional SMS:

- **Cost-effective**: $0.01 per code vs up to 50x more for SMS
- **More secure**: End-to-end encryption, no SIM swap vulnerabilities  
- **Better delivery**: Instant delivery vs SMS delays and failures
- **User-friendly**: Codes appear directly in Telegram

### Authentication Process
1. **Phone Number Entry**: User enters their phone number
2. **Code Delivery**: Verification code sent via Telegram (not SMS)
3. **Code Verification**: User enters the code received in Telegram
4. **2FA (if enabled)**: Password entry for two-factor authentication
5. **Registration (if new)**: First name/last name entry for new users
6. **Session Creation**: Persistent session saved locally

### QR Code Authentication
- Alternative login method for users with another authenticated device
- Generates QR code for scanning from Telegram mobile app
- Requires confirmation on the authenticated device

## Dependencies

### Core Dependencies
- `ffi: ^2.1.0` - Foreign Function Interface for TDLib
- `path_provider: ^2.1.0` - Platform-specific directory paths
- `provider: ^6.1.0` - State management
- `shared_preferences: ^2.2.0` - Local data persistence

### Optional Dependencies
- `qr_code_scanner: ^1.0.1` - QR code scanning functionality

## Development Notes

### TDLib Integration
- Uses FFI to communicate with native TDLib library
- Handles JSON-based message passing
- Manages authorization states automatically
- Implements proper session persistence

### State Management
- Uses Provider pattern for reactive state management
- Separates authentication logic from UI components
- Provides real-time updates for auth state changes

### Error Handling
- Comprehensive error catching and user feedback
- Network error handling and retry logic
- Graceful handling of authentication failures

## Security Considerations

- API credentials should be kept secure in production
- Session data is stored locally and encrypted by TDLib
- Gateway API provides better security than SMS verification
- No hardcoded secrets or credentials in the codebase

## Contributing

This is currently an authentication demo. Contributions for additional Telegram features are welcome:

1. Fork the repository
2. Create a feature branch
3. Implement the feature following existing patterns
4. Add appropriate error handling and tests
5. Submit a pull request

## License

This project is for educational and demonstration purposes. Make sure to comply with Telegram's Terms of Service when using their APIs.

## Troubleshooting

### Common Issues

**"Library not found" error**:
- Ensure `libtdjson.so` is in the correct location (`linux/lib/`)
- Verify the binary is compatible with your Linux distribution

**Authentication failures**:
- Check your API credentials are correct
- Ensure you're using valid phone numbers
- Verify network connectivity

**Build errors**:
- Run `flutter clean && flutter pub get`
- Ensure all dependencies are properly installed
- Check Flutter and Dart SDK versions

### Debug Mode
The application includes debug logging for development. Check the console output for detailed information about TDLib operations and authentication flow.

## Logging

Verbosity is controlled at runtime through the `TELEGA_LOG` environment
variable. The grammar is `RUST_LOG`-style: a default level plus optional
per-subsystem overrides, separated by commas.

```
TELEGA_LOG=<default>[,<module>=<level>]...
```

### Levels

`trace`, `debug`, `info`, `warning`, `error`, `fatal` — exact names from
`package:logger`. Calls below `warning` go through the per-module gate; calls
at `warning` and above always emit, regardless of subsystem level.

### Recognized modules

- `auth` — authentication
- `bridge` (alias: `tdlib`) — Telegram client library calls and updates
- `messages` — message pipeline (sends, edits, server-pushed updates)
- `chats` — chat list pipeline
- `network` — network layer
- `storage` — local storage
- `ui` — widgets and screens
- `performance` (alias: `perf`) — timing and profiling
- `general` — anything that doesn't fit the others

### Native bridge level

The TDLib C++ side runs at `fatal` (silent) by default. Raise it with the
special `bridge.native=<level>` token. Native logs print on a separate path
with their own format — they are not unified with the Dart logger output.

### Defaults

- Debug builds: default level `info`; native bridge `fatal`
- Release/profile builds: default level `warning`; native bridge `fatal`

### Examples

```bash
# Quiet — warnings and errors only.
TELEGA_LOG=warning flutter run

# Default development view, plus every TDLib request and update.
TELEGA_LOG=info,bridge=trace flutter run

# Heavy debugging session: messages firehose plus native bridge info.
TELEGA_LOG=debug,messages=trace,bridge.native=info flutter run

# Investigate one chat update flow without other noise.
TELEGA_LOG=warning,chats=debug flutter run
```

### Notes

- The variable is read once at app startup. Hot **restart** picks up a new
  value; hot **reload** does not — it preserves logger state.
- An invalid level or module name is ignored with a single warning at startup;
  the rest of the expression still applies.
- On mobile platforms env access at launch is limited; logging falls back to
  the build-mode defaults there.

## Acknowledgments

- [TDLib](https://github.com/tdlib/td) - Telegram Database Library
- [Telegram Gateway API](https://core.telegram.org/gateway) - Modern authentication solution
- Flutter and Dart teams for the excellent framework