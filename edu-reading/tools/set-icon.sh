#!/usr/bin/env bash
# Swap the app icon for one of the candidates in edu-reading/icon/.
#   ./tools/set-icon.sh bubble
# Then rebuild. `./tools/set-icon.sh` with no argument lists what's available.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
dest="$root/ios/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

if [ $# -eq 0 ]; then
  echo "candidates (see icon/candidates.png for a side-by-side at home-screen size):"
  for f in "$root"/icon/*.png; do
    n="$(basename "$f" .png)"
    [ "$n" = "candidates" ] && continue
    echo "  $n"
  done
  exit 0
fi

src="$root/icon/$1.png"
[ -f "$src" ] || { echo "no such icon: $1"; exit 1; }
cp "$src" "$dest"
echo "app icon set to '$1' — rebuild to see it"
