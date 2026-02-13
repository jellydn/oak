#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOUNDS_DIR="$ROOT_DIR/Oak/Oak/Resources/Sounds"

required_tracks=(
  "ambient_rain"
  "ambient_forest"
  "ambient_cafe"
  "ambient_brown_noise"
  "ambient_lofi"
)

extensions=("m4a" "wav" "mp3")

if [[ ! -d "$SOUNDS_DIR" ]]; then
  echo "Missing sounds directory: $SOUNDS_DIR"
  exit 1
fi

missing=0

for track in "${required_tracks[@]}"; do
  found=0
  for ext in "${extensions[@]}"; do
    if [[ -f "$SOUNDS_DIR/$track.$ext" ]]; then
      found=1
      break
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    echo "Missing ambient track file: $track.{m4a|wav|mp3}"
    missing=1
  fi
done

if [[ "$missing" -eq 1 ]]; then
  echo "Ambient sound validation failed."
  exit 1
fi

echo "Ambient sound validation passed."
