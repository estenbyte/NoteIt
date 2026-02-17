#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/NoteItRelease"
DMG_DIR="/tmp/NoteIt-dmg"
OUTPUT="$PROJECT_DIR/NoteIt-$VERSION.dmg"

echo "Building NoteIt v$VERSION..."

# Build
xcodebuild -project "$PROJECT_DIR/NoteIt/NoteIt.xcodeproj" \
    -scheme NoteIt \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build | grep -E "error:|BUILD"

# Create DMG
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$BUILD_DIR/Build/Products/Release/NoteIt.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

rm -f "$OUTPUT"
hdiutil create -volname "NoteIt" -srcfolder "$DMG_DIR" -ov -format UDZO "$OUTPUT"

echo ""
echo "Done! DMG saved to: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
