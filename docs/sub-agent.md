# Sub Agent Definition

In this project `SubAgent` is defined as a variant of `Skill` that:

- runs in parallel to the main context
- works in a new, independent context
- returns the findings / result to the main context
- **works without Edit / Write permission**

The first 3 items exactly match the characteristic of what is known as _Sub Agent_ in general. This project explicitly limits _write_ permission to _Sub Agent_ for the following reasons:

- Generally `Edit / Write` tools require approval from the user at least once (or at the first call). After that, once approved, a later call is allowed or the later approval itself is bypassed for convenience per session (like Claude Code). However, a distributed `Skill` and `SubAgent` is expected to have a consistent permission policy, and `Read`-only permission is the first option. Apart from `Read`-only, `Bash(git:*)` and especially `git branch / worktree` are safe as they protect the main worktree.
- `SubAgent` is expected to run autonomously in the background and not to get stuck while waiting for approval from the user. The leading `Agent` or the user commits changes based on the findings from `SubAgent` (findings include the `SubAgent` worktree) — otherwise the main worktree coherence would be broken.
- A write from a background `SubAgent` is also **not recoverable through the session**. Claude Code states that a forked skill running in the background "applies its edits outside your session's [checkpoints], so `/rewind` doesn't undo them" ([[1]](#references)), leaving the revert to be done by hand.
- As a conclusion, it follows that a `SubAgent` having `Edit / Write` permission leads to 2 problems:
  - The `SubAgent` may get stuck waiting for approval from the user, or even preempt `Edit / Write` without getting approval
  - The main worktree is changed behind the main session's back, the change cannot be rewound, and several changes may overlap in the worst case.

Besides, `Agent` is out of the scope of this project so far (See [platform.md](./platform.md)).

## Properties

In `autoware-harness`, `SubAgent` is a variant of `Skill` that is placed under `skills/` directory with the following properties:

- `context: fork`
- `agent: Explore`
- `disallowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited
- `allowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited

`agent` and `disallowed-tools` carry the enforcement, and `allowed-tools` states the intent. See [the guardrail section of format.md](./format.md#guardrail) for why all three are needed, and note in particular that `agent` defaults to `general-purpose`, which holds every tool.

## Background execution

`context: fork` makes the skill run in a new context, and Claude Code runs that fork in the background by default. The parallelism comes from the separate `background` field, whose default is `true` ([[2]](#references)).

Do not treat the parallelism as a guarantee. Claude Code waits for the result instead in the following documented cases ([[1]](#references)):

- in non-interactive mode, with the `-p` flag or the Agent SDK
- when `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` is set to `1`
- when a forked skill is invoked while an earlier invocation of the same skill is still running
- when a scheduled task fires with the skill as its prompt

The write prohibition does not depend on which of the two happens, so it holds either way.

## Task shape

`context: fork` "only makes sense for skills with explicit instructions" ([[1]](#references)). A subagent that receives guidelines without a task returns without meaningful output, so keep a knowledge-injection `Skill` unforked and reserve `SubAgent` for a skill that states what to do.

## Other platforms

`context: fork`, `agent` and `disallowed-tools` are Claude extensions, and `allowed-tools` is not portable either: Cursor does not document it as a `SKILL.md` front matter field, and Codex does not document it at all (see [platform.md](./platform.md)).

A `SubAgent` skill therefore degrades on the other platforms: it runs in the caller's context instead of an isolated one. That loses the isolation but **not the guardrail**, because the user is present in the caller's context and can approve. The write prohibition is the part that must survive, and it does.

Do not try to recover the isolation with a prompt in the body that asks the agent to re-run itself in an isolated context. Such a prompt is read only after the body has already entered the main context, so it cannot restore the isolation it asks for, and an instruction in prose cannot create a permission boundary that the harness does not enforce. If a platform ever needs genuine isolation, distribute the same body through that platform's `agents` manifest field instead, which is a packaging problem rather than a prompt problem (see [platform.md](./platform.md)).

## References

- [1](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- [2](https://code.claude.com/docs/en/skills#frontmatter-reference)
