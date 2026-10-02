#!/usr/bin/env bash
# Builds FlashSpeak, installs it on a connected iPhone and launches it.
#
#   scripts/run-on-device.sh                # first connected iPhone, Debug
#   scripts/run-on-device.sh -c Release     # Release build (real paywall, live Worker)
#   scripts/run-on-device.sh -d "Vlad’s iPhone" -- -demo flashcards -demoLanguage ja
#
# Anything after `--` is passed to the app as launch arguments.
# Needs Xcode installed (not open), the phone unlocked, trusted and in
# Developer Mode.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION=Debug
DEVICE_NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c) CONFIGURATION="$2"; shift 2 ;;
    -d) DEVICE_NAME="$2"; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
LAUNCH_ARGS=("$@")

BUNDLE_ID=com.vladtamas.FlashSpeak
DERIVED_DATA=build/DerivedData
JSON=$(mktemp)
trap 'rm -f "$JSON"' EXIT

# Pick a connected iPhone (devicectl reports tunnelState "connected").
xcrun devicectl list devices --json-output "$JSON" >/dev/null
DEVICE=$(python3 - "$JSON" "$DEVICE_NAME" <<'PY'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
wanted = sys.argv[2]
for d in devices:
    name = d["deviceProperties"]["name"]
    connected = d.get("connectionProperties", {}).get("tunnelState") == "connected"
    is_phone = d["hardwareProperties"].get("deviceType") == "iPhone"
    if is_phone and connected and (not wanted or name == wanted):
        print(d["identifier"], d["hardwareProperties"]["udid"], name, sep="\t")
        break
PY
)
if [[ -z "$DEVICE" ]]; then
  echo "No connected iPhone found. Plug it in, unlock it and trust this Mac." >&2
  xcrun devicectl list devices >&2
  exit 1
fi
IFS=$'\t' read -r DEVICE_ID UDID NAME <<<"$DEVICE"
echo "▸ Building $CONFIGURATION for $NAME"

xcodebuild \
  -project FlashSpeak.xcodeproj \
  -scheme FlashSpeak \
  -configuration "$CONFIGURATION" \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  -quiet \
  build

APP="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos/FlashSpeak.app"
echo "▸ Installing"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP" >/dev/null

echo "▸ Launching"
xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID" ${LAUNCH_ARGS[@]+"${LAUNCH_ARGS[@]}"} >/dev/null
echo "✓ FlashSpeak is running on $NAME"
