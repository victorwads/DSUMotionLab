#!/bin/sh
set -eu
cd "$(dirname "$0")"
swift build -c release
BIN="$(swift build -c release --show-bin-path)"
APP="$PWD/dist/DSU Motion Lab.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/DSUMotionLab" "$APP/Contents/MacOS/DSUMotionLab"
ditto "$BIN/DSUMotionLab_DSUMotionLab.bundle" "$APP/Contents/Resources/DSUMotionLab_DSUMotionLab.bundle"
/usr/libexec/PlistBuddy -c "Clear dict" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string DSUMotionLab" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string dev.victorwads.dsumotionlab" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string DSU Motion Lab" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.1.0" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSLocalNetworkUsageDescription string Connect to phone motion servers on your local network." "$APP/Contents/Info.plist"
printf "Built: %s\n" "$APP"
