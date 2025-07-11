#!/bin/bash

# ---- CONFIGURATION ----
APP_NAME="RunPython.app"
VOLUME_NAME="RunPython Installer"
APP_SOURCE_PATH="$HOME/Documents/$APP_NAME"
DMG_OUTPUT_PATH="$HOME/Documents/RunPython.dmg"
DMG_SRC_DIR="$HOME/Documents/dmg-src"
CERT_NAME="Apple Distribution: SUMURI LLC (M2UAN8S5M3)"
# ------------------------

set -e

echo "🔍 Verifying .app exists at $APP_SOURCE_PATH..."
if [ ! -d "$APP_SOURCE_PATH" ]; then
  echo "❌ $APP_NAME not found at $APP_SOURCE_PATH"
  exit 1
fi

echo "🛡️ Checking notarization status with spctl..."
SPCTL_OUTPUT=$(spctl --assess --type exec --verbose "$APP_SOURCE_PATH" 2>&1 || true)

if echo "$SPCTL_OUTPUT" | grep -q "accepted"; then
  echo "✅ App is notarized and accepted by Gatekeeper."
else
  echo "❌ App is NOT notarized or has issues:"
  echo "$SPCTL_OUTPUT"
  exit 1
fi

echo "📌 Stapling the app (notarization ticket)..."
xcrun stapler staple "$APP_SOURCE_PATH"

echo "✅ Staple complete!"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
  echo "📦 create-dmg not found. Installing via Homebrew..."
  if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
    exit 1
  fi
  brew install create-dmg
else
  echo "✅ create-dmg is already installed."
fi

echo "🧹 Cleaning previous dmg build..."
rm -rf "$DMG_SRC_DIR"
rm -f "$DMG_OUTPUT_PATH"

echo "📁 Preparing dmg source directory..."
mkdir -p "$DMG_SRC_DIR"
cp -R "$APP_SOURCE_PATH" "$DMG_SRC_DIR/"

echo "💿 Creating DMG..."
create-dmg \
  --volname "$VOLUME_NAME" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "$APP_NAME" 200 190 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 600 185 \
  "$DMG_OUTPUT_PATH" \
  "$DMG_SRC_DIR"

echo "✅ DMG created at: $DMG_OUTPUT_PATH"

echo "📌 Stapling the DMG (optional)..."
xcrun stapler staple "$DMG_OUTPUT_PATH"

echo "✅ Done. Your signed and notarized DMG is ready! 🎉"
