# Support status of each platform

> [!WARNING]
> The following information is based on the documentation as of 2026/08/27.

## Support status for Agent / Skill / Command

The table below summarizes the support status of each feature **for project scope**.

| Coding Agent | Context File                                        | Skill                                                                   | Command                                   | Agent                                                |
| ------------ | --------------------------------------------------- | ----------------------------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------- |
| Claude       | `CLAUDE.md`                                         | `.claude/skills`                                                        | `Skill` is preferred ([[1]](#references)) | Markdown under `.claude/agents`                      |
| Codex        | `AGENTS.md`                                         | `.codex/skills`                                                         | `Skill` is preferred ([[2]](#references)) | defined in `.codex/config.toml`                      |
| Copilot      | `AGENTS.md`, `CLAUDE.md`, etc. ([[3]](#references)) | Multiple directories in given order and precedence ([[4]](#references)) | Same as `Skill`                           | Same as `Skill`                                      |
| Cursor       | `AGENTS.md`, `.cursor/rules` ([[5]](#references))   | `.cursor/skills` ([[6]](#references))                                   | `Skill` is preferred ([[7]](#references)) | Markdown under `.cursor/agents` ([[8]](#references)) |

Since the distribution of `Agent` and `Command` is not well standardized, this project prioritizes `Skill` and a subset of `Command`.

### Distributing `Command` via plugin manifests

`Command` distribution through the plugin manifest differs per platform. The table below reflects the official manifest specifications.

| Coding Agent | Manifest field for `Command`        | Target files                       |
| ------------ | ----------------------------------- | ---------------------------------- |
| Claude       | `commands` ([[9]](#references))     | flat `*.md`                        |
| Cursor       | `commands` ([[10]](#references))    | `.md`, `.mdc`, `.markdown`, `.txt` |
| Copilot      | `commands` ([[11]](#references))    | files under `commands/`            |
| Codex        | not supported ([[12]](#references)) | --                                 |

Therefore a single `commands/` directory at the repository root can be shared by Claude, Cursor and Copilot. Claude discovers it automatically, while Cursor and Copilot need an explicit `"commands": "./commands/"` entry in their manifest.

Codex has no `Command` (or prompt) component in its plugin manifest, so plugins cannot populate `~/.codex/prompts`. Codex-compliant workflow must be a `Skill`.

Note that both Claude and Copilot recommend the `skills/` layout for new plugins (Claude states it explicitly ([[9]](#references)), and Copilot lets `Skill` override `Command` in its loading order ([[4]](#references))), and that Codex deprecates `Command` in favor of `Skill`([[2]](#references)). This is consistent with this project prioritizing `Skill`.

### Distributing `Agent` via plugin manifests

The situation mirrors `Command`: Claude, Cursor and Copilot all take an `agents` field pointing at a directory of Markdown files, but the file naming differs (Copilot expects the `.agent.md` suffix), so a single directory cannot be shared as-is.

Codex has no `agents` field in its plugin manifest. Its subagents are configured in `.codex/config.toml`.

| Coding Agent | Manifest field for `Agent`          | Target files                 |
| ------------ | ----------------------------------- | ---------------------------- |
| Claude       | `agents` ([[9]](#references))       | flat `*.md` under `agents/`  |
| Cursor       | `agents` ([[13]](#references))      | `.md`, `.mdc`, `.markdown`   |
| Copilot      | `agents` ([[11]](#references))      | `*.agent.md` under `agents/` |
| Codex        | not supported ([[12]](#references)) | N/A                          |

## Support status of YAML front matter

All four platforms support the Agent Skills open standard ([[14]](#references)), whose front matter is the portable baseline:

| Field           | Required | Constraints                                                                     |
| --------------- | -------- | ------------------------------------------------------------------------------- |
| `name`          | Yes      | 1-64 chars, lowercase `a-z`, `0-9` and `-`; no leading/trailing/consecutive `-` |
| `description`   | Yes      | 1-1024 chars; states what the skill does and when to use it                     |
| `license`       | No       | License name, or the name of a bundled license file                             |
| `compatibility` | No       | Up to 500 chars; environment requirements                                       |
| `metadata`      | No       | Arbitrary string-to-string map                                                  |
| `allowed-tools` | No       | Space-separated list of pre-approved tools (experimental in the spec)           |

Per-platform support of those fields is as follows.

| Coding Agent | Required                                        | Also adopted from the standard                          | Reference           |
| ------------ | ----------------------------------------------- | ------------------------------------------------------- | ------------------- |
| Claude       | none (`name` and `description` are recommended) | `license`, `compatibility`, `metadata`, `allowed-tools` | [[15]](#references) |
| Codex        | `name`, `description`                           | not documented                                          | [[16]](#references) |
| Cursor       | `name`, `description`                           | `metadata`                                              | [[6]](#references)  |
| Copilot      | `name`, `description`                           | `license`, `allowed-tools`                              | [[17]](#references) |

Each platform additionally defines its own extensions as follows:

- Claude: `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`([[15]](#references))
- Cursor: `paths`, `disable-model-invocation`, `icon`, `color`

Therefore this project mandates the following fields:

- `name`: Required
- `description`: Required
- `allowed-tools`: Required (if it's empty set it to `""`), but note that Cursor does not document it as a `SKILL.md` front matter field ([[6]](#references)), so it is not honored there

## References

- [1](https://code.claude.com/docs/en/changelog#2-1-3)
- [2](https://github.com/openai/codex/releases/tag/rust-v0.118.0)
- [3](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions#types-of-custom-instructions)
- [4](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#loading-order-and-precedence)
- [5](https://cursor.com/docs/context/rules)
- [6](https://cursor.com/docs/context/skills#frontmatter-fields)
- [7](https://cursor.com/docs/context/skills)
- [8](https://cursor.com/docs/agent/subagents)
- [9](https://code.claude.com/docs/en/plugins-reference#component-path-fields)
- [10](https://cursor.com/docs/reference/plugins#commands-format)
- [11](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#component-path-fields)
- [12](https://developers.openai.com/codex/plugins/build)
- [13](https://cursor.com/docs/reference/plugins#agents-format)
- [14](https://agentskills.io/specification#frontmatter)
- [15](https://code.claude.com/docs/en/skills#frontmatter-reference)
- [16](https://learn.chatgpt.com/docs/build-skills#create-a-skill)
- [17](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills#example-skillmd-file)
