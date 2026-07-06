#!/usr/bin/env bash
# Claude Code PostToolUse hook: after a `git commit` invocation anywhere in
# this monorepo (master repo or any submodule), run that repo's fast CI
# checks and fail loudly (stderr + exit 2) so Claude sees and fixes issues.
#
# Reads the PostToolUse hook payload as JSON on stdin, using fields:
#   .tool_input.command  - the Bash command that was run
#   .cwd                 - the working directory it ran in
#
# Non-commit commands, or any command that isn't `git commit`, are a
# silent no-op (exit 0). Checks are intentionally fast: no tests, no docker.

set -uo pipefail

payload="$(cat)"

extract_json_field() {
  # $1 = payload, $2 = field name (top-level or dotted "tool_input.command")
  local payload="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r --arg f "$field" '
      def getpath2($f):
        ($f | split(".")) as $parts
        | reduce $parts[] as $p (.; if . == null then null else .[$p] end);
      getpath2($f) // empty
    '
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$field" <<PYEOF
import json, sys
field = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cur = data
for part in field.split("."):
    if not isinstance(cur, dict) or part not in cur:
        cur = None
        break
    cur = cur[part]
if cur is not None:
    print(cur)
PYEOF
  else
    echo "post-commit-ci: neither jq nor python3 available, cannot parse hook input" >&2
    exit 0
  fi
}

command_str="$(extract_json_field "$payload" "tool_input.command")"
cwd="$(extract_json_field "$payload" "cwd")"

if [[ -z "$command_str" ]]; then
  exit 0
fi

# Match a `git commit` invocation as a distinct subcommand (avoid false
# positives like `git commit-tree` or commands merely mentioning "commit").
if ! printf '%s' "$command_str" | grep -Eq '(^|[;&|]|[[:space:]])git([[:space:]]+-[A-Za-z0-9=._/-]+)*[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

if [[ -z "$cwd" ]]; then
  cwd="$(pwd)"
fi

if ! repo_root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "post-commit-ci: '$cwd' is not inside a git repo, skipping" >&2
  exit 0
fi

repo_name="$(basename "$repo_root")"

fail=0
run_output=""

# Runs "$@" inside $repo_root, printing its combined output on failure and
# setting the shared $fail flag. Not run in a subshell so $fail is visible
# to the caller.
run_check() {
  local desc="$1"
  shift
  echo "post-commit-ci: running $desc in $repo_root" >&2
  local output
  if ! output="$(cd "$repo_root" && "$@" 2>&1)"; then
    echo "post-commit-ci: FAILED - $desc" >&2
    echo "$output" >&2
    fail=1
  fi
}

case "$repo_name" in
  rize-backend)
    run_check "go build ./..." go build ./...
    if command -v golangci-lint >/dev/null 2>&1; then
      run_check "golangci-lint run" golangci-lint run
    else
      echo "post-commit-ci: warning - golangci-lint not installed, skipping lint" >&2
    fi
    ;;
  rize-desktop|rize-mobile)
    if command -v swiftlint >/dev/null 2>&1; then
      run_check "swiftlint --strict" swiftlint --strict
    else
      echo "post-commit-ci: warning - swiftlint not installed, skipping lint" >&2
    fi
    ;;
  *)
    # Master repo (or anything else): docs checks.
    run_check "markdownlint-cli2" npx -y markdownlint-cli2
    if [[ -x "$repo_root/scripts/check-wiki-links.sh" ]]; then
      run_check "check-wiki-links.sh" "$repo_root/scripts/check-wiki-links.sh"
    fi
    ;;
esac

if [[ "$fail" -ne 0 ]]; then
  exit 2
fi

exit 0
