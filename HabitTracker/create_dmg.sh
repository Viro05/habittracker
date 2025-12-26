#!/bin/bash

# Create DMG for HabitTracker App
# This script creates a distributable .dmg file for the HabitTracker app

set -e

APP_NAME="HabitTracker"
VERSION="1.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="./build/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_DIR="./dmg_temp"
DMG_PATH="./${DMG_NAME}.dmg"

echo "🚀 Creating DMG for ${APP_NAME}..."

# Check if app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ App not found at ${APP_PATH}"
    echo "Please build the app first with: xcodebuild -project HabitTracker.xcodeproj -scheme HabitTracker -configuration Release -derivedDataPath ./build clean build"
    exit 1
fi

# Clean up previous builds
rm -rf "${DMG_DIR}"
rm -f "${DMG_PATH}"

# Create temporary directory for DMG contents
mkdir -p "${DMG_DIR}"

# Copy the app to DMG directory
echo "📦 Copying app bundle..."
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "${DMG_DIR}/Applications"

# Create a background for the DMG (optional)
mkdir -p "${DMG_DIR}/.background"
cat > "${DMG_DIR}/.background/background.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #000000;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            opacity: 0.3;
        }
        h1 {
            font-size: 48px;
            font-weight: 100;
            margin: 0;
        }
        p {
            font-size: 16px;
            font-weight: 300;
            margin: 10px 0 0 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>HabitTracker</h1>
        <p>Minimal Habit Tracking</p>
    </div>
</body>
</html>
EOF

# Create DS_Store for custom DMG appearance
cat > "${DMG_DIR}/.DS_Store_template" << 'EOF'
# Custom DMG layout settings will be applied when opened
EOF

echo "💿 Creating DMG file..."

# Create the DMG
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_PATH}"

# Clean up temp directory
rm -rf "${DMG_DIR}"

echo "✅ DMG created successfully: ${DMG_PATH}"
echo ""
echo "📁 DMG Contents:"
echo "   • ${APP_NAME}.app (Drag to Applications folder)"
echo "   • Applications (Shortcut to Applications folder)"
echo ""
echo "🎉 You can now distribute ${DMG_NAME}.dmg!"
echo ""
echo "📋 Installation Instructions for Users:"
echo "   1. Double-click ${DMG_NAME}.dmg to mount it"
echo "   2. Drag ${APP_NAME}.app to the Applications folder"
echo "   3. Launch ${APP_NAME} from Applications or Spotlight"
echo ""
echo "💡 Note: Users may need to allow the app in System Preferences > Security & Privacy if prompted."

# Get file size
DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
echo "📊 DMG Size: ${DMG_SIZE}"
