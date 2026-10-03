# anthropic-docs

A local mirror of the published **Claude Code** documentation pages this campaign argues from, so a
claim about Claude Code behaviour can be checked against the vendor's own words without a browser.

```
en/*.md       the pages, verbatim as served (Markdown, Mintlify flavoured: <Warning>, <Frame>, ...)
MANIFEST.txt  sha256 + bytes + lines + UTC fetch stamp, per page
fetch.sh      re-fetch and re-record:  ./fetch.sh            (or: ./fetch.sh agent-teams)
```

## What is mirrored, and why

| Page | Why it is here |
|---|---|
| `en/agent-teams.md` | The team/swarm subsystem: flag semantics, roster + mailbox + task-list layout, lead/teammate authority, limitations. Primary source for `plans/harness/agent-teams/`. |
| `en/sub-agents.md` | The surface teams are constantly confused with: subagent **names**, the sibling roster, resuming an agent with `SendMessage`. |
| `en/cross-session-messaging.md` | The third surface — sessions you run yourself, messaging each other with **no** team. |
| `en/tools-reference.md` | Tool-by-tool behaviour, incl. which models get `TaskCreate`/`TaskGet`/`TaskList`/`TaskUpdate` ("Task tool availability"), which decides who can use a shared task list at all. |

More pages: `curl https://code.claude.com/docs/llms.txt` is the full index the pages themselves point
at; add the slug to `PAGES` in `fetch.sh`.

## Version caveat — read before citing

**These pages are the live docs, not a version-pinned snapshot.** `fetch.sh` records a *fetch time*,
not a product version, and the pages are only internally dated by the version notes in their own prose
(as fetched 2026-10-03, the newest note per page is `agent-teams` v2.1.281, `sub-agents` v2.1.286,
`cross-session-messaging` v2.1.248, `tools-reference` v2.1.288).

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
