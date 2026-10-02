#!/usr/bin/env bash
# Rewrite only the "version" values in place so the rest of each file stays byte-identical.
set -euo pipefail

version="$1"

for manifest in \
    .claude-plugin/plugin.json \
    .codex-plugin/plugin.json \
    .cursor-plugin/plugin.json \
    .github/plugin/plugin.json \
    .github/plugin/marketplace.json; do
    sed -i -E "s/^([[:space:]]*\"version\":[[:space:]]*)\"[^\"]*\"/\1\"${version}\"/" "$manifest"
done
