#!/usr/bin/env python3
"""Mirror Anthropic's first-party English Markdown documentation."""

from __future__ import annotations

import concurrent.futures as cf
import pathlib
import re
import shutil
import sys
import urllib.parse
import urllib.request

ROOT_INDEXES = (
    "https://platform.claude.com/llms.txt",
    "https://code.claude.com/docs/llms.txt",
)
ALLOWED_HOSTS = {"platform.claude.com", "code.claude.com"}
REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
INDEXES_DIR = REPO_ROOT / "indexes"
LINK_RE = re.compile(r"\]\((https?://[^)\s]+)\)|(?<!\()(?P<bare>https?://[^\s<>`)]+)")
USER_AGENT = "Anthropic-docs-sync/1.0 (+https://github.com/netbrah/Anthropic-docs)"
TIMEOUT = 60
MAX_WORKERS = 12


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return response.read()


def links(text: str) -> list[str]:
    found = []
    for match in LINK_RE.finditer(text):
        url = match.group(1) or match.group("bare")
        found.append(url.rstrip(".,;:"))
    return list(dict.fromkeys(found))


def local_path(root: pathlib.Path, url: str) -> pathlib.Path:
    parsed = urllib.parse.urlparse(url)
    path = parsed.path.lstrip("/") or "index"
    return root / parsed.netloc / path


def is_english_page(url: str) -> bool:
    path = urllib.parse.urlparse(url).path
    if path.startswith("/docs/_llms/"):
        return False
    return path.startswith("/docs/en/") or urllib.parse.urlparse(url).netloc == "code.claude.com"


def sync_page(url: str) -> tuple[str, int]:
    data = fetch(url)
    destination = local_path(DOCS_DIR, url)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    return url, len(data)


def main() -> int:
    indexes: dict[str, bytes] = {}
    pages: set[str] = set()
    for url in ROOT_INDEXES:
        data = fetch(url)
        indexes[url] = data
        for candidate in links(data.decode("utf-8", errors="replace")):
            parsed = urllib.parse.urlparse(candidate)
            if (
                parsed.netloc in ALLOWED_HOSTS
                and parsed.path.endswith(".md")
                and is_english_page(candidate)
            ):
                pages.add(candidate)

    pages = set(sorted(pages))
    print(f"Discovered {len(indexes)} indexes and {len(pages)} English Markdown pages")
    shutil.rmtree(DOCS_DIR, ignore_errors=True)
    shutil.rmtree(INDEXES_DIR, ignore_errors=True)
    for url, data in indexes.items():
        destination = local_path(INDEXES_DIR, url)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)

    errors = []
    total = 0
    with cf.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(sync_page, url): url for url in pages}
        for future in cf.as_completed(futures):
            try:
                _, size = future.result()
                total += size
            except Exception as exc:  # noqa: BLE001
                errors.append((futures[future], str(exc)))
                print(f"! {futures[future]}: {exc}", file=sys.stderr)

    print(f"Wrote {len(pages) - len(errors)}/{len(pages)} pages ({total / 1048576:.1f} MiB)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
