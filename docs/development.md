# Development Guide

## Supported agents

This repository supports the following coding agents:

- Claude Code
- Codex
- GitHub Copilot
- Cursor

## Release

See [roadmaps.md](./roadmaps.md).

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
