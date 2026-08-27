# `SubAgent` Definition

In this project `SubAgent` is defined as a variant of `Skill` that:

- runs in parallel to the main context
- works in a new, independent context
- returns the findings / result to the main context
- **works without Edit / Write permission**
  - `git branch / worktree` creation is the only exception.

The first 3 items exactly match the characteristic of what is known as _Sub Agent_ in general. The last rule is specific to this project, but the principle is not unique — even considered as an important property. Claude Code has 3 built-in sub agents `General-purpose`, `Plan`, `Explore` and `Plan / Explore` only work in read only mode. Codex provides `sandbox_mode = "read-only"` option.

This project explicitly limits _write_ permission to _Sub Agent_ for the following reasons:

- Generally `Edit / Write` tools require approval from the user at least once (or at the first call). After that, once approved, a later call is allowed or the later approval itself is bypassed for convenience per session (like Claude Code). However, a distributed `Skill` and `SubAgent` is desirable to have a consistent permission policy, and `Read`-only permission is the first option. Apart from `Read`-only, `Bash(git:*)` and especially `git branch / worktree` are considered to be safe as they protect the main worktree.
- `SubAgent` is expected to run autonomously in the background and not to get stuck while waiting for approval from the user. The leading `Agent` or the user commits changes based on the findings from `SubAgent` (findings include the `SubAgent` worktree) — otherwise the main worktree coherence would be broken.
  - (Claude Code Specific): According to [[1]](#references), a forked `SubAgent` does not save accesible checkpoints:

  ```txt
  A forked skill that runs in the background applies its edits outside your session’s checkpoints, so /rewind doesn’t undo them; use git to revert them.
  ```

- As a conclusion, it follows that a `SubAgent` having `Edit / Write` permission leads to 2 problems:
  - The `SubAgent` may get stuck waiting for approval from the user, or even fabricate `Edit / Write` approval
  - The main worktree is changed behind the main session's back, the change cannot be rewound, and several changes may overlap in the worst case.

Besides, `Agent` is out of the deveopment scope of this project so far (See [platform.md](./platform.md)).

## Properties

In `autoware-harness`, `SubAgent` is a variant of `Skill` that is placed under `skills/` directory with the following properties:

- `context: fork`
- `agent`: `Explore / Plan` is the 1st option, unless the skill runs `git branch / worktree`
  - TODO: can we limit `Explore / Plan` by making it a rule to create wokrtree outside of the repository ?
- `disallowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited
  - TODO: if the `agent` is `Explore / Plan`, then do we need this to explicitly prohibit Write action ?
- `allowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited

`agent` and `disallowed-tools` carry the enforcement, and `allowed-tools` states the intent. See [the guardrail section of format.md](./format.md#guardrail) for why all three are needed, and note in particular that `agent` defaults to `general-purpose`, which holds every tool. [permission.md](./permission.md) covers the underlying model on every platform.

## Other platforms

`context: fork`, `agent` and `disallowed-tools` are Claude extensions, and `allowed-tools` is not portable either: Cursor does not document it as a `SKILL.md` front matter field, and Codex does not document it at all (see [permission.md](./permission.md)).

Codex is the one other platform that can make a write impossible, through `sandbox_mode = "read-only"` on a custom subagent. It has no way to receive that definition from a plugin yet, so the guarantee is not reachable by distribution today.

A `SubAgent` skill therefore degrades on the other platforms: it runs in the caller's context instead of an isolated one. That loses the isolation but **not the guardrail**, because the user is present in the caller's context and can approve. The write prohibition is the part that must survive, and it does.

Do not try to recover the isolation with a prompt in the body that asks the agent to re-run itself in an isolated context. Such a prompt is read only after the body has already entered the main context, so it cannot restore the isolation it asks for, and an instruction in prose cannot create a permission boundary that the harness does not enforce. If a platform ever needs genuine isolation, distribute the same body through that platform's `agents` manifest field instead, which is a packaging problem rather than a prompt problem (see [platform.md](./platform.md)).

## References

- [1](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
