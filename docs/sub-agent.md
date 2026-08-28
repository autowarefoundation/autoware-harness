# `SubAgent` Definition

In this project `SubAgent` is defined as a variant of `Skill` that:

- runs in the background
- works in a new, independent context
- returns the findings / result to the main context
  - (Preferable) **works without Edit / Write permission to the main worktree**

The first 3 items exactly match the characteristic of what is known as _Sub Agent_ in general. The last rule is specific to this project, but the principle is not unique — and it is in fact treated as an important property. Claude Code has 3 built-in sub agents `general-purpose`, `Plan`, `Explore` and `Plan / Explore` only work in read only mode. Codex provides `sandbox_mode` option (`read-only` and `workspace-write` mode, although it cannot be applied to skill level).

This project's policy is to minimize _write_ permission to _Sub Agent_ for the following reasons:

- Generally `Edit / Write` tools require approval from the user at least once (or at the first call). After that, once approved, later calls are allowed or later approvals themselves are bypassed for convenience per session (like Claude Code). However, a distributed `Skill` and `SubAgent` is desirable to have a consistent permission policy, and `Read`-only permission is the first option. Apart from `Read`-only, `Bash(git:*)` and especially `git branch / worktree` are considered to be safe as they protect the main worktree.
- `SubAgent` is expected to run autonomously in the background and not to get stuck while waiting for approval from the user. The leading `Agent` or the user commits changes based on the findings from `SubAgent` (findings include the `SubAgent` worktree) — otherwise the main worktree coherence would be broken.
  - (Claude Code Specific): According to [[1]](#references), a forked `SubAgent` does not save accessible checkpoints:

  ```txt
  A forked skill that runs in the background applies its edits outside your session’s checkpoints, so /rewind doesn’t undo them; use git to revert them.
  ```

- As a conclusion, it follows that a `SubAgent` having `Edit / Write` permission can lead to 2 problems:
  - The `SubAgent` may get stuck waiting for approval from the user, or even fabricate `Edit / Write` approval
    - (Claude specific): `AskUserQuestion` is also not available in `SubAgent` ([[2]](#references)).
  - The main worktree is changed behind the main session's back, the change cannot be rewound, and several changes may overlap in the worst case.

Besides, `Agent` is out of the development scope of this project so far (See [platform.md](./platform.md)).

## Properties

In `autoware-harness`, `SubAgent` is a variant of `Skill` that is placed under `skills/` directory with the following properties:

- `context: fork`
- TODO: permission, especially for Edit / Write. The `agent` field is deferred together with it, because the `git worktree` exception depends on whether `Plan` / `Explore` retain `Bash`.

`context: fork` and `agent` are Claude extensions, so a `SubAgent` skill degrades on other platforms and runs in the caller's context instead of an isolated one. Prose-style prompt like "run this skill in an isolated context" does not solve the issue because it is already read as a skill in the main context. To achieve complete isolation in cross-platform manner, the `SubAgent` should be distributed through `agents` manifest, which is out of the scope of this project due to packaging policy (see [platform.md](./platform.md)).

> [!NOTE]
> In Claude, `SubAgent` in `Plan` / `Explore` mode does not read `CLAUDE.md`. On other platforms it degrades to `Skill` and thus reads `AGENTS.md`.

## Trade-off between isolation and auto-discovery

If `SubAgent` is distributed as a pure cross-platform `Agent` and works in an isolated context, we can reduce the consumption of context window in the main context. However, it needs to be explicitly called by its name, losing the benefits of the auto-discovery characteristic which only `Skill` has.

In that sense, Claude's approach of `Skill` having `context: fork` enjoys both benefits. This project leverages this feature and mandates `context` field as well as an Agent-style body for `SubAgent`-like skills to ensure `Agent` behavior across the platforms (and isolation on Claude).

## References

- [1](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- [2](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background)
