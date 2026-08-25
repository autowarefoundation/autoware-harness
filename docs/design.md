# Design

## Overview

Although there are various coding agents other than the ones supported in thie project, most of them have 3 working units in common - `Agent` (sub agent, like `~/.copilot/agents`), `Skill` (like `~/.claude/skills`) and `Command` (like `~/.codex/prompts/`). This project categorizes them as follows:

- `Agent` defines _how AI should act_ when it make plans, judges and initiate tasks. When it is triggered as a sub agent, it acts in a _new context_ and returns the result to main context.
  - `Agent` is **explicitly called by its name**.
- `Skill` is explicitly triggered by the agent or _picked up_ by the context to provide knowledge on _how AI should tackle_ specific tasks in _current context_. Also in this project, `Skill` is expected to _inject appropriate domain knowledge_ into the context.
  - `Skill` **may not be explicitly called by its name** . Therefore its `description` field needs to have enough information so that the agent can pick up appropriate one by itself based on the context.
- `Command` is a set of procedures and prompts which is repeated many times in the development cycle. Thus it is expeted to have predictable effect. In this project, a `Command` _should_ only rely on **given prompt** (aka `#ARGUMENTS` in Claude) and **explict call for other Skill / Command**, not on the context in which and when it is called.
  - `Command` is **explicity called by its name** and is invoked by **humans**.

This project proritizes `Skill`(and boilerplate `Command`) over the others to provide **common basic building blocks** for Autoware developers (at least until their configuratins get stable -- see `./platform.md`).

## Repository Structure

- `docs/` contains
- `skills/` directory contains the resources to be installed.
- `AGENTS.md`, `.agents/skills/` are agent prompts for developing this project. These files / directories are symlinked from Claude stuff.
- `.agents/plugins/marketplace.json`, `.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `.github/plugin` contain plugin manifest files for each coding agents.
- `.devcontainers` folder contains `devcontainer` settings
