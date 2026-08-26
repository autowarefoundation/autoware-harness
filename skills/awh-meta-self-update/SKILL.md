---
description: |
  Use this skill when the user asks to update, upgrade, or check for a new version of the autoware-harness plugin itself
  (for example "update the harness", "is there a newer version of this plugin?").
  It gives the in-session command for the coding agent hosting the session.
name: awh-meta-self-update
allowed-tools: ""
---

# Updating the Autoware Harness plugin

Every platform manages plugins through an in-session command. Present the command for the agent hosting this session and let the user run it, because `/plugin` is interactive and the agent cannot run it.

## Claude

Claude refreshes the marketplace and checks for new plugin versions at the start of each session, so run these commands only when the user wants the update applied immediately.

```text
/plugin marketplace update autoware-harness
/plugin update autoware-harness@autoware-harness
```

The update applies after a restart.

## Copilot

```text
/plugin
```

Select `autoware-harness` and update it from the plugin manager.

## Codex

```text
/plugins
```

Open the entry for `autoware-harness` and reinstall it to pick up the current version. Bundled
skills become available in the next session.

## Cursor

Cursor documents no command for updating an installed plugin. Report that the update is done from the Cursor plugin UI.

## After the update

State whether a restart is required.
