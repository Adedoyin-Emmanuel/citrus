#!/usr/bin/env bash
# Builds Citrus and packages it as a proper macOS .app bundle.
#
# A real bundle (with an Info.plist + bundle identifier, ad-hoc code signed) is
# required for user notifications to work and for the app to behave like a real
# menu bar utility. Run `swift run` for quick dev iteration; run this to get a
# distributable Citrus.app whose "job finished" notifications actually appear.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Citrus"
BUNDLE_ID="com.nativelyai.citrus"
CONFIG="release"
BUILD_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

echo "Building ${APP_NAME} (${CONFIG})..."
swift build -c "$CONFIG"

APP_DIR=".build/${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RESOURCES_DIR="${APP_DIR}/Contents/Resources"

echo "Assembling bundle at ${APP_DIR}..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Bundled SwiftPM resources, if any.
if [ -d "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle" ]; then
  cp -R "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle" "${RESOURCES_DIR}/"
fi

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_DIR"

echo "Built ${APP_DIR}"
echo "Run it with: open \"${APP_DIR}\""
