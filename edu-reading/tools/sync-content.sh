#!/usr/bin/env bash
# content/reading/ is the source of truth for all six decks. The iOS app reads a
# bundled copy, so edit the source and run this. Same shape as content/grammar/,
# and it is what makes an Android port a copy rather than a rewrite.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cp "$root/content/reading/reading.json" "$root/edu-reading/ios/Resources/Content/reading.json"
echo "synced reading.json -> edu-reading/ios/Resources/Content/"
