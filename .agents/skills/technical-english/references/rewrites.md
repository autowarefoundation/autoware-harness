# Rewrite examples per rule

Each section shows the minimal edit that satisfies the rule. Rule IDs match [SKILL.md](../SKILL.md#rule-set).

## Table of contents

- [Voice and mood](#voice-and-mood)
- [Sentences](#sentences)
- [Word choice](#word-choice)
- [Structure and formatting](#structure-and-formatting)

## Voice and mood

### V1 — active voice

- Bad: The front matter is read by the agent at session start.
- Good: The agent reads the front matter at session start.

### V2 — address the reader as "you"

- Bad: We recommend that the user sets `disable-model-invocation` to `true`.
- Good: Set `disable-model-invocation` to `true`.

### V3 — imperative mood

- Bad: You should then run the hooks.
- Good: Run the hooks.

### V4 — present tense

- Bad: The agent will load the skill once a matching context is detected.
- Good: The agent loads the skill when it detects a matching context.

## Sentences

### S1 — one idea per sentence

- Bad: The skill reads the target files and it groups the findings by rule and then it prints a table.
- Good: The skill reads the target files. It groups the findings by rule and prints a table.

### S2 — no filler openings

- Bad: Note that in order to lint the documents, you basically just need `pre-commit`.
- Good: To lint the documents, you need `pre-commit`.

### S3 — condition first

- Bad: Split the body into `references/` if the file exceeds 500 lines.
- Good: If the file exceeds 500 lines, split the body into `references/`.

### S4 — prefer verbs over nominalization

- Bad: Perform the installation of the local marketplace.
- Good: Install the local marketplace.

### S5 — no "please"

- Bad: Please refer to the design document.
- Good: See the design document.

<!-- TODO: add examples drawn from real review findings in this repository. -->

## Word choice

### W1 — consistent terminology

- Bad: Register the skill in the marketplace. The plugin manifest lists every add-on.
- Good: Register the skill in the marketplace. The plugin manifest lists every skill.

### W2 — no ambiguous pronouns

- Bad: The agent reads the front matter and the body. This is cached.
- Good: The agent reads the front matter and the body. The body is cached.

### W3 — no jargon or idioms

- Bad: Out of the box, the devcontainer is a piece of cake to spin up.
- Good: The devcontainer starts without further setup.

### W4 — no judgment of difficulty

- Bad: Simply run the script; it is obviously easy.
- Good: Run the script.

### W5 — expand abbreviations at first use

- Bad: Declare the skill in the MCP manifest.
- Good: Declare the skill in the Model Context Protocol (MCP) manifest.

## Structure and formatting

### L1 — parallel list items

- Bad:
  - Formats the Markdown files
  - Term validation
  - You should then check the links
- Good:
  - Formats the Markdown files
  - Validates the terms
  - Checks the links

### L2 — numbered lists only for ordered steps

- Bad: a numbered list of the supported coding agents.
- Good: a bullet list of the supported coding agents; a numbered list for the installation steps.

### H1 — sentence-case noun-phrase headings

- Bad: `## How To Configure The Local Marketplace`
- Good: `## Configuring the local marketplace`

### H2 — no skipped or stacked headings

- Bad: `## Architecture` followed immediately by `#### Skill layout`.
- Good: `## Architecture`, one sentence of context, then `### Skill layout`.

### C1 — inline code for identifiers

- Bad: Set the disable-model-invocation field to true.
- Good: Set the `disable-model-invocation` field to `true`.

### C2 — introduce and tag code blocks

- Bad: an untagged block with no lead-in sentence.
- Good:

  Lint every tracked file:

  ```bash
  pre-commit run --all-files
  ```

### C3 — descriptive link text

- Bad: See [here](https://developers.google.com/style).
- Good: See the [Google developer documentation style guide](https://developers.google.com/style).
