#!/bin/bash
# Installs this fork's audio driver and restarts Core Audio.
#
#   native/scripts/install-driver.sh [Release|Debug]     (default: Release)
#
# Only eqMacFork.driver is touched. The official eqMac's driver (eqMac.driver) is left
# alone, so both apps can stay installed. Requires an admin password.
set -euo pipefail

CONFIGURATION="${1:-Release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="$ROOT/native/build/Build/Products/$CONFIGURATION/eqMacFork.driver"
DEST="/Library/Audio/Plug-Ins/HAL/eqMacFork.driver"

if [ ! -d "$SOURCE" ]; then
  echo "error: $SOURCE not found. Build it first: native/scripts/build.sh $CONFIGURATION" >&2
  exit 1
fi

echo "Installing $SOURCE"
echo "        to $DEST"
sudo rm -rf "$DEST"
sudo cp -R "$SOURCE" "$DEST"
sudo chown -R root:wheel "$DEST"

# launchd restarts coreaudiod right away. (`launchctl kickstart` of coreaudiod is
# refused under SIP on recent macOS, so killall is the reliable way.)
echo "Restarting Core Audio; sound drops out for a moment."
sudo killall coreaudiod

echo "Done. Start eqMac: open \"$ROOT/native/build/Build/Products/$CONFIGURATION/eqMac.app\""
