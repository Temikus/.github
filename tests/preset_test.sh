#!/usr/bin/env bash
# Runs Renovate against a copy of tests/fixture and checks what default.json finds.
# Needs network and a GitHub token (GITHUB_COM_TOKEN, or `gh auth token`) for version lookups.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
eval "$(cd "$root" && mise env -s bash)"
export GITHUB_COM_TOKEN="${GITHUB_COM_TOKEN:-$(gh auth token)}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# Renovate's local platform lists files with git, so the fixture must be a repo.
cp -R "$root/tests/fixture/." "$work/repo"
git -C "$work/repo" init -q
git -C "$work/repo" add -A
git -C "$work/repo" -c user.name=test -c user.email=test@example.com commit -qm fixture

(cd "$work/repo" && LOG_LEVEL=debug LOG_FORMAT=json RENOVATE_CONFIG_FILE="$root/default.json" \
  renovate --platform=local --dry-run=lookup --require-config=ignored --onboarding=false) >"$work/log" 2>&1 || {
  tail -n 20 "$work/log" >&2
  exit 1
}

# One line per dependency: manager file packageName currentValue branch
deps=$(jq -r 'select(.msg == "packageFiles with updates") | .config | to_entries[] | .key as $m
  | .value[] | .packageFile as $f | .deps[]
  | "\($m) \($f) \(.packageName) \(.currentValue) \(.updates[0].branchName // "-")"' "$work/log")
echo "$deps"

rc=0
expect() {
  if grep -qE "$2" <<<"$deps"; then echo "PASS: $1"; else echo "FAIL: $1" >&2; rc=1; fi
}
expect_count() {
  local n
  n=$(grep -cE "$2" <<<"$deps" || true)
  if [ "$n" -eq "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1 (found $n)" >&2; rc=1; fi
}

expect "regex manager reads a workflow pin" '^regex \.github/workflows/ci\.yml betterleaks/betterleaks v1\.7\.3 '
expect "regex manager reads a justfile pin" '^regex justfile golang\.org/x/vuln v1\.7\.0 '
expect_count "setup-just version is tracked once" ' casey/just 1\.58\.0 ' 1
expect_count "betterleaks pins share one branch" 'betterleaks/betterleaks .* renovate/betterleaks$' 2
expect_count "golangci-lint pins share one branch" 'golangci/golangci-lint .* renovate/golangci-lint$' 2
expect "the lint action keeps its own branch" 'golangci/golangci-lint-action .* renovate/golangci-golangci-lint-action-'

exit "$rc"
