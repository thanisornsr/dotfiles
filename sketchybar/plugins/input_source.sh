#!/bin/sh

# Shows the current keyboard layout. Runs on the input_change event (see
# sketchybarrc) and once at startup.

ID=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)

case "$ID" in
  com.apple.keylayout.Thai*) LABEL="TH" ;;
  com.apple.keylayout.Swedish*) LABEL="SV" ;;
  com.apple.keylayout.US*|com.apple.keylayout.ABC*) LABEL="EN" ;;
  "") LABEL="??" ;;
  # Unknown layout: first two letters of its name, e.g. keylayout.German -> GE
  *) LABEL=$(echo "${ID##*.}" | cut -c1-2 | tr '[:lower:]' '[:upper:]') ;;
esac

sketchybar --set "$NAME" label="$LABEL"
