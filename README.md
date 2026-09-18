# Anthropic-docs

Unofficial Markdown mirror of Anthropic's first-party developer documentation,
generated from the official `llms.txt` indexes.

The snapshot is reproducible:

```bash
python scripts/sync_docs.py
```

The sync combines the Claude Platform documentation, including the complete
“Build with Claude” hierarchy, with the separate Claude Code documentation.
Raw indexes are retained under `indexes/` and English Markdown pages are stored
under `docs/<host>/` with their URL paths preserved.

This repository is not affiliated with or endorsed by Anthropic.
