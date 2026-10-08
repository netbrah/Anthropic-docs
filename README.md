# anthropic-docs

A local mirror of the published **Claude Code** documentation pages this campaign argues from, so a
claim about Claude Code behaviour can be checked against the vendor's own words without a browser.

```
en/*.md        Claude Code pages, verbatim as served (Markdown, Mintlify flavoured: <Warning>, <Frame>, ...)
platform/*.md  Claude Platform (API) pages, path kept below docs/en so the mirror path maps to the URL
MANIFEST.txt   sha256 + bytes + lines + UTC fetch stamp, per page
fetch.sh       re-fetch and re-record:  ./fetch.sh            (or: ./fetch.sh agent-teams platform/agents-and-tools/mcp-connector)
```

Two origins, two bases: `en/…` comes from `https://code.claude.com/docs/en` (Claude Code, dated by
`v2.1.NNN` notes in its prose), `platform/…` from `https://platform.claude.com/docs/en` (the API, which
never names a Claude Code version — it dates features by `_YYYYMMDD` `type` strings instead).

## What is mirrored, and why

| Page | Why it is here |
|---|---|
| `en/agent-teams.md` | The team/swarm subsystem: flag semantics, roster + mailbox + task-list layout, lead/teammate authority, limitations. Primary source for `plans/harness/agent-teams/`. |
| `en/sub-agents.md` | The surface teams are constantly confused with: subagent **names**, the sibling roster, resuming an agent with `SendMessage`. |
| `en/cross-session-messaging.md` | The third surface — sessions you run yourself, messaging each other with **no** team. |
| `en/tools-reference.md` | Tool-by-tool behaviour, incl. which models get `TaskCreate`/`TaskGet`/`TaskList`/`TaskUpdate` ("Task tool availability"), which decides who can use a shared task list at all. |
| `en/mcp.md` | Claude Code's MCP side of **tool search**: `Scale with MCP tool search`, `ENABLE_TOOL_SEARCH` (`true`/`auto`/`auto:N`/`false`), `alwaysLoad`, the `ToolSearch` tool, and the v2.1.221 / v2.1.227 notes. |
| `en/agent-sdk/tool-search.md` | The same mechanism as exposed to the Agent SDK: default-on, the 10 % `auto` threshold, the 10,000-tool cap, unsupported hosts. |
| `en/agent-sdk/mcp.md` | How the SDK decides the first-turn wait when tool search is on vs off, and `alwaysLoad` from the SDK side. |
| `platform/agents-and-tools/tool-use/tool-search-tool.md` | The API-side mechanism itself: `tool_search_tool_regex_20251119` / `tool_search_tool_bm25_20251119`, `defer_loading: true`, `tool_reference` expansion, limits, and the **Beta header: None** fact. |
| `platform/agents-and-tools/tool-use/manage-tool-context.md` | The closest thing the API docs have to an umbrella page: the four approaches (tool search, programmatic tool calling, prompt caching, context editing) and which slice of context pressure each removes. |
| `platform/agents-and-tools/tool-use/programmatic-tool-calling.md` | PTC: `allowed_callers`, requires `code_execution_20260120`+, frontmatter `status: ga`. Contains the only in-body "Advanced tool use" links. |
| `platform/agents-and-tools/tool-use/tool-reference.md` | Authoritative `type` ↔ Beta-header table for every Anthropic tool, plus the tool definition properties (`defer_loading`, `allowed_callers`, `strict`, `cache_control`). |
| `platform/agents-and-tools/tool-use/{overview,how-tool-use-works,define-tools,handle-tool-calls,server-tools,tool-combinations,strict-tool-use,fine-grained-tool-streaming,code-execution-tool,parallel-tool-use,tool-use-with-prompt-caching,troubleshooting-tool-use}.md` | The surrounding tool-use corpus, kept so a claim about what tool search composes with, what supersedes what, and which headers are still required can be checked without a browser. |
| `platform/agents-and-tools/mcp-connector.md` | The API-side MCP connector: `defer_loading` on `mcp_toolset` `default_config`/`configs`, `mcp-client-2025-11-20` vs the deprecated `mcp-client-2025-04-04`, and the `mcp-client-2026-09-15` tool-list pinning beta. |

More pages: `curl -L https://code.claude.com/docs/llms.txt` (232 entries, Claude Code) and
`curl -L https://platform.claude.com/llms.txt` (82 KB, the whole platform) are the full indexes the
pages themselves point at; add the slug to `PAGES` (Claude Code) or `PPAGES` (platform) in `fetch.sh`.
Note `platform.claude.com/docs/llms.txt` 308-redirects, so `curl` needs `-L`.

## Version caveat — read before citing

**These pages are the live docs, not a version-pinned snapshot.** `fetch.sh` records a *fetch time*,
not a product version, and the pages are only internally dated by the version notes in their own prose
(as fetched 2026-10-08, the newest note per Claude Code page is `tools-reference` v2.1.288,
`sub-agents` v2.1.286, `mcp` v2.1.284, `agent-teams` v2.1.281, `agent-sdk/mcp` v2.1.274,
`cross-session-messaging` v2.1.248, `agent-sdk/tool-search` v2.1.227). The `platform/` pages carry no
`v2.1.NNN` notes at all — the API docs date features by dated `type` strings
(`tool_search_tool_regex_20251119`, `code_execution_20260521`) and by `anthropic-beta` header dates, so
nothing in them can be checked against an installed Claude Code build.

Two consequences:

1. **A docs statement is not evidence about a specific installed build.** The corpus this campaign
   grades is the deobfuscated bundle at
   `~/Projects/claude/deobfuscation/out/versions/2.1.288/readable`. When docs and bundle disagree,
   say which one you are quoting — and check whether the docs are describing a newer build.
2. **The docs can be ahead of the bundle, and the bundle can contradict the docs.** Both directions
   have happened here; see `plans/harness/agent-teams/DOC-CORRECTIONS.md`.

The published docs are prose written for users. Where a claim is load-bearing, the bundle is the
stronger source — but the bundle is minified-then-renamed JS with no stable identifiers, so the docs
are the only practical way to learn *what to grep for*. Treat them as an index into the corpus, and as
authority only for product intent and for limits (the `Limitations` section is not derivable from the
bundle at all).

## Relationship to the other local sources

| Source | Strength | Weakness |
|---|---|---|
| These docs | current, canonical for product intent and documented limits | unpinned to a build; no implementation detail |
| `~/Projects/claude/deobfuscation/out/versions/<v>/readable` | pinned per version, byte-hashed, exact code | minified names; `fetch.sh`-style freshness is per-npm-release only |
| `~/Projects/claude/upstream/collection-claude-code-source-code` | readable **TypeScript**, real identifier names, so a gate or module is legible at a glance | **v2.1.88** — far older than the 2.1.288 we grade; third-party decompile, unverified provenance. Use it to learn a *shape*, then re-find it in the 2.1.288 bundle. Example: `src/utils/agentSwarmsEnabled.ts` there names the GrowthBook killswitch `tengu_amber_flint` that the 2.1.288 bundle also contains but only as `T("tengu_amber_flint", true)`. |
| `~/.claude/cache/changelog.md` | per-version user-visible behaviour and fixes | newest section is 2.1.287, so it does not describe 2.1.288 |
