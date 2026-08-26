# Development Guide

## Supported agents

This repository supports the following coding agents:

- Claude Code
- Codex
- GitHub Copilot
- Cursor
- OpenCode

## Release

## Naming rules

Each feature name should be composed as follows:

1. Start with `awh-` (an abbreviation of `autoware harness`).
2. Add the `<domain>` (for example, `interface`, `perception`).
3. Append any sub-domain parts, separated by `-`.

## Agent vs Skill vs Command

See [design.md.](./design.md)

## Development Environment

(Optional) It is recommended to use `devcontainer` to reproduce development environment. If you are using `vscode`, it will automatically setup the `devcontainer`. Or you can start the container by

```bash
devcontainer up && devcontainer exec bash // when you start
---
docker container kill autoware-harness-devcontainer // finish
---
devcontainer up --remove-existing-container // when Dockerfile or devcontainer.json has changed
```

Even if you do not have access to local environment, you can open up `GitHub Codespace` on the repository.

## Implementation

See [format.md](./format.md).
