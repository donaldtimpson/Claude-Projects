#!/usr/bin/env bash
# Restore the phonics clips into ios/Resources/Sounds from tools/sounds/clips.tar.enc.
# Needs the key at ~/.config/sound-it-out/sounds.key (or $SOUNDS_KEY) — copy it
# between your machines by hand (AirDrop, password manager); it is never committed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
sounds="$here/../../ios/Resources/Sounds"
key="${SOUNDS_KEY:-$HOME/.config/sound-it-out/sounds.key}"
[[ -f "$key" ]] || { echo "No key at $key — copy sounds.key from your other machine." >&2; exit 1; }
mkdir -p "$sounds"
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
# Decrypt fully first: a wrong key fails here, before anything is written.
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -in "$here/clips.tar.enc" -out "$tmp" -pass "file:$key" \
  || { echo "Decryption failed — wrong key?" >&2; exit 1; }
tar -xf "$tmp" -C "$sounds"
echo "restored $(ls "$sounds"/ph_*.m4a | wc -l | tr -d ' ') clips into ios/Resources/Sounds"
