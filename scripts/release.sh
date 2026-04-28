#!/usr/bin/env bash
# release.sh — build, sign, notarize, staple, and package Hidden Bar Revived
# as a distributable `.zip` for GitHub Releases + Homebrew cask.
#
# Usage:
#   ./scripts/release.sh                       # uses keychain profile HiddenBarNotary
#   NOTARY_PROFILE=MyProfile ./scripts/release.sh
#   DRY_RUN=1 ./scripts/release.sh             # build + sign + staple, skip notarize
#   SKIP_NOTARIZE=1 ./scripts/release.sh       # sign only, skip notarize + staple
#
# Required before first run — one-time keychain credential setup:
#
#   xcrun notarytool store-credentials "HiddenBarNotary" \
#       --apple-id   "you@example.com" \
#       --team-id    "485WH9DHS4" \
#       --password   "xxxx-xxxx-xxxx-xxxx"   # app-specific password
#
# The Developer ID Application certificate must be installed in the login
# keychain and visible to `security find-identity -v -p codesigning`.
#
# Output: dist/HiddenBarRevived-<version>.zip plus a sibling `.sha256` file
# whose contents are ready to paste into the Homebrew cask.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- Config ---------------------------------------------------------------

PROJECT="Hidden Bar.xcodeproj"
SCHEME="Hidden Bar"
APP_NAME="Hidden Bar Revived"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Shelby Denike (485WH9DHS4)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-HiddenBarNotary}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist}"
BUILD_DIR="$REPO_ROOT/build-release"

# --- Derive version from project.pbxproj ---------------------------------

VERSION="$(grep -m1 'MARKETING_VERSION = ' "$PROJECT/project.pbxproj" | sed -E 's/.*= *([^;]+);.*/\1/' | tr -d ' ')"
BUILD_NUMBER="$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PROJECT/project.pbxproj" | sed -E 's/.*= *([^;]+);.*/\1/' | tr -d ' ')"

if [[ -z "$VERSION" ]]; then
    echo "Could not derive MARKETING_VERSION from $PROJECT/project.pbxproj" >&2
    exit 1
fi

ARTIFACT_BASE="HiddenBarRevived-$VERSION"
ZIP_PATH="$OUTPUT_DIR/$ARTIFACT_BASE.zip"

echo "==> Releasing $APP_NAME $VERSION ($BUILD_NUMBER)"

# --- Preflight -----------------------------------------------------------

# Apple's App Store Connect requirement (effective 2026-04-28): apps must be
# built with Xcode 26+ using the macOS 26 SDK. Developer ID notarization
# does NOT require this, but we enforce it anyway so the artifact we ship
# is also App Store ready when that path opens up.
MIN_XCODE_MAJOR=26
MIN_SDK_MAJOR=26
XCODE_VERSION="$(xcodebuild -version | head -1 | awk '{ print $2 }')"
SDK_VERSION="$(xcrun --sdk macosx --show-sdk-version)"
if [[ "${XCODE_VERSION%%.*}" -lt "$MIN_XCODE_MAJOR" ]]; then
    echo "Xcode $XCODE_VERSION is older than the required Xcode $MIN_XCODE_MAJOR." >&2
    echo "Install Xcode 26+ and run 'sudo xcode-select -s /Applications/Xcode.app'." >&2
    exit 1
fi
if [[ "${SDK_VERSION%%.*}" -lt "$MIN_SDK_MAJOR" ]]; then
    echo "macOS SDK $SDK_VERSION is older than the required macOS $MIN_SDK_MAJOR SDK." >&2
    exit 1
fi
echo "==> Toolchain: Xcode $XCODE_VERSION, macOS SDK $SDK_VERSION"

if ! security find-identity -v -p codesigning | grep -qF "$SIGNING_IDENTITY"; then
    echo "Signing identity not found in keychain: $SIGNING_IDENTITY" >&2
    echo "Available identities:" >&2
    security find-identity -v -p codesigning >&2
    exit 1
fi

if [[ "${SKIP_NOTARIZE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
    if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
        echo "notarytool profile '$NOTARY_PROFILE' not configured." >&2
        echo "Run this once:" >&2
        echo "  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\" >&2
        echo "      --apple-id you@example.com --team-id 485WH9DHS4 --password xxxx-xxxx-xxxx-xxxx" >&2
        exit 1
    fi
fi

# --- Build ---------------------------------------------------------------

echo "==> Building Release configuration..."
rm -rf "$BUILD_DIR"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=485WH9DHS4 \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
    build

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Build did not produce $APP_PATH" >&2
    exit 1
fi

# --- Verify signature ----------------------------------------------------

echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=1 "$APP_PATH"
codesign -dv --verbose=2 "$APP_PATH" 2>&1 | grep -E "Authority|TeamIdentifier|flags" || true

# --- Notarize + staple ---------------------------------------------------

mkdir -p "$OUTPUT_DIR"

if [[ "${SKIP_NOTARIZE:-0}" == "1" ]]; then
    echo "==> SKIP_NOTARIZE=1, skipping notarization"
elif [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "==> DRY_RUN=1, skipping notarization"
else
    SUBMISSION_ZIP="$OUTPUT_DIR/$ARTIFACT_BASE-for-notarization.zip"
    echo "==> Packaging for notarization..."
    /usr/bin/ditto -c -k --keepParent "$APP_PATH" "$SUBMISSION_ZIP"

    echo "==> Submitting to Apple notarization service (this can take a few minutes)..."
    xcrun notarytool submit "$SUBMISSION_ZIP" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait

    rm -f "$SUBMISSION_ZIP"

    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
fi

# --- Package final artifact ----------------------------------------------

echo "==> Packaging $ZIP_PATH..."
rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

SHA256="$(/usr/bin/shasum -a 256 "$ZIP_PATH" | awk '{ print $1 }')"
echo "$SHA256  $(basename "$ZIP_PATH")" > "$ZIP_PATH.sha256"

echo ""
echo "==> Release artifact ready:"
echo "    $ZIP_PATH"
echo "    sha256: $SHA256"
echo ""
echo "Next steps:"
echo "  1. gh release create v$VERSION \"$ZIP_PATH\" \\"
echo "         --title \"v$VERSION\" --notes-file CHANGELOG.md"
echo "  2. Update Casks/hidden-revived.rb in the homebrew-hidden-revived tap:"
echo "         version \"$VERSION\""
echo "         sha256 \"$SHA256\""
