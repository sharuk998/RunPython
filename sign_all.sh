#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_PATH="$SCRIPT_DIR"
CERT="Apple Distribution: The App Dynamics LLC (65G85Y9KN7)"

echo "🧹 Cleaning up unnecessary files..."

# Avoid deleting anything inside .xcframework
find "$APP_PATH" -path "*/Python.xcframework/*" -prune -o -name "*.o" -delete
find "$APP_PATH" -path "*/Python.xcframework/*" -prune -o -name "*.a" -delete
find "$APP_PATH" -name "*.pyc" -delete
find "$APP_PATH" -type d -name "__pycache__" -exec rm -rf {} +

echo "📝 Signing native binaries inside $APP_PATH"

# Find all .dylib and .so files and sign them
find "$APP_PATH" -type f \( -name "*.so" -o -name "*.dylib" \) | while read file; do
  echo "🔏 Signing $file"
  codesign --force --options runtime --sign "$CERT" "$file"
done

# Sign Python interpreter
INTERPRETER="$APP_PATH/iLEAPP/venv/bin/python3.12"
if [ -f "$INTERPRETER" ]; then
  echo "🔏 Signing $INTERPRETER"
  codesign --force --options runtime --sign "$CERT" "$INTERPRETER"
fi

# Sign PyInstaller bootloaders
for bootloader in run run_d runw runw_d; do
  BOOTLOADER_PATH="$APP_PATH/iLEAPP/venv/lib/python3.12/site-packages/PyInstaller/bootloader/Darwin-64bit/$bootloader"
  if [ -f "$BOOTLOADER_PATH" ]; then
    echo "🔏 Signing $BOOTLOADER_PATH"
    codesign --force --options runtime --sign "$CERT" "$BOOTLOADER_PATH"
  fi
done

BUNDLE_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" \
  -path "*/Build/Products/Debug/RunPython.app" \
  ! -path "*/Index.noindex/*" \
  -type d -print -quit)
  
if [ -z "$BUNDLE_PATH" ] || [ ! -d "$BUNDLE_PATH/Contents/MacOS" ]; then
  echo "❌ RunPython.app not found or invalid"
  exit 1
fi

# Final app-wide deep signing
echo "🔏 Signing app bundle $BUNDLE_PATH"
codesign --force --deep --options runtime --sign "$CERT" "$BUNDLE_PATH"

echo "✅ Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$BUNDLE_PATH"

echo "🎉 Done"
