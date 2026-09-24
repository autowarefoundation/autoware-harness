# SKILL.md Format

## Front Matter

All `SKILL.md` file must have

- `name`
- `description`
- `allowed-tools`

field (see [platform.md](./platform.md) for the background).

Additionally, if you intend to design a `Command`, **place it under skills/**, and set

```yaml
disable-model-invocation: true
```

to explicitly declare as a human triggered command (NOTE: this is a Claude extension).

### name

`name` should follow the naming rules as described in [design.md](./design.md).

### description

`description` field must:

- start with "Use this skill when / for ..." and describe concrete trigger situations
- include the purpose / objective of the skill
- (optional) include argument guide or hint to obtain better output

### allowed-tools

`allowed-tools` must be space-separated lists. See [security.md](./security.md) and take care of following behaviors:

- Read-only tools should be enumerated because otherwise the user would be prompted whenever Claude select them on the first use.
- `Edit` should be declared only when the skill needs to edit relevant files.
- At least in Claude, `WebFetch` tool does not read the full content of the URL, but it summarizes the content with lightweight model.

### for `SubAgent`

If the skill is expected to work as a `SubAgent`, add

- `context: fork`
- `agent: Explore | Plan`

See [sub-agent.md](./sub-agent.md)

## Body

If the body consists of several units like steps, instructions, sub domains and **exceeds 500 lines**, it is highly recommended to divide them into `references/` folder ([reference](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#progressive-disclosure-patterns)).

Long reference files or `SKILL.md` should have table of contents to achieve **progressive disclosure**, leading to less consumption of context window (related files do not consume context tokens until they are actually read).

### Sub directories

- `references/`: contains extra Markdown files
- `templates/`: contains template files
- `scripts/`: contains simple auxiliary script to be executed by the skill

### for `SubAgent`

For skills that work as `SubAgent`:

- include "Report" section at the end of the body
- define the format of findings (bullet points, table, etc.)
- do not include apply / edit steps

### Styles (WIP)

- It is recommended to explicitly call relevant skill / information (like glossary, coding guideline)
  - to inject expertise knowledge from other domain
  - to divide roles and responsible domain per skills
- code execution part should present concrete code blocks
- present reliable source for external information as much as possible:
  - Good: official API reference, document, release notes, known issues
  - Bad: secondary information from media
