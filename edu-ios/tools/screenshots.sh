#!/usr/bin/env bash
# Captures the App Store Connect screenshot set on both required display sizes.
#
# App Store Connect asks for one set at 6.9" iPhone (1320x2868) and, because
# Lyceum ships universal, one at 13" iPad (2064x2752). It scales those down for
# every smaller device itself, so these two are all that's needed.
#
# The app signs into the seeded review account on production, so the shots show
# real courses with real progress. Seed it first, from edu-web:
#   npx tsx scripts/seed-review-account.ts
#
# Usage: tools/screenshots.sh [output-dir]
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="${1:-$PWD/build/screenshots}"
export REVIEW_EMAIL="${REVIEW_EMAIL:-appreview@timpsonlyceum.com}"
export REVIEW_PASSWORD="${REVIEW_PASSWORD:-LyceumReview2026!}"
export API_BASE_URL="${API_BASE_URL:-https://timpson-lyceum.vercel.app}"

# slug:device-name-prefix pairs, one per required display size. The prefix is
# matched against the installed simulators and the newest runtime wins, so this
# survives Xcode updates renaming the current top-end device.
DEVICES=(
  "iphone-6.9:iPhone|Pro Max"
  "ipad-13:iPad Pro 13-inch"
)

# Newest simulator whose name matches both patterns -> "udid<TAB>name (iOS x.y)".
resolve_sim() {
  xcrun simctl list devices available --json | python3 -c '
import json, re, sys
pats = sys.argv[1].split("|")
runtime_key = lambda r: [int(n) for n in re.findall(r"\d+", r)] or [0]
best = None
data = json.load(sys.stdin)["devices"]
for runtime, devices in data.items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if all(p.lower() in d["name"].lower() for p in pats):
            key = runtime_key(runtime)
            if best is None or key > best[0]:
                best = (key, d["udid"], d["name"], runtime.split(".")[-1])
if not best:
    sys.exit(1)
print(f"{best[1]}\t{best[2]} ({best[3]})")
' "$1"
}

xcodegen generate >/dev/null

for entry in "${DEVICES[@]}"; do
  slug="${entry%%:*}"
  pattern="${entry#*:}"

  if ! sim=$(resolve_sim "$pattern"); then
    echo "==> $slug: no installed simulator matches '$pattern' — skipping" >&2
    continue
  fi
  udid="${sim%%$'\t'*}"
  device="${sim#*$'\t'}"

  dir="$OUT/$slug"
  rm -rf "$dir"
  mkdir -p "$dir"

  echo "==> $device -> $dir"
  # SCREENSHOT_DIR reaches the test process through TEST_RUNNER_-prefixed vars.
  env TEST_RUNNER_SCREENSHOT_DIR="$dir" \
      TEST_RUNNER_REVIEW_EMAIL="$REVIEW_EMAIL" \
      TEST_RUNNER_REVIEW_PASSWORD="$REVIEW_PASSWORD" \
      TEST_RUNNER_API_BASE_URL="$API_BASE_URL" \
    xcodebuild test \
      -project Lyceum.xcodeproj \
      -scheme LyceumScreenshots \
      -sdk iphonesimulator \
      -destination "platform=iOS Simulator,id=$udid" \
      -resultBundlePath "$dir/result.xcresult" \
      2>&1 | tail -5

  rm -rf "$dir/result.xcresult"
  count=$(find "$dir" -name "*.png" | wc -l | tr -d ' ')
  echo "    $count screenshots"
  for f in "$dir"/*.png; do
    [ -e "$f" ] || continue
    printf "    %-28s %s\n" "$(basename "$f")" \
      "$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{printf "%s ", $2}')"
  done
done

echo
echo "Done. Upload from $OUT"
