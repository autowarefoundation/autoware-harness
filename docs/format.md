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

`allowed-tools` must be space-separated lists, and only knowledge-injection skill can have empty `allowed-tools: ""`. Try to specify tolerable actions to ensure security and avoid accidents.

#### Approval guardrail

A `Skill` and an `Agent` differ in how they clear an action that needs approval, so they need different tool grants.

- A `Skill` runs under an **approval guardrail**. An action that requires user approval, such as editing a file in the repository, must reach the user before it happens.
- An `Agent` **self-approves** inside the task it was given and keeps editing until that task is done. It returns the result to the caller instead of asking mid-task.

A forked skill (`context: fork`) runs in a new context and never receives user messages. Its caller is the only party it can talk to, so it cannot obtain user approval, and an instruction such as "ask the user before applying the changes" is a step it **cannot perform**. A forked skill that also holds a file-mutating tool therefore edits without approval, and it may report back that approval was given.

Declare `allowed-tools` so that the guardrail cannot be skipped.

| `context` | File-mutating tools in `allowed-tools`     | Verdict                                                                        |
| --------- | ------------------------------------------ | ------------------------------------------------------------------------------ |
| `fork`    | None                                       | Allowed. Return the findings and let the caller apply them.                    |
| `fork`    | `Edit`, `Write`, `NotebookEdit`, or `Bash` | Forbidden. The skill can edit before the user ever sees the proposal.          |
| Omitted   | Any                                        | Allowed. The skill runs in the caller's context, so approval reaches the user. |

`Bash` is file-mutating unless it is narrowed to specific commands, because an unrestricted shell can write any file. Prefer `Bash(git:*)` over bare `Bash` when a forked skill only needs to read repository state.

Split a skill that both investigates and edits: fork the investigation, return the proposal, and leave the edit to the caller that can ask the user.

### context

Given the number of potential Claude users, to reduce the usage of context window,

```yaml
context: fork
```

field (NOTE: this is a Claude extension) is recommended for **independent-task-oriented skill that does not rely on current context**.

Because a forked skill cannot ask the user anything, `context: fork` constrains what the skill may be allowed to do. See [Approval guardrail](#approval-guardrail).

### Validation

`scripts/validate-skill-front-matter.py` checks every `SKILL.md` against the rules above and runs as a `pre-commit` hook.

```bash
pre-commit run validate-skill-front-matter --all-files
```

It reports a violation with the file, the offending field, and the rule that was broken.

## Body

If the body consists of several units like steps, instructions, sub domains and **exceeds 500 lines**, it is highly recommended to divide them into `references/` folder ([reference](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#progressive-disclosure-patterns)).

Long reference files or `SKILL.md` should have table of contents to achieve **progressive disclosure**, leading to less consumption of context window (related files do not consume context tokens until they are actually read).

### Sub directories

- `references/`: contains extra Markdown files
- `templates/`: contains template files
- `scripts/`: contains simple auxiliary script to be executed by the skill

### Styles (WIP)

- It is recommended to explicitly call relevant skill / information (like glossary, coding guideline)
  - to inject expertise knowledge from other domain
  - to divide roles and responsible domain per skills
- code execution part should present concrete code blocks
- present reliable source for external information as much as possible:
  - Good: official API reference, document, release notes, known issues
  - Bad: secondary information from media
