# Design

## Overview

Although there are many coding agents besides the ones supported by this project, most of them share three working units in common: `Agent` (a sub agent, e.g. `~/.copilot/agents`), `Skill` (e.g. `~/.claude/skills`) and `Command` (e.g. `~/.codex/prompts/`). This project categorizes them as follows:

- `Agent` defines _how the AI should act_ when it makes plans, judges, and initiates tasks. When it is triggered as a sub agent, it acts in a _new context_ and returns the result to the main context.
  - `Agent` is **explicitly called by its name**.
- `Skill` is either explicitly triggered by the agent or _picked up_ from the context to provide knowledge on _how the AI should tackle_ a specific task in the _current context_. In this project, a `Skill` is also expected to _inject the appropriate domain knowledge_ into the context.
  - `Skill` **may not be explicitly called by its name**. Therefore, its `description` field needs to carry enough information for the agent to pick the appropriate one on its own, based on the context.
- `Command` is a set of procedures and prompts that is repeated many times during the development cycle. It is therefore expected to have a predictable effect. In this project, a `Command` _should_ rely only on the **given prompt** (i.e. `#ARGUMENTS` in Claude) and on **explicit calls to other Skills / Commands**, not on the context in which and when it is called.
  - `Command` should be **explicitly called by its name** and invoked by **humans**.

This project prioritizes `Skill` (and boilerplate `Command`) over the others in order to provide **common basic building blocks** for Autoware developers, at least until their configurations stabilize — see [platform.md](./platform.md) for more details.

## Repository Structure

- `docs/` contains the project documentation.
- `skills/` contains the resources to be installed.
- `AGENTS.md` and `.agents/skills/` are the agent prompts used for developing this project. These files and directories are symlinked from the Claude configuration.
- `.agents/plugins/marketplace.json`, `.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, and `.github/plugin` contain the plugin manifest files for each coding agent.
- `.devcontainers/` contains the `devcontainer` settings.
