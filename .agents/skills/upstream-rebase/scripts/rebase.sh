#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

remote=$(ur_remote)
branch=$(ur_branch)
ref="$remote/$UR_UPSTREAM_BRANCH"

[[ -z $(ur_git status --porcelain) ]] ||
  ur_die 'working tree is not clean; commit or stash first'
ur_require_no_rebase
ur_fetch "$remote"
ur_git rev-parse --verify --quiet "$ref" >/dev/null ||
  ur_die "$ref does not exist after fetch"

behind=$(ur_git rev-list --count "HEAD..$ref")
ahead=$(ur_git rev-list --count "$ref..HEAD")

if (( behind == 0 )); then
  printf '%s is already based on %s (%s local commit(s) ahead)\n' "$branch" "$ref" "$ahead"
  exit 0
fi

pre=$(ur_git rev-parse HEAD)
printf 'rebasing %s onto %s; %s local commit(s) will be replayed (pre-rebase HEAD %s)\n' \
  "$branch" "$ref" "$ahead" "${pre:0:12}"

if ur_git rebase "$ref"; then
  printf '\nrebased onto %s; local commits on top:\n' "$ref"
  ur_git log --oneline "$ref..HEAD"
  exit 0
fi

conflicts=$(ur_git diff --name-only --diff-filter=U || true)
ur_git rebase --abort >/dev/null 2>&1 || true
printf 'rebase hit conflicts and was aborted; %s is back at %s\n' "$branch" "${pre:0:12}" >&2
if [[ -n $conflicts ]]; then
  printf 'conflicting files:\n%s\n' "$conflicts" >&2
fi
printf 'rebase manually to resolve them: git rebase %s\n' "$ref" >&2
exit 3
