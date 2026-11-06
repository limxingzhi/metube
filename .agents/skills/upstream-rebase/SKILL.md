---
name: upstream-rebase
description: Use when asked to check for alexta69/metube upstream changes, sync this fork with upstream, or rebase the current branch onto upstream/master. Fetches the upstream remote, reports divergence, and rebases only when asked.
---

# Upstream Rebase

Deterministic git procedure for keeping this fork based on `alexta69/metube`.
The scripts only fetch and rebase; they never push, force-push, or open a PR.
Run them from inside the checkout they should sync; they operate on the
repository root `git rev-parse --show-toplevel` reports.

## 1. Check

```bash
.agents/skills/upstream-rebase/scripts/check.sh
```

Read-only apart from `git fetch`.

- `behind` is the number of upstream commits the current branch is missing.
- `ahead` is the number of local commits that a rebase will replay on top of
  upstream.

| Exit code | Meaning |
| --------- | ------- |
| `0` | the branch already contains every upstream commit |
| `1` | upstream has commits the branch lacks; rebase needed |
| `2` | precondition or network error, message on stderr |

## 2. Rebase

Run this only when the user asked for the rebase, not on your own initiative:

```bash
.agents/skills/upstream-rebase/scripts/rebase.sh
```

The script refuses a dirty working tree, a detached HEAD, or an in-progress
rebase (exit `2`), fetches upstream, and replays the branch's local commits
onto `upstream/master`.

| Exit code | Meaning |
| --------- | ------- |
| `0` | rebase succeeded, or nothing was behind |
| `2` | precondition or network error; nothing changed |
| `3` | conflict; the rebase was aborted, the branch is unchanged, and the conflicting files were printed |

## Configuration

- `UPSTREAM_REMOTE` names the remote to use. Default: the first remote whose
  URL contains `alexta69/metube`, usually `upstream`.
- `UPSTREAM_BRANCH` overrides `master`.

## Rules

- Never push, force-push, or create a PR as part of this skill.
- On exit `3`, report the conflicting files and stop; do not try to resolve
  them inside the script. The user decides whether to rebase manually.
- After a successful rebase, run `check.sh` again and require exit `0` before
  reporting done.
