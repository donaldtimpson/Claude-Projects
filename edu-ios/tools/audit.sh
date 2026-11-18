#!/usr/bin/env bash
# Design-review tour (Screenshots/AuditTests.swift) in light and dark at once, on two
# simulators, against production as the seeded review account.
# Usage: tools/audit.sh OUT_DIR [sections]   sections: courses,pushed,review,drills,progress
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$1"; ONLY="${2:-}"
LIGHT="${LIGHT_SIM:-Lyceum Design iPhone}"; DARK="${DARK_SIM:-iPhone 17 Pro}"
udid() { xcrun simctl list devices available | grep -F "$1 (" | head -1 | grep -oE '[0-9A-F-]{36}'; }
xcodebuild build-for-testing -project Lyceum.xcodeproj -scheme LyceumScreenshots -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$(udid "$LIGHT")" -derivedDataPath build/dd-audit 2>&1 | tail -1
run() {
  local id; id=$(udid "$1"); xcrun simctl boot "$id" 2>/dev/null || true
  xcrun simctl ui "$id" appearance "$2"; rm -rf "$OUT/$2"
  env TEST_RUNNER_AUDIT_DIR="$OUT/$2" TEST_RUNNER_AUDIT_ONLY="$ONLY" \
      TEST_RUNNER_REVIEW_EMAIL="${REVIEW_EMAIL:-appreview@timpsonlyceum.com}" \
      TEST_RUNNER_REVIEW_PASSWORD="${REVIEW_PASSWORD:-LyceumReview2026!}" \
    xcodebuild test-without-building -project Lyceum.xcodeproj -scheme LyceumScreenshots \
      -destination "platform=iOS Simulator,id=$id" -derivedDataPath build/dd-audit \
      -only-testing:LyceumScreenshots/AuditTests > "$OUT/$2.log" 2>&1 || true
  echo "$2: $(ls "$OUT/$2" 2>/dev/null | wc -l | tr -d ' ') shots"
}
mkdir -p "$OUT"
run "$LIGHT" light & run "$DARK" dark & wait
