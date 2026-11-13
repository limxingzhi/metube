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

# First done entry whose status is "finished" (not "error"); // empty turns
# a missing result into an empty string instead of the literal null.
url=$(jq -r '[.done[] | select(.status == "finished")][0].url // empty' <<<"$history")
if [ -z "$url" ]; then
  echo "no completed items"
  exit 0
fi

# jq -nc builds JSON from arguments instead of stdin; --arg escapes the URL
# safely. delete_files:false keeps the media file (unless the server is
# configured with DELETE_FILE_ON_TRASHCAN=true, which always deletes).
curl -fsS -X POST http://me/me/delete \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg id "$url" '{where: "done", ids: [$id], delete_files: false}')" >/dev/null

echo "cleared: $url"
