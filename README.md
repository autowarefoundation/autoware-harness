# autoware-harness

Autoware is an open-source autonomous driving platform that spans a wide range of domains — sensor drivers, embedded systems and networking (ROS 2 and DDS), Docker and Linux, performance profiling, C++/Python software development, autonomous-driving-specific domain knowledge, machine learning, simulation, and system integration on real vehicles, among others.

`autoware-harness` is designed to facilitate Autoware development and integration by:

1. collecting, unifying, and sharing common knowledge and context from each domain — glossary, methodology, development rules and conventions, etc. — so that every developer and agent can grasp the whole picture at an expert level
2. collecting and maintaining useful tips and know-how for effective development, integration, and debugging
3. encapsulating and exposing all of the above as a set of `Skill`s and `Agent`s, so that:
   - users can integrate and customize Autoware for their own purposes
   - developers can build their custom skills and agents on top of them
   - agents can autonomously fix issues by following the appropriate procedures

Consolidating all of this into a **single source of truth** that everyone refers to in common enables us to address following problems:

- Domain knowledge and know-how tend to stay locked inside individual developers' heads instead of being shared across the project and with external contributors.
- Fixing a downstream issue at its root is difficult, since doing so requires tracing it back through multiple unfamiliar, Autoware-specific domains.
- Domain-specific glossaries (Planning, Perception, Sensing, Localization, etc.) make review by non-domain experts difficult, and terminology is often inconsistent even within a single component.
- Coding style, error handling, and other package-level conventions vary from maintainer to maintainer.
- Debugging and performance-measurement know-how is rarely shared.

Over time, this also helps developers converge on a shared consensus, and lets external users lean on agents to quickly access developer-level context.

## Installation / Update

Once installed, call `/awh-meta-self-update` in each tool's session.

### Claude Code / GitHub Copilot CLI

```txt
/plugin marketplace add autowarefoundation/autoware-harness
/plugin install autoware-harness@autoware-harness
```

### Codex CLI

```txt
/plugins
```

Open the plugin browser inside a Codex session, add `autowarefoundation/autoware-harness` as a marketplace source, and install `autoware-harness` from it. Or

```bash
codex plugin marketplace add autowarefoundation/autoware-harness
```

### Cursor

1. Dashboard → Plugins → Team Marketplaces → Add Marketplace → Import from Repo, and point it at `autowarefoundation/autoware-harness`.
2. Customize (sidebar) → find `autoware-harness` → Install

## Usage

Coding Agents will automatically select and load relevant skills. Or you can explicitly call specific skill by typing `/awh-` `TAB` and selecting appropriate one.

## Feature Request / Issue Report

If any issues are found (the agent not working appropriately, skills/commands not recognized, etc.) please submit a PR or an issue following the template.

## Development Guide

See [docs/development.md](docs/development.md).
