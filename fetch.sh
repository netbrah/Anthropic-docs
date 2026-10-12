#!/bin/bash
# Refresh the mirrored docs pages and re-record the manifest.
# Usage: ./fetch.sh [page ...]   (default: every entry in PAGES and PPAGES below)
#   a page is a slug from the lists below, or its manifest path (en/... or platform/...).
# Exit 0 only if every page returned HTTP 200 and every hash was recorded.
set -uo pipefail
cd "$(dirname "$0")"

BASE="https://code.claude.com/docs/en"       # Claude Code product docs  -> en/<slug>.md
PBASE="https://platform.claude.com/docs/en"  # Claude Platform (API) docs -> platform/<slug>.md

PAGES=(
  agent-teams
  sub-agents
  cross-session-messaging
  tools-reference
  mcp
  agent-sdk/tool-search
  agent-sdk/mcp
)

# Platform slugs keep their path below docs/en so the mirror path maps to the URL.
PPAGES=(
  agents-and-tools/tool-use/overview
  agents-and-tools/tool-use/how-tool-use-works
  agents-and-tools/tool-use/define-tools
  agents-and-tools/tool-use/handle-tool-calls
  agents-and-tools/tool-use/server-tools
  agents-and-tools/tool-use/tool-search-tool
  agents-and-tools/tool-use/manage-tool-context
  agents-and-tools/tool-use/programmatic-tool-calling
  agents-and-tools/tool-use/tool-combinations
  agents-and-tools/tool-use/tool-reference
  agents-and-tools/tool-use/strict-tool-use
  agents-and-tools/tool-use/fine-grained-tool-streaming
  agents-and-tools/tool-use/code-execution-tool
  agents-and-tools/tool-use/parallel-tool-use
  agents-and-tools/tool-use/tool-use-with-prompt-caching
  agents-and-tools/tool-use/troubleshooting-tool-use
  agents-and-tools/mcp-connector
)

targets=()
for p in "${PAGES[@]}";  do targets+=("en/$p.md|$BASE/$p.md"); done
for p in "${PPAGES[@]}"; do targets+=("platform/$p.md|$PBASE/$p.md"); done

if [ $# -gt 0 ]; then
  sel=()
  for a in "$@"; do
    a=${a%.md}
    for t in "${targets[@]}"; do
      case "${t%%|*}" in "$a.md"|*/"$a.md") sel+=("$t") ;; esac
    done
  done
  if [ ${#sel[@]} -eq 0 ]; then echo "no mirrored page matches: $*" >&2; exit 1; fi
  targets=("${sel[@]}")
fi

stamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tmp=$(mktemp)
fail=0

for t in "${targets[@]}"; do
  rel=${t%%|*}; url=${t#*|}
  mkdir -p "$(dirname "$rel")"
  code=$(curl -sS --max-time 60 -L -w '%{http_code}' -o "$rel" "$url")
  if [ "$code" != "200" ]; then
    echo "FAIL  $rel  HTTP=$code" >&2
    rm -f "$rel"
    fail=1
    continue
  fi
  bytes=$(wc -c < "$rel" | tr -d ' ')
  lines=$(wc -l < "$rel" | tr -d ' ')
  sha=$(shasum -a 256 "$rel" | cut -d' ' -f1)
  printf '%s  %s  bytes=%s lines=%s fetched=%s\n' "$sha" "$rel" "$bytes" "$lines" "$stamp" >> "$tmp"
  printf 'ok    %-58s %s B  %s lines\n' "$rel" "$bytes" "$lines"
done

# Merge: drop the entries for pages re-fetched this run, keep the rest.
touch MANIFEST.txt
pat=$(printf '%s\n' "${targets[@]}" | sed 's/|.*//; s/[][\.*^$/+]/\\&/g' | sort -u | paste -sd'|' -)
grep -Ev " ($pat) " MANIFEST.txt > MANIFEST.keep 2>/dev/null || : > MANIFEST.keep
{ cat MANIFEST.keep; cat "$tmp"; } | sort -u -k2 > MANIFEST.new
mv MANIFEST.new MANIFEST.txt
rm -f MANIFEST.keep "$tmp"

echo "manifest: $(wc -l < MANIFEST.txt | tr -d ' ') entries, stamp $stamp"
exit $fail
