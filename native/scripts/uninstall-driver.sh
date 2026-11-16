#!/bin/bash
# Removes this fork's audio driver and restarts Core Audio.
# The official eqMac's driver (eqMac.driver) is not touched. Requires an admin password.
set -euo pipefail

DEST="/Library/Audio/Plug-Ins/HAL/eqMacFork.driver"

if [ ! -d "$DEST" ]; then
  echo "$DEST is not installed; nothing to do."
  exit 0
fi

echo "Removing $DEST"
sudo rm -rf "$DEST"
echo "Restarting Core Audio; sound drops out for a moment."
sudo killall coreaudiod
echo "Done."
