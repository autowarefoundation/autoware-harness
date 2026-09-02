---
description: |
  Use this skill when writing, reviewing, or proofreading English prose in the Markdown documentation of this repository, such as the readme, the files under `docs/`, and `SKILL.md` files.
  It applies concise technical-writing conventions (reader persona, voice, sentence structure, word choice, terminology, list and heading style) and reports rule-tagged findings with suggested rewrites before editing.
  Include the path to the Markdown files in the argument; when no path is given, the skill reviews the Markdown files changed in the working tree.
name: technical-english
allowed-tools: Bash(bash:*) Bash(git:*) Glob Grep Read Edit WebFetch
context: fork
---

# Technical English for documentation

Proofread Markdown documentation so that it reads as concise, unambiguous technical English.

The [Google developer documentation style guide](https://developers.google.com/style) is the single source of truth for the rules below. Consult the guide with `WebFetch` whenever a case is not covered here.

- Scope: Markdown prose in this repository — the readme, `docs/**/*.md`, and the `SKILL.md` and `references/*.md` files under `skills/`.
- Out of scope: Other types of files, and fenced code blocks, inline code spans, URLs, or link targets inside Markdown.

The `pre-commit` hooks already run `textlint`, `markdownlint`, and `prettier`, so the hooks fix mechanical issues before this skill runs. Review only what those hooks cannot judge.

## Table of contents

- [Workflow](#workflow) — how to collect the targets, review, and edit
- [Rule set](#rule-set) — the checks to apply, each with a rule ID
- [references/rewrites.md](./references/rewrites.md) — before/after examples per rule ID
- [references/terminology.md](./references/terminology.md) — preferred word choices and words to avoid
- [scripts/collect-targets.sh](./scripts/collect-targets.sh) — resolves which files and line ranges to review

## Workflow

1. Collect the targets with the helper script, so that the same input always yields the same review scope.

   ```bash
   bash scripts/collect-targets.sh [path ...]
   ```

   Each output line is one target in one of two forms.

   | Line                       | Meaning                               |
   | -------------------------- | ------------------------------------- |
   | `FULL <path>`              | Proofread the whole file.             |
   | `RANGE <path> <from>-<to>` | Proofread these 1-indexed lines only. |

   The script resolves the scope as follows.

   - Arguments given: every Markdown file under those paths is a `FULL` target.
   - No arguments given:
     - A file with unstaged changes or untracked content is a `FULL` target, because its content is still in flux.
     - A file whose changes are all staged is a `RANGE` target covering each changed hunk and the surrounding lines.

   Set `CONTEXT` to change how many lines surround a staged hunk. It defaults to `5`.

   ```bash
   CONTEXT=10 bash scripts/collect-targets.sh
   ```

2. Read each target. For a `RANGE` target, read the whole file for context but report findings only inside the listed ranges, so that unchanged prose stays unchanged.
3. Judge prose only — never restructure the document or change its technical claims.
4. Report findings as a table, one row per finding, most impactful first.

   ```text
   | File:line | Rule | Current | Suggested |
   | --------- | ---- | ------- | --------- |
   ```

   - Cite the rule ID from [Rule set](#rule-set) so the author can see the reasoning.
   - Leave a finding out when the rewrite does not clearly improve clarity. Prefer few, high-confidence findings over an exhaustive list.

5. Ask the user which findings to apply. Apply them with `Edit` only after approval, and change nothing else.

## Rule set

Each rule has a stable ID so findings stay traceable. Full before/after examples live in [references/rewrites.md](./references/rewrites.md).

### Audience

An agent-facing Markdown file has a different reader from a human-facing one. `AGENTS.md`, `SKILL.md`, and the command and subagent definitions are read by a coding agent at runtime, and a human reads them only while maintaining them. Decide which kind of file is under review before applying any other rule.

- `A1` Write to the reader the file actually has. In an agent-facing file, "you" means the agent, and "the user" means the human, who is a third party rather than the reader.
- `A2` Keep only what changes the agent's behavior. Drop motivation, reassurance, and history that a human maintainer would enjoy but an agent cannot act on.
- `A3` Mark every step the agent cannot perform. Name the human as the actor and give the exact text to hand over, because an agent that cannot run a step will otherwise guess at one.

### Voice and mood

- `V1` Use active voice in instructions and explanations. Name the actor instead of leaving a passive subject implicit. Passive voice is acceptable in specifications, where the actor is genuinely irrelevant.
- `V2` Address the reader as "you". Do not use "we" for instructions, and do not use "the user" when the reader is meant. In an agent-facing file the human is genuinely a third party, so `A1` governs instead.
- `V3` Write instructions in the imperative mood.
- `V4` Use present tense. Avoid "will" for behavior that is always true.

### Sentences

- `S2` Delete filler openings such as "Note that", "It should be noted that", "Basically", "Simply", "In order to" (use "to").
- `S3` Put the condition before the instruction: "If X, do Y", not "Do Y if X".
- `S4` Avoid nominalization. Prefer the verb ("configure") over the noun phrase ("perform the configuration of").
- `S5` Do not use "please" in instructions.

### Word choice

- `W1` Use one term consistently for one concept throughout a document. See [references/terminology.md](./references/terminology.md). For Autoware domain terms, defer to the glossary skill.
- `W2` Avoid ambiguous pronouns. Replace "it", "this", and "these" with the noun they refer to when the referent is not adjacent.
- `W3` Avoid unnecessary jargon, idioms, and culture-specific metaphors — many readers are not native English speakers.
- `W4` Avoid absolutes such as "easy", "simple", "just", "obviously", which judge the reader's experience.
- `W5` Expand an abbreviation at its first use in a document, then use the abbreviation.

### Structure and formatting

- `L1` Keep list items parallel in grammatical form: make them either all sentences or all fragments.
- `L2` Use a numbered list only for ordered steps; use a bullet list otherwise.
- `H1` Use sentence case for headings, and phrase them as noun phrases or gerunds, not full sentences.
- `C1` Mark identifiers, paths, commands, and literal values as inline code.
- `C2` Introduce a code block with a sentence that states what it does, and tag the block with its language.
- `C3` Use descriptive link text. Do not use "here" or a bare URL as link text.
