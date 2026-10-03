#!/bin/bash
# Refresh the mirrored Anthropic Claude Code docs pages and re-record the manifest.
# Usage: ./fetch.sh [page ...]   (default: the list in PAGES below)
# Exit 0 only if every page returned HTTP 200 and every hash was recorded.
set -uo pipefail
cd "$(dirname "$0")"

BASE="https://code.claude.com/docs/en"
PAGES=(agent-teams sub-agents cross-session-messaging tools-reference)
[ $# -gt 0 ] && PAGES=("$@")

mkdir -p en
stamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tmp=$(mktemp)
fail=0

for p in "${PAGES[@]}"; do
  code=$(curl -sS --max-time 60 -w '%{http_code}' -o "en/$p.md" "$BASE/$p.md")
  if [ "$code" != "200" ]; then
    echo "FAIL  $p  HTTP=$code" >&2
    fail=1
    continue
  fi
  bytes=$(wc -c < "en/$p.md" | tr -d ' ')
  lines=$(wc -l < "en/$p.md" | tr -d ' ')
  sha=$(shasum -a 256 "en/$p.md" | cut -d' ' -f1)
  printf '%s  %s  bytes=%s lines=%s fetched=%s\n' "$sha" "en/$p.md" "$bytes" "$lines" "$stamp" >> "$tmp"
  printf 'ok    %-24s %s B  %s lines  %s\n' "$p" "$bytes" "$lines"
done

# Merge: drop the entries for pages re-fetched this run, keep the rest.
touch MANIFEST.txt
pat=$(printf '%s|' "en/${PAGES[0]}.md" "${PAGES[@]:1}" | sed 's/|$//')
grep -Ev " $pat " MANIFEST.txt > MANIFEST.keep 2>/dev/null || : > MANIFEST.keep
{ cat MANIFEST.keep; cat "$tmp"; } | sort -u -k2 > MANIFEST.new
mv MANIFEST.new MANIFEST.txt
rm -f MANIFEST.keep "$tmp"

echo "manifest: $(wc -l < MANIFEST.txt | tr -d ' ') entries, stamp $stamp"
exit $fail
