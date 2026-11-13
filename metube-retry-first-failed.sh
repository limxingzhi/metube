#!/usr/bin/env bash
# -e: stop on errors, -u: error on unset vars, -o pipefail: a failed jq/curl in a pipe fails the script.
set -euo pipefail

# GET /history returns JSON: {"done":[...], "queue":[...], "pending":[...]}
history=$(curl -fsS http://me/me/history)

# Header row: %-8s / %-14s are left-aligned (-) string fields (s) padded to
# 8 and 14 characters, so the columns line up.
printf '%-8s %-14s %s\n' BUCKET STATUS TITLE

# Build one tab-separated line per item (@tsv), then read it back tab by tab.
# IFS=$'\t' splits on tabs only; read -r keeps backslashes literal.
jq -r '
  (.done[]    | ["done",    .status, .title]),
  (.queue[]   | ["queue",   .status, .title]),
  (.pending[] | ["pending", .status, .title])
  | @tsv' <<<"$history" | while IFS=$'\t' read -r bucket state title; do
  printf '%-8s %-14s %s\n' "$bucket" "$state" "$title"
done

# First done entry whose status is "error" (not "finished"); // empty turns
# a missing result into an empty string instead of the literal null.
url=$(jq -r '[.done[] | select(.status == "error")][0].url // empty' <<<"$history")
if [ -z "$url" ]; then
  echo "no failed items"
  exit 0
fi

# jq -nc builds JSON from arguments instead of stdin; --arg escapes the URL
# safely. The retry endpoint takes a single id: it re-extracts the URL, and
# its response reports per-item success, so check the reported status.
response=$(curl -fsS -X POST http://me/me/retry \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg id "$url" '{id: $id}')")

if [ "$(jq -r '.status // empty' <<<"$response")" != "ok" ]; then
  echo "retry failed: $(jq -r '.msg // "unknown error"' <<<"$response")"
  exit 1
fi

echo "retried: $url"
