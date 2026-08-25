# Support status of each platforms

## Support status for Agent / Skill / Command

Below table summarizes support status of each feature (It can change in the future) **for project scope**.

| Coding Agent | Context File                                       | Skill             | Command                                 | Agent                           |
| ------------ | -------------------------------------------------- | ----------------- | --------------------------------------- | ------------------------------- |
| Claude       | `CLAUDE.md`                                        | `./claude/skills` | merged into `Skill`([[1]](#references)) | Markdown under `.claude/agents` |
| Codex        | `AGENTS.md`                                        | `.codex/skills`   | merged into `Skill`                     | defined in `.codex/config.toml` |
| Copilot      | `AGENTS.md`, `CLAUDE.md`, etc.([[2]](#references)) |                   |                                         |                                 |

Since the distribution of `Agent` and `Command` are not well standardized, this project proritizes `Skill` and part of `Commands`.

## Support status of YAML front matter

## References

- [1](https://code.claude.com/docs/en/changelog#2-1-3)
- [2](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions#types-of-custom-instructions)
