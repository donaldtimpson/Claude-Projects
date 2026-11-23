#!/usr/bin/env bash
# Pack + encrypt the app's phonics clips (ios/Resources/Sounds/ph_*.m4a) into
# tools/sounds/clips.tar.enc, which IS committed. The clips themselves are not:
# they're Phonicademy's (licence forbids publishing them as a file collection), and
# the repo is public. The key never goes in git — see decrypt.sh for where it lives.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
sounds="$here/../../ios/Resources/Sounds"
key="${SOUNDS_KEY:-$HOME/.config/sound-it-out/sounds.key}"
if [[ ! -f "$key" ]]; then
  mkdir -p "$(dirname "$key")"; umask 077
  openssl rand -base64 32 > "$key"
  echo "Created a new key at $key — copy it to your other machine (same path)."
fi
ls "$sounds"/ph_*.m4a >/dev/null
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
# Deterministic archive (sorted names, fixed owner/mtime) so an unchanged set re-encrypts to the same plaintext.
(cd "$sounds" && ls ph_*.m4a | sort | tar --uid 0 --gid 0 --uname "" --gname "" -cf "$tmp" -T -)
openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -in "$tmp" -out "$here/clips.tar.enc" -pass "file:$key"
echo "encrypted $(ls "$sounds"/ph_*.m4a | wc -l | tr -d ' ') clips -> tools/sounds/clips.tar.enc"
