#!/bin/bash
# Apple Silicon, Xcode, and a booted iPhone simulator required. Does not load
# Eagle's access engine or change any device/system theme.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:?Pass the UUID of a booted simulator}"
QA_DIR="$(mktemp -d /private/tmp/eagle-notification-qa.XXXXXX)"
trap 'rm -rf "$QA_DIR"' EXIT
APP="$QA_DIR/NotificationPreview.app"
mkdir -p "$APP"
cp -X "$ROOT/scripts/NotificationPreview-Info.plist" "$APP/Info.plist"
xcrun --sdk iphonesimulator swiftc \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios16.0-simulator -parse-as-library \
  "$ROOT/lara/views/new/EagleDynamicNotification.swift" \
  "$ROOT/lara/views/new/EagleNotificationMorph.swift" \
  "$ROOT/scripts/NotificationPreview.swift" -o "$APP/NotificationPreview"
codesign --force --sign - "$APP"
xcrun simctl install "$DEVICE" "$APP"
# Prints PASS after approximately 20 seconds; remains open for visual QA.
# Ctrl-C detaches the console without uninstalling the harness.
xcrun simctl launch --terminate-running-process --console "$DEVICE" dev.eagle.notification-preview
