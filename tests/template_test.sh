#!/usr/bin/env bash
# Renders template/ with Copier into a scratch repo, then runs the shared recipes there.
# Offline: the scratch repo's origin is a local bare repo.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
eval "$(cd "$root" && mise env -s bash)"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
proj="$work/proj"

rc=0
pass() { echo "PASS: $1"; }
fail() {
  echo "FAIL: $1" >&2
  rc=1
}
# expect NAME EXIT_STATUS OUTPUT_REGEX COMMAND...
expect() {
  local name=$1 want=$2 pattern=$3 out status=0
  shift 3
  out=$("$@" 2>&1) || status=$?
  if [ "$status" -eq "$want" ] && grep -qE "$pattern" <<<"$out"; then
    pass "$name"
  else
    fail "$name (exit $status): $out"
  fi
}
pj() { just --justfile "$proj/justfile" --working-directory "$proj" "$@"; }

git init -q -b main "$proj"
# HEAD, not the latest tag, so a PR tests its own template.
copier copy --quiet --defaults --vcs-ref HEAD "$root" "$proj"

expect "common.just is copied byte for byte" 0 '' cmp "$root/template/just/common.just" "$proj/just/common.just"
expect "the answers file records the template commit" 0 '^_commit: ' cat "$proj/.copier-answers.yml"
expect "only template/ is rendered" 0 '' test ! -e "$proj/copier.yml" -a ! -e "$proj/template"

printf "set allow-duplicate-recipes\n\nimport 'just/common.just'\n" >"$proj/justfile"
expect "the import adds release" 0 '^ +release bump' pj --list
expect "the import adds sync-common" 0 '^ +sync-common' pj --list

git init -q --bare "$work/origin.git"
git -C "$proj" remote add origin "$work/origin.git"
git -C "$proj" add -A
git -C "$proj" commit -qm init
git -C "$proj" push -q origin main
git -C "$proj" tag -a v0.1.0 -m v0.1.0
git -C "$proj" push -q origin v0.1.0

git -C "$proj" checkout -q -b feature
expect "release refuses to run off main" 1 'Releases must run from main \(on: feature\)' pj release patch
git -C "$proj" checkout -q main

git -C "$proj" commit -q --allow-empty -m unpushed
expect "release refuses an unpushed commit" 1 'Local main differs from origin/main' pj release patch
git -C "$proj" push -q origin main

expect "release rejects an unknown bump" 1 'Usage: just release' pj release bogus
expect "release minor tags v0.2.0" 0 'Tagging v0.2.0 \(previous: v0.1.0\)' pj release minor
expect "the tag reaches origin" 0 'refs/tags/v0.2.0' git -C "$proj" ls-remote --tags origin v0.2.0

printf "\nrelease bump:\n    @echo local release {{ bump }}\n" >>"$proj/justfile"
expect "a repo's own release overrides the imported one" 0 '^local release patch$' pj release patch

exit "$rc"
