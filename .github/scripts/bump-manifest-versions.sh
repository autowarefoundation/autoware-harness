#!/usr/bin/env bash
set -euo pipefail

version="$1"

for manifest in \
    .claude-plugin/plugin.json \
    .codex-plugin/plugin.json \
    .cursor-plugin/plugin.json \
    .github/plugin/plugin.json; do
    tmp=$(mktemp)
    jq --arg v "$version" '.version = $v' "$manifest" >"$tmp"
    mv "$tmp" "$manifest"
done

tmp=$(mktemp)
jq --arg v "$version" \
    '.metadata.version = $v | .plugins[0].version = $v' \
    .github/plugin/marketplace.json >"$tmp"
mv "$tmp" .github/plugin/marketplace.json
