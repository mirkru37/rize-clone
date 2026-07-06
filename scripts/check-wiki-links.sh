#!/usr/bin/env bash
# Verify every Obsidian-style [[wiki-link]] in documentation/*.md points at an
# existing documentation/<target>.md file.
#
# Rules:
#   - [[target]] and [[target|display text]] are checked.
#   - [[#Section]] (same-page anchor, no file target) is skipped.
#   - Fenced code blocks (``` ... ```) are stripped before scanning, so
#     Mermaid subroutine-shape node syntax like Foo[["Bar"]] never false-
#     positives as a wiki-link.
#
# Exits non-zero and lists every dangling link if any target file is missing.

set -euo pipefail

DOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/documentation"

if [[ ! -d "$DOC_DIR" ]]; then
  echo "check-wiki-links: documentation directory not found at $DOC_DIR" >&2
  exit 1
fi

failures=0

# Strip fenced code blocks (```...```) from a file, printing the remainder.
strip_fenced_code_blocks() {
  awk '
    /^[[:space:]]*```/ { infence = !infence; next }
    !infence { print }
  ' "$1"
}

while IFS= read -r -d '' file; do
  rel="${file#"$DOC_DIR"/}"

  # Extract wiki-link targets: [[target]] or [[target|display]].
  # grep -o gives us each match; we then strip the [[ ]] and any |display.
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue

    inner="${match#\[\[}"
    inner="${inner%\]\]}"
    target="${inner%%|*}"

    # Skip same-page anchors like [[#Conventions]].
    if [[ "$target" == \#* ]]; then
      continue
    fi

    # Strip any trailing #Anchor from a [[target#Anchor]] link.
    target="${target%%#*}"

    [[ -z "$target" ]] && continue

    target_path="$DOC_DIR/${target}.md"
    if [[ ! -f "$target_path" ]]; then
      echo "dangling wiki-link: [[${inner}]] in documentation/${rel} -> expected documentation/${target}.md" >&2
      failures=$((failures + 1))
    fi
  done < <(strip_fenced_code_blocks "$file" | grep -oE '\[\[[^][]+\]\]' || true)
done < <(find "$DOC_DIR" -maxdepth 1 -name '*.md' -print0)

if [[ "$failures" -gt 0 ]]; then
  echo "check-wiki-links: found $failures dangling wiki-link(s)" >&2
  exit 1
fi

echo "check-wiki-links: all wiki-links resolve"
