# Variables
flutter_bin := "flutter"
tdlib_path := "linux/lib/libtdjson.so"
tdlib_src := env_var_or_default("TDLIB_SRC", env_var("HOME") / "github/td")
tdlib_repo := "https://github.com/tdlib/td.git"
android_sdk := env_var_or_default("ANDROID_SDK_ROOT", env_var("HOME") / "Android/Sdk")
ndk_version := env_var_or_default("ANDROID_NDK_VERSION", "29.0.13113456")
android_jni := "android/app/src/main/jniLibs"
android_abis := "arm64-v8a armeabi-v7a x86_64 x86"

# Default recipe
default:
    @just --list

# === Setup Commands ===

# Complete project setup (dependencies + TDLib)
setup: deps setup-tdlib-auto
    @echo "✓ Project setup complete!"
    @echo "You can now run: just run"

# Install Flutter dependencies
deps:
    @echo "📦 Installing Flutter dependencies..."
    {{flutter_bin}} pub get

# Automatically download and setup TDLib (recommended)
setup-tdlib-auto:
    @echo "🔧 Automatically setting up TDLib..."
    @just download-tdlib-npm

# Run original TDLib setup script (manual instructions)
setup-tdlib-manual:
    @echo "🔧 Running manual TDLib setup..."
    chmod +x setup_tdlib.sh
    ./setup_tdlib.sh

# Download TDLib using npm prebuilt-tdlib (recommended)
download-tdlib-npm:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "📦 Downloading TDLib using npm prebuilt-tdlib..."
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        echo "❌ npm not found. Please install Node.js/npm first"
        echo "💡 Alternative: run 'just download-tdlib-direct' for direct download"
        exit 1
    fi
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    cd "$temp_dir"
    
    # Initialize npm project and install prebuilt-tdlib
    echo '{"name": "temp", "private": true}' > package.json
    npm install prebuilt-tdlib
    
    # Find the libtdjson.so file
    tdlib_file=$(find node_modules -name "libtdjson.so" | head -1)
    
    if [ -z "$tdlib_file" ]; then
        echo "❌ Could not find libtdjson.so in npm package"
        exit 1
    fi
    
    # Ensure target directory exists
    mkdir -p "{{justfile_directory()}}/linux/lib"
    
    # Copy the library
    cp "$tdlib_file" "{{justfile_directory()}}/{{tdlib_path}}"
    
    echo "✓ TDLib successfully downloaded to {{tdlib_path}}"
    echo "📋 Version info:"
    strings "{{justfile_directory()}}/{{tdlib_path}}" | grep -i "tdlib\|version" | head -3 || echo "  (version info not available)"

# Download TDLib directly from GitHub releases
download-tdlib-direct:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "📦 Downloading TDLib directly from GitHub..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo "❌ curl not found. Please install curl first"
        exit 1
    fi
    
    # Ensure target directory exists
    mkdir -p "{{justfile_directory()}}/linux/lib"
    
    # Try multiple sources
    echo "🔍 Trying tdlib-binaries (legacy)..."
    
    # Try Dropbox link first (more reliable)
    if curl -L -f -o "{{justfile_directory()}}/{{tdlib_path}}" \
        "https://www.dropbox.com/s/abyepz5ak48uecw/libtdjson.so?dl=1"; then
        echo "✓ TDLib downloaded from Dropbox"
        echo "⚠️  Note: This is TDLib v1.2.0 (older version)"
    else
        echo "❌ Direct download failed"
        echo "💡 Try: just download-tdlib-npm (recommended)"
        echo "💡 Or: just setup-tdlib-manual (manual instructions)"
        exit 1
    fi

