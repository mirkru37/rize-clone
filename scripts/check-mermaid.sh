#!/usr/bin/env bash
# Validate every fenced ```mermaid block in documentation/*.md by rendering it
# with the Mermaid CLI (mmdc). Requires Node/npx; mmdc is fetched on demand
# via `npx -y @mermaid-js/mermaid-cli`.
#
# Set MERMAID_NO_SANDBOX=1 to run mmdc's bundled Chromium with --no-sandbox
# (via a generated puppeteer config passed through -p). This is needed on
# CI runners (e.g. GitHub Actions ubuntu-latest) where unprivileged user
# namespaces are restricted by AppArmor and Chromium's own sandbox cannot
# start ("No usable sandbox!"). Local runs stay sandboxed by default.
#
# Exits non-zero and reports the offending file/block on any render failure.

set -euo pipefail

DOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/documentation"

if [[ ! -d "$DOC_DIR" ]]; then
  echo "check-mermaid: documentation directory not found at $DOC_DIR" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "check-mermaid: npx not found; Node.js is required" >&2
  exit 1
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

mmdc_extra_args=()
if [[ "${MERMAID_NO_SANDBOX:-0}" == "1" ]]; then
  puppeteer_config="$work_dir/puppeteer-config.json"
  printf '%s\n' '{"args": ["--no-sandbox"]}' > "$puppeteer_config"
  mmdc_extra_args=(-p "$puppeteer_config")
fi

failures=0
total=0

extract_mermaid_blocks() {
  # Prints each mermaid block's content, separated by a line containing
  # only "===BLOCK-END===", given a markdown file.
  awk '
    /^[[:space:]]*```mermaid[[:space:]]*$/ { inblock = 1; next }
    /^[[:space:]]*```[[:space:]]*$/ {
      if (inblock) { inblock = 0; print "===BLOCK-END===" }
      next
    }
    inblock { print }
  ' "$1"
}

while IFS= read -r -d '' file; do
  rel="${file#"$DOC_DIR"/}"
  block_num=0
  block_content=""

  while IFS= read -r line; do
    if [[ "$line" == "===BLOCK-END===" ]]; then
      block_num=$((block_num + 1))
      total=$((total + 1))
      in_file="$work_dir/${rel//\//_}.block${block_num}.mmd"
      out_file="$work_dir/${rel//\//_}.block${block_num}.svg"
      printf '%s' "$block_content" > "$in_file"

      if ! npx -y @mermaid-js/mermaid-cli -i "$in_file" -o "$out_file" "${mmdc_extra_args[@]+"${mmdc_extra_args[@]}"}" >"$work_dir/log.$block_num" 2>&1; then
        echo "mermaid render failed: documentation/${rel} block #${block_num}" >&2
        cat "$work_dir/log.$block_num" >&2
        failures=$((failures + 1))
      fi

      block_content=""
      continue
    fi
    block_content+="$line"$'\n'
  done < <(extract_mermaid_blocks "$file")
done < <(find "$DOC_DIR" -maxdepth 1 -name '*.md' -print0)

if [[ "$failures" -gt 0 ]]; then
  echo "check-mermaid: $failures of $total mermaid block(s) failed to render" >&2
  exit 1
fi

echo "check-mermaid: all $total mermaid block(s) render cleanly"
