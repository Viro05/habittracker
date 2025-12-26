#!/bin/bash

# Generate App Icons Script
# This script creates all required app icon sizes for macOS from the SVG template

# Check if we have the required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo "Installing librsvg (for rsvg-convert)..."
    if command -v brew &> /dev/null; then
        brew install librsvg
    else
        echo "Please install Homebrew first: https://brew.sh"
        echo "Then run: brew install librsvg"
        exit 1
    fi
fi

# Create the AppIcon.appiconset directory
ICON_DIR="$(dirname "$0")/../HabitTracker/Assets.xcassets/AppIcon.appiconset"
SVG_FILE="$(dirname "$0")/icon.svg"

# Array of required icon sizes for macOS
declare -a sizes=(
    "16:16x16"
    "32:16x16@2x"
    "32:32x32"
    "64:32x32@2x"
    "128:128x128"
    "256:128x128@2x"
    "256:256x256"
    "512:256x256@2x"
    "512:512x512"
    "1024:512x512@2x"
)

echo "Generating app icons..."

# Generate each required size
for size_info in "${sizes[@]}"; do
    IFS=':' read -r pixels name <<< "$size_info"
    output_file="${ICON_DIR}/icon_${pixels}x${pixels}.png"

    echo "Generating ${name} (${pixels}x${pixels}px)..."
    rsvg-convert -w ${pixels} -h ${pixels} "${SVG_FILE}" -o "${output_file}"
done

# Update the Contents.json with proper filenames
cat > "${ICON_DIR}/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ App icons generated successfully!"
echo "Icons saved to: ${ICON_DIR}"
