# Design

## Repository Structure

- `docs/` contains the project documentation.
- `skills/` contains the resources to be installed.
- `AGENTS.md` and `.agents/skills/` are the agent prompts used for developing this project. These files and directories are symlinked to the Claude configuration.
- `.agents/plugins/marketplace.json`, `.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, and `.github/plugin` contain the plugin manifest files for each coding agent.
- `.devcontainers/` contains the `devcontainer` settings.

## Overview

Although there are many coding agents besides the ones supported by this project, most of them share three working units in common: _Agent_ / _Sub Agent_ (e.g. `~/.copilot/agents`), `Skill` (e.g. `~/.claude/skills`) and `Command` (e.g. `~/.codex/prompts/`). This project categorizes them as follows:

- _Agent_ defines _how the AI should act_ when it makes plans, judges, and initiates tasks.
  - _Agent_ is **explicitly called by its name**. The user themselves can be considered as an _Agent_.
  - _Agent_ is equipped with full permission to autonomously achieve the task without requesting approval one by one from the user.
- _Sub Agent_ is spawned by the parent _Agent_ to perform an independent task in a _new context_ and returns the result to the parent
  - _Sub Agent_ is **explicitly called by its name**.
  - _Sub Agent_ tends to have limited permission (in most cases `Read`-only permission) and perform assistive tasks such as planning (e.g. `/plan` in Claude Code), research, code review.
- `Skill` is either explicitly triggered by the agent or _picked up_ from the context to provide knowledge on _what AI should know_ and _how AI should tackle_ a specific task in the _current context_. In this project, a `Skill` is also expected to _inject the appropriate domain knowledge_ into the context.
  - `Skill` **may not be explicitly called by its name**. Therefore, its `description` field needs to carry enough information for the agent to pick the appropriate one on its own, based on the context.
    - This _auto discovery_ property can be considered as an advantage of `Skill`.
- `Command` is a set of procedures and prompts that is repeated many times during the development cycle. It is therefore expected to have a predictable effect. In this project, a `Command` _should_ rely only on the **given prompt** (i.e. `#ARGUMENTS` in Claude) and on **explicit calls to other Skills / Commands**, not on the context in which and when it is called.
  - `Command` should be **explicitly called by its name** and invoked by **humans**.

This project defines `SubAgent` (apart from _Sub Agent_ in common sense) as a variant of `Skill`. See [sub-agent.md](./sub-agent.md) for our definition.

This project prioritizes `Skill` and `SubAgent` (and boilerplate `Command`) over the others in order to provide **common basic building blocks** for Autoware developers, at least until their configurations stabilize — see [platform.md](./platform.md) for more details.

## Naming Rules / Skill Domains

All skills start with `awh-` (abbreviation of `Auto Ware Harness`), following `<domain>` part and leading name parts (excluding `.agents/skills/`). Current rule and roadmap for domain part is:

- `meta`
  - The skills relate to `autoware-harness` maintenance
- `glossary`
  - The skills provides each domain's glossary, known expertise in the domain, unique keywords with special meaning, etc.
- `interface`
  - The skills relate to Autoware's internal / external interface with other systems.
- `coding`
  - The skills relate to software design and coding styles per framework, programming language, etc. across Autoware project
- `component`
  - The skills describe component-wise (like Planning, Perception) background, mechanism / methodology, architectures
- TBD
