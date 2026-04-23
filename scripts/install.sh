#!/usr/bin/env bash
# install.sh — build Hidden Bar Revived in Release and install to /Applications.
#
# Usage: ./scripts/install.sh [--debug] [--no-launch]
#   --debug      build Debug configuration instead of Release
#   --no-launch  install but don't open the app afterward
#
# Requires Xcode command line tools. Writes to /Applications, which on a
# standard macOS install is writable by admin users without sudo.

set -euo pipefail

CONFIG=Release
LAUNCH_AFTER_INSTALL=1
for arg in "$@"; do
    case "$arg" in
        --debug) CONFIG=Debug ;;
        --no-launch) LAUNCH_AFTER_INSTALL=0 ;;
        -h|--help)
            sed -n '2,10p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 2
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="Hidden Bar.xcodeproj"
SCHEME="Hidden Bar"
DERIVED="build"
APP_NAME="Hidden Bar Revived"
APP_BUNDLE="$DERIVED/Build/Products/$CONFIG/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"
LOG=/tmp/hiddenbarrevived-build.log

echo "==> Building $APP_NAME ($CONFIG)..."
rm -rf "$DERIVED"
if ! xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -derivedDataPath "$DERIVED" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=YES \
        DEVELOPMENT_TEAM="" \
        build >"$LOG" 2>&1; then
    echo "Build failed. Last 40 lines of log:" >&2
    tail -40 "$LOG" >&2
    exit 1
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Expected $APP_BUNDLE not found after build. Check $LOG." >&2
    exit 1
fi

echo "==> Quitting any running instance..."
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
pkill -f "$APP_NAME.app/Contents/MacOS" 2>/dev/null || true
# Give launchd a moment to release the bundle.
sleep 1

echo "==> Installing to $INSTALL_PATH..."
if [[ -e "$INSTALL_PATH" ]]; then
    rm -rf "$INSTALL_PATH"
fi
cp -R "$APP_BUNDLE" "$INSTALL_PATH"
xattr -cr "$INSTALL_PATH"

VERSION=$(defaults read "$INSTALL_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "?")
BUILD=$(defaults read "$INSTALL_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "?")
echo "==> Installed $APP_NAME $VERSION ($BUILD)"

if [[ "$LAUNCH_AFTER_INSTALL" -eq 1 ]]; then
    echo "==> Launching..."
    open "$INSTALL_PATH"
fi
