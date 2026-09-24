# Rewrite examples per rule

Each section shows the minimal edit that satisfies the rule. Rule IDs match [SKILL.md](../SKILL.md#rule-set).

## Table of contents

- [Audience](#audience)
- [Voice and mood](#voice-and-mood)
- [Sentences](#sentences)
- [Word choice](#word-choice)
- [Structure and formatting](#structure-and-formatting)

## Audience

### A1 — write to the reader the file actually has

In `SKILL.md`, the agent is the reader and the human is a third party.

- Bad: As a user, you should then approve the findings before they are applied.
- Good: Ask the user to approve the findings, then apply them.

### A2 — keep only what changes the agent's behavior

- Bad: Naming is a long-standing source of debate in this project, and the maintainers settled on kebab-case after a lengthy discussion. Use kebab-case.
- Good: Use kebab-case for the skill name.

### A3 — mark every step the agent cannot perform

- Bad: Run `/plugin marketplace update autoware-harness` to refresh the marketplace.
- Good: `/plugin` is interactive, so the agent cannot run it. Ask the user to run `/plugin marketplace update autoware-harness`.

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

- Bad: A numbered list presents the supported coding agents, which have no order.
- Good: A bullet list presents the supported coding agents, and a numbered list presents the installation steps.

### H1 — sentence-case noun-phrase headings

- Bad: `## How To Configure The Local Marketplace`
- Good: `## Configuring the local marketplace`

### C1 — inline code for identifiers

- Bad: Set the disable-model-invocation field to true.
- Good: Set the `disable-model-invocation` field to `true`.

### C2 — introduce and tag code blocks

- Bad: An untagged code block appears with no lead-in sentence.
- Good:

  Lint every tracked file:

  ```bash
  pre-commit run --all-files
  ```

### C3 — descriptive link text

- Bad: See [here](https://developers.google.com/style).
- Good: See the [Google developer documentation style guide](https://developers.google.com/style).
