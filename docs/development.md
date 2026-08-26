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

## Local verification

Only `.agents/skills` is loaded when you open this repository in coding agent CLIs. To verify the skills under `skills/`, install this repository as a local plugin in the following manner.

> [!TIP]
> To avoid conflict with the same `autoware-harness` installed on the host computer, `devcontainer` is useful to test on a clean environment.

### Install the working tree as a marketplace

```text
/plugin marketplace add <path to autoware-harness>
/plugin install autoware-harness@autoware-harness
```

### Reflect recent changes under `skills/`

```text
/plugin marketplace update autoware-harness
```

### Clean up

```text
/plugin uninstall autoware-harness@autoware-harness
/plugin marketplace remove autoware-harness
```
