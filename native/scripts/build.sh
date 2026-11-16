#!/bin/bash
# Builds the web UI, the audio driver and the app.
#
#   native/scripts/build.sh [Release|Debug]     (default: Release)
#
# Products end up in native/build/Build/Products/<Configuration>/:
#   eqMac.app          the app
#   eqMacFork.driver   the audio driver (install with native/scripts/install-driver.sh)
set -euo pipefail

CONFIGURATION="${1:-Release}"
case "$CONFIGURATION" in
  Release|Debug) ;;
  *) echo "usage: $0 [Release|Debug]" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NATIVE="$ROOT/native"
LOG_DIR="$NATIVE/build/script-logs"
mkdir -p "$LOG_DIR"

for tool in node npm pod xcodebuild; do
  command -v "$tool" >/dev/null || { echo "error: '$tool' not found. See BUILDING.md." >&2; exit 1; }
done

if [ ! -d "$ROOT/node_modules" ]; then
  echo "==> Installing JS dependencies"
  (cd "$ROOT" && npm ci --no-audit --no-fund)
fi

echo "==> Building UI"
(cd "$ROOT/ui" && npm run build) > "$LOG_DIR/ui.log" 2>&1 || {
  tail -30 "$LOG_DIR/ui.log"
  echo "error: UI build failed, full log: $LOG_DIR/ui.log" >&2
  exit 1
}

echo "==> Installing pods"
(cd "$NATIVE" && pod install) > "$LOG_DIR/pods.log" 2>&1 || {
  tail -30 "$LOG_DIR/pods.log"
  echo "error: pod install failed, full log: $LOG_DIR/pods.log" >&2
  exit 1
}

for SCHEME in "Driver - $CONFIGURATION" "eqMac"; do
  echo "==> Building $SCHEME ($CONFIGURATION)"
  LOG="$LOG_DIR/$(echo "$SCHEME" | tr -d ' ')-$CONFIGURATION.log"
  if ! xcodebuild \
      -workspace "$NATIVE/eqMac.xcworkspace" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -derivedDataPath "$NATIVE/build" \
      build > "$LOG" 2>&1; then
    grep -E "error:" "$LOG" | sort -u | head -30 >&2 || true
    echo "error: $SCHEME build failed, full log: $LOG" >&2
    exit 1
  fi
done

PRODUCTS="$NATIVE/build/Build/Products/$CONFIGURATION"
echo
echo "Built:"
echo "  $PRODUCTS/eqMac.app"
echo "  $PRODUCTS/eqMacFork.driver"
echo
echo "Next: native/scripts/install-driver.sh $CONFIGURATION   (once, and after driver changes)"
