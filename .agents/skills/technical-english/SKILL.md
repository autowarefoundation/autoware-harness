---
description: |
  Use this skill when writing, reviewing, or proofreading English prose in the Markdown documentation of this repository, such as the readme, `docs/`, and `SKILL.md` files.
  It applies concise technical-writing conventions (voice, sentence structure, word choice, terminology, list and heading style) and reports rule-tagged findings with suggested rewrites before editing.
  Include the path to the Markdown files in the argument; when no path is given, review the Markdown files changed in the current diff.
name: technical-english
allowed-tools: Glob Grep Read Edit WebFetch
context: fork
---

# Technical English for documentation

Proofread Markdown documentation so that it reads as concise, unambiguous technical English.

The [Google developer documentation style guide](https://developers.google.com/style) is the single source of truth for the rules below. Consult it (`WebFetch`) whenever a case is not covered here.

Scope: Markdown prose in this repository — the readme, `docs/**/*.md`, and the `SKILL.md` and `references/*.md` files under `skills/`.
Out of scope: code comments, commit messages, and the schema rules of `.msg` / `.srv` / `.action` field comments, which belong to `awh-interface-msg-format`.

The `pre-commit` hooks already run `textlint`, `markdownlint`, and `prettier`, so mechanical issues are fixed outside this skill. Review only what those hooks cannot judge.

## Table of contents

- [Workflow](#workflow) — how to review and when to edit
- [Rule set](#rule-set) — the checks to apply, each with a rule ID
- [references/rewrites.md](./references/rewrites.md) — before/after examples per rule ID
- [references/terminology.md](./references/terminology.md) — preferred word choices and words to avoid

## Workflow

1. Resolve the targets.
   - Argument given: treat it as a path or glob and collect `*.md` under it.
   - No argument: review the Markdown files changed in the working tree.

   ```bash
   git diff --name-only --diff-filter=d HEAD -- '*.md'
   ```

2. Read each target in full. Judge prose only — never restructure the document or change its technical claims.
3. Report findings as a table, one row per finding, most impactful first.

   ```text
   | File:line | Rule | Current | Suggested |
   | --------- | ---- | ------- | --------- |
   ```

   - Cite the rule ID from [Rule set](#rule-set) so the author can see the reasoning.
   - Leave a finding out when the rewrite does not clearly improve clarity. Prefer few, high-confidence findings over an exhaustive list.
   - Do not report findings inside fenced code blocks, inline code spans, URLs, or link targets.

4. Ask the user which findings to apply. Apply them with `Edit` only after approval, and change nothing else.

<!-- TODO: decide whether the report should also be writable as a review comment on the PR, and how. -->

## Rule set

Each rule has a stable ID so findings stay traceable. Full before/after examples live in [references/rewrites.md](./references/rewrites.md).

### Voice and mood

- `V1` Use active voice in instructions and explanations. Name the actor instead of leaving a passive subject implicit. Passive voice is acceptable in specifications, where the actor is genuinely irrelevant.
- `V2` Address the reader as "you". Do not use "we" for instructions, and do not use "the user" when the reader is meant.
- `V3` Write instructions in the imperative mood.
- `V4` Use present tense. Avoid "will" for behavior that is always true.

### Sentences

- `S1` One idea per sentence. Split sentences that chain clauses with "and", "but", or a semicolon.
- `S2` Delete filler openings such as "Note that", "It should be noted that", "Basically", "Simply", "In order to" (use "to").
- `S3` Put the condition before the instruction: "If X, do Y", not "Do Y if X".
- `S4` Avoid nominalization. Prefer the verb ("configure") over the noun phrase ("perform the configuration of").
- `S5` Do not use "please" in instructions.

<!-- TODO: add a sentence-length guideline once the maintainers agree on a concrete limit. -->

### Word choice

- `W1` Use one term consistently for one concept throughout a document. See [references/terminology.md](./references/terminology.md). For Autoware domain terms, defer to the glossary skill.
- `W2` Avoid ambiguous pronouns. Replace "it", "this", and "these" with the noun they refer to when the referent is not adjacent.
- `W3` Avoid unnecessary jargon, idioms, and culture-specific metaphors — many readers are not native English speakers.
- `W4` Avoid absolutes such as "easy", "simple", "just", "obviously", which judge the reader's experience.
- `W5` Expand an abbreviation at its first use in a document, then use the abbreviation.

### Structure and formatting

- `L1` Keep list items parallel in grammatical form, and either all sentences or all fragments.
- `L2` Use a numbered list only for ordered steps; use a bullet list otherwise.
- `H1` Use sentence case for headings, and phrase them as noun phrases or gerunds, not full sentences.
- `H2` Do not skip heading levels, and do not leave a heading immediately followed by another heading with no prose.
- `C1` Mark identifiers, paths, commands, and literal values as inline code.
- `C2` Introduce a code block with a sentence that states what it does, and tag the block with its language.
- `C3` Use descriptive link text. Do not use "here" or a bare URL as link text.

<!-- TODO: record project decisions on Oxford comma, en/em dash usage, and whether one-sentence-per-line Markdown is required. -->
