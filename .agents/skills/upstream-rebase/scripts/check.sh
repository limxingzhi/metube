#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

remote=$(ur_remote)
branch=$(ur_branch)
ref="$remote/$UR_UPSTREAM_BRANCH"

ur_fetch "$remote"
ur_git rev-parse --verify --quiet "$ref" >/dev/null ||
  ur_die "$ref does not exist after fetch"

behind=$(ur_git rev-list --count "HEAD..$ref")
ahead=$(ur_git rev-list --count "$ref..HEAD")

printf 'remote:    %s (%s)\n' "$remote" "$(ur_git remote get-url "$remote")"
printf 'branch:    %s\n' "$branch"
printf 'reference: %s\n' "$ref"
printf 'behind:    %s\n' "$behind"
printf 'ahead:     %s\n' "$ahead"

if [[ -n $(ur_git status --porcelain) ]]; then
  printf 'warning: working tree is not clean; rebase.sh will refuse until you commit or stash\n'
fi

if (( behind > 0 )); then
  printf '\nupstream commits missing from %s:\n' "$branch"
  ur_git log --oneline "HEAD..$ref"
  printf '\nrebase needed: %s upstream commit(s) missing\n' "$behind"
  exit 1
fi

printf '\n%s already contains every commit in %s\n' "$branch" "$ref"
exit 0