# Build TDLib for Android from source (all 4 ABIs)
# Prerequisites: gperf, php, make, perl, java, ninja, Android SDK+NDK
build-tdlib-android: _ensure-tdlib-src
    #!/usr/bin/env bash
    set -euo pipefail

    if [ ! -d "{{android_sdk}}/ndk/{{ndk_version}}" ]; then
        echo "❌ Android NDK {{ndk_version}} not found at {{android_sdk}}/ndk/"
        echo "💡 Install via Android Studio SDK Manager or set ANDROID_NDK_VERSION"
        exit 1
    fi

    echo "📦 Building TDLib for Android ABIs: {{android_abis}}"
    cd "{{tdlib_src}}/example/android"

    # Build OpenSSL once; reused for subsequent TDLib rebuilds
    if [ ! -d "third-party/openssl" ]; then
        echo "🔐 Building OpenSSL (one-time, ~5 min)..."
        ./build-openssl.sh "{{android_sdk}}" "{{ndk_version}}"
    fi

    echo "🔨 Building TDLib JSON (all ABIs, ~5-10 min)..."
    ./build-tdlib.sh "{{android_sdk}}" "{{ndk_version}}" '' '' 'JSON'

    # Copy all ABIs into the Flutter project
    for abi in {{android_abis}}; do
        src="tdlib/libs/$abi/libtdjson.so"
        dst="{{justfile_directory()}}/{{android_jni}}/$abi/libtdjson.so"
        if [ ! -f "$src" ]; then
            echo "❌ Missing build output: $src"
            exit 1
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  ✓ $abi → $dst"
    done

    echo "✓ TDLib for Android built and installed!"
    ls -lh "{{justfile_directory()}}/{{android_jni}}"/*/libtdjson.so

# Build libtdjson.so for Linux from TDLib source
build-tdlib-linux: _ensure-tdlib-src
    #!/usr/bin/env bash
    set -euo pipefail

    echo "📦 Building TDLib for Linux from source (~10-20 min)..."

    missing=()
    for tool in cmake make gcc g++ gperf; do
        command -v $tool >/dev/null 2>&1 || missing+=($tool)
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing build tools: ${missing[*]}"
        echo "💡 Install with: sudo pacman -S cmake make gcc gperf (Arch)"
        echo "             or: sudo apt install cmake make build-essential gperf (Debian)"
        exit 1
    fi

    cd "{{tdlib_src}}"
    mkdir -p build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_LTO=ON .. >/dev/null
    cmake --build . --target tdjson -j$(nproc)

    mkdir -p "{{justfile_directory()}}/linux/lib"
    cp libtdjson.so.* "{{justfile_directory()}}/{{tdlib_path}}" 2>/dev/null || \
        cp libtdjson.so "{{justfile_directory()}}/{{tdlib_path}}"
    chmod +x "{{justfile_directory()}}/{{tdlib_path}}"

    echo "✓ Linux libtdjson.so installed"
    ls -lh "{{justfile_directory()}}/{{tdlib_path}}"

# Ensure TDLib source checkout exists (clones if missing)
_ensure-tdlib-src:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -d "{{tdlib_src}}/.git" ]; then
        echo "📡 Cloning TDLib to {{tdlib_src}}..."
        mkdir -p "$(dirname "{{tdlib_src}}")"
        git clone {{tdlib_repo}} "{{tdlib_src}}"
    fi

# Print TDLib version from source + installed binaries
tdlib-version:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📋 TDLib versions:"
    if [ -f "{{tdlib_src}}/CMakeLists.txt" ]; then
        src_version=$(grep -oE "project\(TDLib VERSION [0-9.]+" "{{tdlib_src}}/CMakeLists.txt" | awk '{print $NF}')
        src_ref=$(git -C "{{tdlib_src}}" rev-parse --short HEAD 2>/dev/null || echo "?")
        src_branch=$(git -C "{{tdlib_src}}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
        echo "  source: $src_version ($src_branch @ $src_ref)"
    else
        echo "  source: (not cloned — run 'just _ensure-tdlib-src')"
    fi
    for so in "{{justfile_directory()}}/{{tdlib_path}}" \
              "{{justfile_directory()}}/{{android_jni}}"/*/libtdjson.so; do
        if [ -f "$so" ]; then
            v=$( (strings "$so" 2>/dev/null | grep -oE "libtdjson\.so\.[0-9.]+" | head -1 | sed 's/libtdjson\.so\.//') || true )
            if [ -z "$v" ]; then
                v=$( (strings "$so" 2>/dev/null | grep -E "^1\.[6-9]\.[0-9]+$" | head -1) || true )
            fi
            v=${v:-?}
            rel=${so#"{{justfile_directory()}}/"}
            size=$(ls -lh "$so" | awk '{print $5}')
            echo "  $rel: $v ($size)"
        fi
    done

# Migrate TDLib to a given git ref (tag/branch/commit) and rebuild for all platforms.
# Usage:
#   just migrate-tdlib              # rebuild at current source HEAD
#   just migrate-tdlib master       # pull & checkout master
#   just migrate-tdlib v1.8.0       # checkout a tag
#   just migrate-tdlib abc123       # checkout a commit
#
# Pipeline: checkout → build Linux → build Android (4 ABIs) → verify SONAMEs →
#           flutter build linux --release → flutter build apk → summary
migrate-tdlib ref="": _ensure-tdlib-src
    #!/usr/bin/env bash
    set -euo pipefail

    echo "══════════════════════════════════════════════════════"
    echo "  TDLib Migration"
    echo "══════════════════════════════════════════════════════"

    # 1. Sync source
    cd "{{tdlib_src}}"
    echo "📡 Fetching latest from origin..."
    git fetch --tags --prune origin

    if [ -n "$(git status --porcelain)" ]; then
        echo "❌ TDLib source at {{tdlib_src}} has uncommitted changes. Clean or stash first."
        git status --short
        exit 1
    fi
    if [ -n "{{ref}}" ]; then
        echo "🔀 Checking out ref: {{ref}}"
        git checkout "{{ref}}"
    fi
    # Fast-forward current branch (if detached HEAD, skip)
    if git symbolic-ref -q HEAD >/dev/null; then
        branch=$(git symbolic-ref --short HEAD)
        echo "⏩ Fast-forwarding branch $branch..."
        git pull --ff-only origin "$branch"
    else
        echo "ℹ️  Detached HEAD — using checked-out commit as-is"
    fi

    new_version=$(grep -oE "project\(TDLib VERSION [0-9.]+" CMakeLists.txt | awk '{print $NF}')
    new_ref=$(git rev-parse --short HEAD)
    new_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "🎯 Target: TDLib $new_version ($new_branch @ $new_ref)"

    # 2. Show current installed versions for diff
    cd "{{justfile_directory()}}"
    extract_version() {
        local so="$1"
        [ -f "$so" ] || { echo "none"; return; }
        local v
        v=$( (strings "$so" 2>/dev/null | grep -oE "libtdjson\.so\.[0-9.]+" | head -1 | sed 's/libtdjson\.so\.//') || true )
        [ -n "$v" ] || v=$( (strings "$so" 2>/dev/null | grep -E "^1\.[6-9]\.[0-9]+$" | head -1) || true )
        echo "${v:-unknown}"
    }
    old_linux=$(extract_version "{{tdlib_path}}")
    old_android=$(extract_version "{{android_jni}}/arm64-v8a/libtdjson.so")
    echo ""
    echo "📊 Current installed:"
    echo "    linux:   $old_linux"
    echo "    android: $old_android"
    echo "📊 Migrating to: $new_version"
    echo ""

    # 3. Build native libraries
    just build-tdlib-linux
    just build-tdlib-android

    # 4. Verify SONAMEs match target version
    echo ""
    echo "🔍 Verifying installed binaries..."
    failed=0
    check_version() {
        local so="$1"
        local label="$2"
        if [ ! -f "$so" ]; then
            echo "  ❌ $label: missing at $so"
            failed=1
            return
        fi
        local v
        v=$( (strings "$so" 2>/dev/null | grep -oE "libtdjson\.so\.[0-9.]+" | head -1 | sed 's/libtdjson\.so\.//') || true )
        [ -n "$v" ] || v=$( (strings "$so" 2>/dev/null | grep -E "^1\.[6-9]\.[0-9]+$" | head -1) || true )
        if [ "$v" = "$new_version" ]; then
            echo "  ✓ $label: $v"
        else
            echo "  ❌ $label: got '${v:-?}', expected '$new_version'"
            failed=1
        fi
    }
    check_version "{{tdlib_path}}" "linux"
    for abi in {{android_abis}}; do
        check_version "{{android_jni}}/$abi/libtdjson.so" "android/$abi"
    done

    if [ $failed -ne 0 ]; then
        echo "❌ Version verification failed"
        exit 1
    fi

    # 5. Verify Flutter builds
    echo ""
    echo "🧪 Verifying Flutter builds..."
    {{flutter_bin}} pub get >/dev/null

    echo "  🐧 Building Linux release..."
    {{flutter_bin}} build linux --release

    echo "  🤖 Building Android APK (arm64-v8a)..."
    {{flutter_bin}} build apk --target-platform android-arm64

    # 6. FFI smoke test (loads libtdjson and calls a sync TDLib function)
    echo ""
    echo "  🔬 Linux FFI smoke test..."
    just smoke-test-tdlib-linux

    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  ✅ Migration complete: $old_linux → $new_version"
    echo "══════════════════════════════════════════════════════"
    just tdlib-version

# FFI smoke test — loads libtdjson on Linux, calls a sync TDLib function via FFI, verifies response.
# Does not require Telegram credentials or network.
smoke-test-tdlib-linux:
    #!/usr/bin/env bash
    set -euo pipefail
    dart run "{{justfile_directory()}}/tool/tdlib_smoke_test.dart"

# Build TDLib from source (advanced users)
build-tdlib-source:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔨 Building TDLib from source..."
    echo "⚠️  This will take 10-30 minutes and requires build tools"
    
    # Check for required tools
    missing_tools=()
    for tool in git cmake make gcc g++; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "💡 Install with: sudo apt update && sudo apt install git cmake make build-essential"
        exit 1
    fi
    
    # Create build directory
    build_dir="{{justfile_directory()}}/tdlib_build"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Clone TDLib if not exists
    if [ ! -d "td" ]; then
        echo "📡 Cloning TDLib repository..."
        git clone https://github.com/tdlib/td.git
    fi
    
    cd td
    git pull
    
    # Build
    echo "🔨 Building TDLib..."
    mkdir -p build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release ..
    cmake --build . -j$(nproc)
    
    # Copy the built library
    mkdir -p "{{justfile_directory()}}/linux/lib"
    cp libtdjson.so "{{justfile_directory()}}/{{tdlib_path}}"
    
    echo "✓ TDLib built and installed successfully!"
    
    # Cleanup
    read -p "Remove build directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$build_dir"
        echo "🧹 Build directory cleaned"
    fi

# === Run Commands ===

# Run app in debug mode
run:
    @echo "🚀 Running Telegram Flutter Client..."
    {{flutter_bin}} run -d linux

# Run app with pm2 (logs in /tmp, no auto-restart)
run-pm2:
    @echo "🚀 Starting with pm2..."
    -pm2 delete telega2 2>/dev/null
    : > /tmp/telega2-out.log
    : > /tmp/telega2-err.log
    pm2 start ecosystem.config.js
    @echo "📋 Logs: tail -f /tmp/telega2-out.log"

# Stop pm2 app
stop-pm2:
    pm2 stop telega2

# Show pm2 logs
logs-pm2:
    tail -f /tmp/telega2-out.log

# Run app in release mode
run-release:
    @echo "🚀 Running in release mode..."
    {{flutter_bin}} run -d linux --release

# Run on Linux specifically
run-linux: check-tdlib
    @echo "🐧 Running on Linux..."
    {{flutter_bin}} run -d linux

# === Build Commands ===

# Build for current platform
build:
    @echo "🔨 Building application..."
    {{flutter_bin}} build linux

# Build Linux release
build-linux:
    @echo "🐧 Building Linux release..."
    {{flutter_bin}} build linux --release

# Build Android APK (ARM64 only for Nothing Phone 2)
build-apk: check-tdlib-android
    @echo "🤖 Building Android APK (ARM64)..."
    {{flutter_bin}} build apk --target-platform android-arm64

# Build and deploy to pCloud
deploy-phone: build-apk
    #!/usr/bin/env bash
    set -euo pipefail

    dest="$HOME/pCloudDrive/android-apps/telega2"
    mkdir -p "$dest"

    echo "📦 Copying APK to pCloud..."
    cp "{{justfile_directory()}}/build/app/outputs/flutter-apk/app-release.apk" "$dest/telega2.apk"

    echo "✓ Done! APK at: $dest/telega2.apk"

# Run on connected Android device
run-android: check-tdlib-android
    @echo "🤖 Running on Android device..."
    {{flutter_bin}} run -d android

# Check if TDLib Android binary exists
check-tdlib-android:
    #!/usr/bin/env bash
    tdlib_android="{{justfile_directory()}}/android/app/src/main/jniLibs/arm64-v8a/libtdjson.so"
    if [ ! -f "$tdlib_android" ]; then
        echo "❌ TDLib Android binary not found"
        echo "💡 Run: just build-tdlib-android"
        exit 1
    else
        echo "✓ TDLib Android binary found"
        ls -lh "$tdlib_android"
    fi

# Build iOS (macOS only)
build-ios:
    @echo "🍎 Building iOS..."
    {{flutter_bin}} build ios

# === Development Commands ===

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    {{flutter_bin}} clean
    rm -rf build/

# Run Flutter analyzer
analyze:
    @echo "🔍 Running Flutter analyzer..."
    {{flutter_bin}} analyze

# Format code
format:
    @echo "✨ Formatting code..."
    dart format .

# Run tests
test:
    @echo "🧪 Running tests..."
    {{flutter_bin}} test

# Check Flutter environment
doctor:
    @echo "🩺 Checking Flutter environment..."
    {{flutter_bin}} doctor -v

# === Utility Commands ===

# Check if TDLib binary exists
check-tdlib:
    #!/usr/bin/env bash
    if [ ! -f "{{tdlib_path}}" ]; then
        echo "❌ TDLib binary not found at {{tdlib_path}}"
        echo "💡 Available setup options:"
        echo "   just setup-tdlib-auto    (recommended - uses npm)"
        echo "   just download-tdlib-direct (direct download)"
        echo "   just build-tdlib-source    (build from source)"
        echo "   just setup-tdlib-manual    (manual instructions)"
        exit 1
    else
        echo "✓ TDLib binary found at {{tdlib_path}}"
        # Show some info about the binary
        if command -v file &> /dev/null; then
            echo "📋 File info: $(file {{tdlib_path}})"
        fi
        if command -v ls &> /dev/null; then
            echo "📏 File size: $(ls -lh {{tdlib_path}} | awk '{print $5}')"
        fi
    fi

# Remove TDLib binary (for testing different versions)
clean-tdlib:
    @echo "🗑️  Removing TDLib binary..."
    rm -f {{tdlib_path}}
    @echo "✓ TDLib binary removed"

# Just get packages
pub-get:
    @echo "📦 Getting packages..."
    {{flutter_bin}} pub get

# Upgrade packages
pub-upgrade:
    @echo "⬆️  Upgrading packages..."
    {{flutter_bin}} pub upgrade

# Show project info
info:
    @echo "📋 Project Information:"
    @echo "  Name: Telegram Flutter Client"
    @echo "  Platform: Linux (primary)"
    @echo "  Flutter: $({{flutter_bin}} --version | head -1)"
    @echo "  TDLib: $(if [ -f {{tdlib_path}} ]; then echo 'Installed'; else echo 'Not installed'; fi)"

# Show TDLib setup help
help-tdlib:
    @echo "🔧 TDLib Setup Options:"
    @echo ""
    @echo "🚀 Quick Start:"
    @echo "  just setup                 - Complete setup (recommended)"
    @echo ""
    @echo "📦 TDLib Installation Methods:"
    @echo "  just setup-tdlib-auto      - Automatic download via npm (recommended)"
    @echo "  just download-tdlib-direct - Direct download from GitHub"
    @echo "  just build-tdlib-source    - Build from source (advanced)"
    @echo "  just setup-tdlib-manual    - Show manual instructions"
    @echo ""
    @echo "🔍 Utilities:"
    @echo "  just check-tdlib           - Verify TDLib installation"
    @echo "  just clean-tdlib           - Remove current TDLib binary"
    @echo ""
    @echo "💡 Recommended: Run 'just setup' for automatic setup"

# === Quick Development Workflow ===

# Quick check: format, analyze, test
check: format analyze test
    @echo "✅ All checks passed!"

# Development server with hot reload
dev: check-tdlib
    @echo "🔥 Starting development server with hot reload..."
    {{flutter_bin}} run -d linux --hot

# Full clean rebuild
rebuild: clean deps build
    @echo "🔄 Full rebuild complete!"