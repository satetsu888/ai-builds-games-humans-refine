#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$PROJECT_DIR/build/web"

if [ ! -d "$WEB_DIR" ]; then
  echo "build/web not found: $WEB_DIR" >&2
  exit 1
fi

cd "$WEB_DIR"

TARGETS=(index.wasm index.js index.pck)
for f in "${TARGETS[@]}"; do
  if [ -f "$f" ]; then
    rm -f "$f.gz"
    gzip -k -9 "$f"
  fi
done

echo "Precompressed files:"
for f in "${TARGETS[@]}"; do
  if [ -f "$f" ] && [ -f "$f.gz" ]; then
    orig_bytes="$(stat -c '%s' "$f")"
    gz_bytes="$(stat -c '%s' "$f.gz")"
    echo "  $f -> $f.gz (${orig_bytes} -> ${gz_bytes} bytes)"
  fi
done
