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

Note that `allowed-tools` **pre-approves** tools rather than restricting them, so it declares intent and does not enforce it. See [permission.md](./permission.md) for what each platform actually enforces.

### for `SubAgent`

If the skill is expected to work as a `SubAgent`, add

- `context: fork`
- `agent`: `Plan` or `Explore`
- `disallowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited
  - TODO: if the `agent` is `Explore / Plan`, then do we need this to explicitly prohibit Write action ?
- `allowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited

field. The first 2 fields are only effective to Claude, and on other platforms the skill degrades to `Skill` in the same context.

#### guardrail

`SubAgent` runs in a new context and never receives user messages, so it cannot obtain user approval. An instruction such as "ask the user before applying the changes" is a step it **cannot perform**. A `SubAgent` that is able to write therefore edits without approval, and it may report back that approval was given.

`allowed-tools` alone does not prevent this, because it pre-approves tools rather than restricting them. See [permission.md](./permission.md) for the full model on every platform.

Two Claude fields do restrict, and a `SubAgent` needs both.

| Field              | Effect                                                                                                                                                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `agent`            | With `context: fork`, the agent type determines the tools and permissions. It **defaults to `general-purpose`, which holds every tool**, so omitting it grants full write access. Use `agent: Explore`, whose tool set excludes `Edit`, `Write` and `NotebookEdit`. |
| `disallowed-tools` | Removes tools from the pool while the skill is active. Required in addition to `agent`, because `Explore` still holds `Bash`, and an unrestricted shell can write any file.                                                                                         |

A `SubAgent` therefore declares its front matter as follows.

```yaml
context: fork
agent: Explore
allowed-tools: Glob Grep Read WebFetch
disallowed-tools: Edit Write NotebookEdit Bash
```

When the `SubAgent` needs to read repository state, drop `Bash` from `disallowed-tools` and narrow the grant to `Bash(git:*)` instead. That grant only removes the approval prompt for those commands, so the shell remains a write path. Keep `Bash` in `disallowed-tools` whenever the task does not need it.

Both `agent` and `disallowed-tools` are Claude extensions, so this enforcement does not carry to other platforms. See [sub-agent.md](./sub-agent.md) for what survives there.

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
