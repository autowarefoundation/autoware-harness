#!/usr/bin/env python3
"""Validate the front matter of every SKILL.md against docs/format.md.

The central rule is the approval guardrail: a forked skill runs in a new
context and never receives user messages, so it cannot obtain user approval.
Such a skill must not hold a tool that can edit a file, or it edits before the
user ever sees the proposal.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_FIELDS = ("name", "description", "allowed-tools")

# Tools that can write to the working tree. Bare `Bash` counts, because an
# unrestricted shell can write any file; `Bash(git:*)` and friends do not.
MUTATING_TOOLS = frozenset({"Edit", "MultiEdit", "NotebookEdit", "Write", "Bash"})

NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def parse_front_matter(text: str) -> dict[str, str] | None:
    """Return the top-level scalar fields, or None when the block is missing.

    Only the fields this validator needs are scalars, so a block scalar body is
    skipped rather than parsed.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    try:
        end = next(i for i, line in enumerate(lines[1:], start=1) if line.strip() == "---")
    except StopIteration:
        return None

    fields: dict[str, str] = {}
    for line in lines[1:end]:
        if not line.strip() or line[0].isspace() or line.lstrip().startswith("#"):
            continue  # a block scalar body or a comment
        key, separator, value = line.partition(":")
        if not separator:
            continue
        fields[key.strip()] = value.strip()
    return fields


def split_tools(raw: str) -> list[str]:
    """Split a space-separated tool list, keeping `Tool(arg:*)` entries intact."""
    value = raw.strip()
    if value in ('""', "''", ""):
        return []
    if value[0] in "\"'" and value[-1] == value[0]:
        value = value[1:-1]
    return [tool for tool in re.findall(r"[^\s(]+(?:\([^)]*\))?", value) if tool]


def mutating(tools: list[str]) -> list[str]:
    return [tool for tool in tools if tool in MUTATING_TOOLS]


def check(path: Path) -> list[str]:
    fields = parse_front_matter(path.read_text(encoding="utf-8"))
    if fields is None:
        return ["front matter is missing or is not closed by a `---` line"]

    errors = []
    for field in REQUIRED_FIELDS:
        if field not in fields:
            errors.append(f"`{field}` is required (docs/format.md#front-matter)")

    name = fields.get("name", "")
    if name:
        if not NAME_PATTERN.match(name):
            errors.append(f"`name: {name}` must be kebab-case (docs/format.md#name)")
        if name != path.parent.name:
            errors.append(f"`name: {name}` must match its directory `{path.parent.name}`")

    if "allowed-tools" in fields:
        tools = split_tools(fields["allowed-tools"])
        forked = fields.get("context") == "fork"
        offenders = mutating(tools)
        if forked and offenders:
            errors.append(
                f"`context: fork` forbids the file-mutating tool(s) {', '.join(offenders)}. "
                "A forked skill cannot ask the user for approval, so it must return its "
                "findings and let the caller apply them "
                "(docs/format.md#approval-guardrail)"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()

    paths = args.paths or sorted(Path().rglob("SKILL.md"))
    failed = False
    for path in paths:
        for error in check(path):
            print(f"{path}: {error}", file=sys.stderr)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
