#!/bin/bash

set -xe

# Build the `.app` bundle using Swift CLI

swift build -c release
EXEC_PATH=$(swift build -c release --show-bin-path)/Penguin

mkdir -p build
pushd build
rm -rf Penguin.app

mkdir -p Penguin.app/Contents/MacOS
mkdir -p Penguin.app/Contents/Resources

cat > Penguin.app/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Penguin</string>
    <key>CFBundleIdentifier</key>
    <string>com.penguin</string>
    <key>CFBundleName</key>
    <string>Penguin</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>PenguinIcon</string>
</dict>
</plist>
EOF


rm -rf PenguinIcon.iconset
mkdir -p PenguinIcon.iconset

sips -z 16 16     ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_16x16.png
sips -z 32 32     ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_16x16@2x.png
sips -z 32 32     ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_32x32.png
sips -z 64 64     ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_32x32@2x.png
sips -z 128 128   ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_128x128.png
sips -z 256 256   ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_128x128@2x.png
sips -z 256 256   ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_256x256.png
sips -z 512 512   ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_256x256@2x.png
sips -z 512 512   ../Penguin/Resources/penguin_1024.png --out PenguinIcon.iconset/icon_512x512.png
cp                ../Penguin/Resources/penguin_1024.png PenguinIcon.iconset/icon_512x512@2x.png
iconutil -c icns PenguinIcon.iconset
mv PenguinIcon.icns Penguin.app/Contents/Resources/


cp $EXEC_PATH Penguin.app/Contents/MacOS/
chmod +x Penguin.app/Contents/MacOS/Penguin

codesign --deep --force --sign - Penguin.app
