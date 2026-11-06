#!/usr/bin/env bash
set -euo pipefail

UR_UPSTREAM_BRANCH=${UPSTREAM_BRANCH:-master}

ur_die() {
  printf 'error: %s\n' "$*" >&2
  exit 2
}

if ! UR_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  ur_die 'not inside a git repository; run from the checkout you want to sync'
fi

ur_git() {
  git -C "$UR_REPO_ROOT" "$@"
}

ur_remote() {
  local requested=${UPSTREAM_REMOTE:-}
  local name url
  if [[ -n $requested ]]; then
    ur_git remote get-url "$requested" >/dev/null 2>&1 ||
      ur_die "remote '$requested' does not exist"
    printf '%s\n' "$requested"
    return 0
  fi
  while IFS= read -r name; do
    url=$(ur_git remote get-url "$name")
    if [[ $url == *alexta69/metube* ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(ur_git remote)
  ur_die "no remote points at alexta69/metube; add one with: git remote add upstream https://github.com/alexta69/metube.git"
}

ur_branch() {
  ur_git symbolic-ref --quiet --short HEAD ||
    ur_die 'HEAD is detached; check out a branch first'
}

ur_fetch() {
  local remote=$1
  GIT_TERMINAL_PROMPT=0 ur_git fetch --prune "$remote" ||
    ur_die "git fetch $remote failed; check network access and the remote URL"
}

ur_git_path() {
  local path
  path=$(ur_git rev-parse --git-path "$1")
  if [[ $path == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$UR_REPO_ROOT/$path"
  fi
}

ur_require_no_rebase() {
  local state
  for state in rebase-merge rebase-apply; do
    if [[ -e $(ur_git_path "$state") ]]; then
      ur_die "a rebase is already in progress; finish it with git rebase --continue or git rebase --abort"
    fi
  done
}
