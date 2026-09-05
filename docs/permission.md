# Permission and tool grants

> [!WARNING]
> The following information is based on the documentation as of 2026/08/27.

This document collects how each platform decides whether a tool call is allowed, so that the rest of the documentation can refer to one place instead of restating it. [format.md](./format.md) covers which fields a `SKILL.md` must declare, and [sub-agent.md](./sub-agent.md) covers the guardrail that a `SubAgent` needs.

## Table of contents

- [The distinction that matters](#the-distinction-that-matters) — declaration vs enforcement
- [Claude](#claude) — the only platform with a fully documented model
- [Codex](#codex) — sandbox and approval policy
- [Copilot](#copilot) — pre-approval only
- [Cursor](#cursor) — not documented
- [Cross-platform summary](#cross-platform-summary)
- [What this project relies on](#what-this-project-relies-on)

## The distinction that matters

Two questions look alike and are not.

- **Who is asked?** Whether a tool call interrupts the user for approval.
- **What is possible?** Whether the tool call can happen at all.

A field that answers the first question does not answer the second. `allowed-tools` answers only the first one on every platform that documents it, so it can never be the mechanism that stops an action.

The principle behind this holds on all four platforms, and Claude states it directly ([[1]](#references)):

> Permission rules are enforced by Claude Code, not by the model. Instructions in your prompt or `CLAUDE.md` shape what Claude tries to do, but they don't change what Claude Code allows.

An instruction in a `SKILL.md` body, or in `AGENTS.md`, therefore shapes intent and never enforces it. Treat prose as a way to make the desired behavior likely, and a configured rule as the only way to make the undesired behavior impossible.

## Claude

### allowed-tools

`allowed-tools` grants permission for the listed tools during the turn that invokes the skill, and the grant clears at the next user message. It is explicitly not a restriction ([[2]](#references)):

> It does not restrict which tools are available: every tool remains callable, and your permission settings still govern tools that are not listed.

A skill can grant itself broad access, and workspace trust does not gate the field, so review the `allowed-tools` of any skill checked into a repository before running the agent there ([[2]](#references)).

### disallowed-tools

`disallowed-tools` is a Claude extension that removes tools from the pool while the skill is active, and the restriction clears at the next user message ([[3]](#references)). This is the frontmatter field that restricts.

### Permission rules

Rules live in the settings files and come in three kinds. The evaluation order is fixed ([[1]](#references)):

> Rules are evaluated in order: deny, then ask, then allow. The first match in that order determines the outcome, and rule specificity doesn't change the order.

Two consequences are easy to miss.

- A broad deny rule cannot carry an allowlist exception. `Bash(aws *)` in deny blocks `Bash(aws s3 ls)` in allow.
- A bare tool name in a deny rule removes the tool from the context entirely, while a scoped rule such as `Bash(rm *)` leaves the tool available and blocks matching calls.

### File path rules

Only `Edit(path)` and `Read(path)` are consulted for file access. A path rule written for `Write`, `NotebookEdit`, `Glob` or `MultiEdit` is accepted and never used, and the agent warns at startup ([[1]](#references)). A `Read` deny rule also blocks `Edit` and `Write` on the same path, but it does not cover `NotebookEdit`, so a path that no tool may change needs an `Edit` deny rule as well.

These rules apply to the built-in file tools and to file commands recognized inside Bash, such as `cat` and `sed`. They do not apply to a subprocess that opens files itself, such as a script ([[1]](#references)).

### Permission modes

The mode decides which calls prompt at all. `acceptEdits` accepts file edits automatically, and `bypassPermissions` skips prompts altogether. Either mode removes the approval step that a guardrail may otherwise be relying on, which is why a guardrail must not be built out of prompts.

### Hooks

A `PreToolUse` hook evaluates a call before the prompt and can deny it. Hooks do not override the rules: a deny rule still blocks and an ask rule still prompts regardless of what the hook returns, and a hook that exits with code 2 stops the call before the rules are evaluated ([[1]](#references)).

### Sandboxing

Sandboxing is OS-level and applies to the Bash tool and its child processes only. It is the layer that holds when a rule does not, because it does not depend on the agent recognizing what a command does ([[1]](#references)).

## Codex

Codex separates the same two questions into two settings ([[4]](#references), [[5]](#references)).

- `sandbox_mode` decides what is technically possible: `read-only` allows inspection but no edit, `workspace-write` allows edits inside the workspace, and `danger-full-access` removes the boundary.
- `approval_policy` decides when the user is asked, for example `on-request` or `never`.

`sandbox_mode` can be set per custom subagent, so a subagent can be marked read-only in its own definition file ([[6]](#references)). That is a stronger guarantee than any frontmatter field on the other platforms, because the sandbox is enforced outside the agent.

Codex does not document `allowed-tools` as a `SKILL.md` frontmatter field.

## Copilot

Copilot honors `allowed-tools` in `SKILL.md`, and it is a pre-approval rather than a restriction: a tool that is not listed causes a confirmation prompt instead of being unavailable ([[7]](#references)). The documentation warns that pre-approving shell commands removes the confirmation step and lets an attacker-controlled skill or a prompt injection run arbitrary commands.

No deny list is documented.

## Cursor

Cursor does not document `allowed-tools` as a `SKILL.md` frontmatter field ([[8]](#references)), so a grant written there is not honored and no frontmatter restriction is available.

## Cross-platform summary

| Platform | Pre-approval in `SKILL.md` | Restriction in `SKILL.md` | Restriction outside `SKILL.md`      | OS-level sandbox      |
| -------- | -------------------------- | ------------------------- | ----------------------------------- | --------------------- |
| Claude   | `allowed-tools`            | `disallowed-tools`        | deny / ask rules, `PreToolUse` hook | Bash and its children |
| Codex    | not documented             | none                      | `sandbox_mode`, `approval_policy`   | yes, and per subagent |
| Copilot  | `allowed-tools`            | none documented           | none documented                     | not documented        |
| Cursor   | not honored                | none documented           | none documented                     | not documented        |

Only Claude and Codex can make an action impossible, and they do it through different fields. No mechanism for doing so is portable.

## What this project relies on

- `allowed-tools` is required by this project as the **declaration of intent**, not as the enforcement. See [format.md](./format.md#allowed-tools).
- A `SubAgent` additionally declares the Claude fields that restrict, and is written so that it stays read-only on the platforms that offer no restriction. See [sub-agent.md](./sub-agent.md).
- No skill may depend on a rule stated only in prose. Prose describes what should happen; it does not decide what can.

## References

- [1](https://code.claude.com/docs/en/permissions)
- [2](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- [3](https://code.claude.com/docs/en/skills#frontmatter-reference)
- [4](https://developers.openai.com/codex/concepts/sandboxing)
- [5](https://developers.openai.com/codex/permissions)
- [6](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [7](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [8](https://cursor.com/docs/context/skills#frontmatter-fields)
