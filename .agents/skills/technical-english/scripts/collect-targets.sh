#!/usr/bin/env bash
#
# Collect the proofreading targets for the technical-english skill.
#
# Usage: collect-targets.sh [path ...]
#
#   With arguments, every Markdown file under the given paths is a whole-file
#   target. Without arguments, the targets come from the working tree: a file
#   with unstaged or untracked content is reviewed in full, and a file whose
#   only changes are staged is reviewed around its changed hunks.
#
# Output: one target per line, in one of two forms.
#
#   FULL <path>                 review the whole file
#   RANGE <path> <from>-<to>    review these 1-indexed lines only
#
# Set CONTEXT to widen or narrow the lines surrounding a staged hunk.

set -euo pipefail

CONTEXT="${CONTEXT:-5}"

list_markdown() {
    local target=$1
    if [[ -d $target ]]; then
        find "$target" -type f -name '*.md' \
            -not -path '*/node_modules/*' -not -path '*/.git/*' | sort
    elif [[ -f $target && $target == *.md ]]; then
        printf '%s\n' "$target"
    else
        printf 'collect-targets.sh: skipping non-Markdown target: %s\n' "$target" >&2
    fi
}

if (($# > 0)); then
    for target in "$@"; do
        while IFS= read -r file; do
            printf 'FULL %s\n' "$file"
        done < <(list_markdown "$target")
    done
    exit 0
fi

declare -A full_targets=()

while IFS= read -r file; do
    [[ -n $file ]] || continue
    full_targets["$file"]=1
    printf 'FULL %s\n' "$file"
done < <(
    {
        git --no-pager diff --name-only --diff-filter=d -- '*.md'
        git ls-files --others --exclude-standard -- '*.md'
    } | sort -u
)

while IFS= read -r file; do
    [[ -n $file ]] || continue
    # A file with unstaged content is already reported as a whole-file target.
    if [[ -v full_targets["$file"] ]]; then
        continue
    fi

    git --no-pager diff --cached --no-ext-diff -U"$CONTEXT" -- "$file" | awk -v file="$file" '
    /^@@/ {
      match($0, /\+[0-9]+(,[0-9]+)?/)
      split(substr($0, RSTART + 1, RLENGTH - 1), hunk, ",")
      start = hunk[1] + 0
      length_ = (2 in hunk) ? hunk[2] + 0 : 1
      if (length_ > 0) printf "RANGE %s %d-%d\n", file, start, start + length_ - 1
    }
  '
done < <(git --no-pager diff --cached --name-only --diff-filter=d -- '*.md' | sort -u)
