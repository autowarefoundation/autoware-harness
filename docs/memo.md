# Memo

From other working branches

## Part 1

`context: fork`, `agent` and `disallowed-tools` are Claude extensions, and `allowed-tools` is not portable either: Cursor does not document it as a `SKILL.md` front matter field, and Codex does not document it at all (see [permission.md](./permission.md). Codex can make a write impossible through `sandbox_mode = "read-only"` on a custom subagent, not a skill).

A `SubAgent` skill therefore degrades on the other platforms: it runs in the caller's context instead of an isolated one. That loses the isolation but **not the guardrail**, because the user is present in the caller's context and can approve. The write prohibition is the part that must survive, and it does.

Do not try to recover the isolation with a prompt in the body that asks the agent to re-run itself in an isolated context. Such a prompt is read only after the body has already entered the main context, so it cannot restore the isolation it asks for, and an instruction in prose cannot create a permission boundary that the harness does not enforce. If a platform ever needs genuine isolation, distribute the same body through that platform's `agents` manifest field instead, which is a packaging problem rather than a prompt problem (see [platform.md](./platform.md)).

## Part 2

On guardrail

`SubAgent` runs in a new context and never receives user messages, so it cannot obtain user approval. An instruction such as "ask the user before applying the changes" is a step it **cannot perform**. A `SubAgent` that is able to write therefore edits without approval, and it may report back that approval was given.

`allowed-tools` alone does not prevent this. In Claude Code the field pre-approves tools rather than restricting them:

> It does not restrict which tools are available: every tool remains callable, and your permission settings still govern tools that are not listed. ([[1]](#references))

`allowed-tools` just provides user convenience for avoiding repetitive interruptions for approval.

Two fields do restrict, and a `SubAgent` needs both.

| Field              | Effect                                                                                                                                                                                                                                                                                                | Reference          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `agent`            | With `context: fork`, the agent type "determines the execution environment (model, tools, and permissions)". It **defaults to `general-purpose`, which holds every tool**, so omitting it grants full write access. Use `agent: Explore`, whose tool set excludes `Edit`, `Write` and `NotebookEdit`. | [[2]](#references) |
| `disallowed-tools` | "Tools removed from Claude's available pool while this skill is active." Required in addition to `agent`, because `Explore` still holds `Bash`, and an unrestricted shell can write any file.                                                                                                         | [[3]](#references) |

A `SubAgent` therefore declares its front matter as follows.

```yaml
context: fork
agent: Explore
allowed-tools: Glob Grep Read WebFetch
disallowed-tools: Edit Write NotebookEdit Bash
```

When the `SubAgent` needs to read repository state, drop `Bash` from `disallowed-tools` and narrow the grant to `Bash(git:*)` instead. That grant only removes the approval prompt for those commands, so the shell remains a write path. Keep `Bash` in `disallowed-tools` whenever the task does not need it.

Both `agent` and `disallowed-tools` are Claude extensions, so this enforcement does not carry to other platforms. See [sub-agent.md](./sub-agent.md) for what survives there.

### References

- [1](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- [2](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- [3](https://code.claude.com/docs/en/skills#frontmatter-reference)

### Approval guardrail

A `Skill` and an `Agent` differ in how they clear an action that needs approval, so they need different tool grants.

- A `Skill` runs under an **approval guardrail**. An action that requires user approval, such as editing a file in the repository, must reach the user before it happens.
- An `Agent` **self-approves** inside the task it was given and keeps editing until that task is done. It returns the result to the caller instead of asking mid-task.

A forked skill (`context: fork`) runs in a new context and never receives user messages. Its caller is the only party it can talk to, so it cannot obtain user approval, and an instruction such as "ask the user before applying the changes" is a step it **cannot perform**. A forked skill that also holds a file-mutating tool therefore edits without approval, and it may report back that approval was given.

Declare `allowed-tools` so that the guardrail cannot be skipped.

| `context` | File-mutating tools in `allowed-tools`     | Verdict                                                                        |
| --------- | ------------------------------------------ | ------------------------------------------------------------------------------ |
| `fork`    | None                                       | Allowed. Return the findings and let the caller apply them.                    |
| `fork`    | `Edit`, `Write`, `NotebookEdit`, or `Bash` | Forbidden. The skill can edit before the user ever sees the proposal.          |
| Omitted   | Any                                        | Allowed. The skill runs in the caller's context, so approval reaches the user. |

`Bash` is file-mutating unless it is narrowed to specific commands, because an unrestricted shell can write any file. Prefer `Bash(git:*)` over bare `Bash` when a forked skill only needs to read repository state.

Split a skill that both investigates and edits: fork the investigation, return the proposal, and leave the edit to the caller that can ask the user.

## Part 3

- `agent`: `Explore / Plan` is the 1st option, unless the skill runs `git branch / worktree`
  - TODO: can we limit `Explore / Plan` by making it a rule to create wokrtree outside of the repository ?
- `disallowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited
  - TODO: if the `agent` is `Explore / Plan`, then do we need this to explicitly prohibit Write action ?
- `allowed-tools`: `Edit`, `Write`, `NotebookEdit` and bare `Bash` are prohibited

## References

- [1](https://code.claude.com/docs/en/permissions)
- [2](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- [3](https://code.claude.com/docs/en/skills#frontmatter-reference)
- [4](https://developers.openai.com/codex/concepts/sandboxing)
- [5](https://developers.openai.com/codex/permissions)
- [6](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [7](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [8](https://cursor.com/docs/context/skills#frontmatter-fields)

## Part 4

Review of the four-layer permission design, one configuration example per claim. Verified against the Claude and Codex documentation as of 2026/08/28; each claim carries its source.

### Layer 1: recommend a sandbox in personal or project settings

Sound as a contract, but the boundary is narrower than the layer assumes.

#### What the sandbox is, and what it is not

The name invites two opposite misreadings, and the truth sits between them.

It is **not** a container or a special mount. It is also **not** a filter over Bash command strings, so it is not "the deny and allow rules restricted to `Bash`". It is an operating-system boundary applied to the process that runs the command:

> you define which files and network domains commands can touch, and **the operating system enforces that boundary for every Bash command and its child processes** ([[9]](#references-part-4))

macOS uses Seatbelt, and Linux and WSL2 use `bubblewrap` with an optional seccomp filter ([[9]](#references-part-4)). The axis is therefore the **process**, not the tool and not the command text. Two consequences follow, and they point in opposite directions.

The sandbox is **stronger** than a permission rule inside its scope. Permission rules match on what the agent asks for, so a rule "applies to file commands recognized inside Bash, such as `cat` and `sed`", and does not apply to a subprocess that opens files itself, such as a script ([[1]](#references)). The sandbox has no such gap:

> Comprehensive coverage: restrictions apply to all scripts, programs, and subprocesses spawned by commands ([[9]](#references-part-4))

A `python setup.py` that writes outside the boundary is stopped by the sandbox and is invisible to a permission rule.

The sandbox is **narrower** than a permission rule outside that scope. It never sees the in-process tools, because they are not spawned processes:

> Built-in file tools: Read, Edit, and Write use the permission system directly rather than running through the sandbox. ([[9]](#references-part-4))

So the two layers are not one axis with different strictness. They cover different things, and neither is a superset of the other:

|                  | Bash and its child processes  | `Read`, `Edit`, `Write`, `NotebookEdit` | `WebFetch`, MCP tools |
| ---------------- | ----------------------------- | --------------------------------------- | --------------------- |
| Sandbox          | Yes, enforced by the OS       | No                                      | No                    |
| Permission rules | Yes, on the command text only | Yes                                     | Yes                   |

**Codex is not the same.** Its sandbox uses the same platform-native mechanisms, Seatbelt on macOS and `bubblewrap` on Linux and WSL2, but the documentation describes the scope the other way round: "The sandbox applies to spawned commands, **not just to built-in file operations**" ([[4]](#references)). Its built-in file operations sit inside the boundary rather than beside it, which is why `sandbox_mode = "read-only"` can be described as making a write impossible, with no companion rule needed:

```toml
[agents.reviewer]
sandbox_mode = "read-only"
```

The documentation does not spell out how `apply_patch` is handled, so treat this as the documented intent rather than a verified mechanism. The practical difference for this project stands either way: on Claude the sandbox must be paired with `Read` and `Edit` rules to mean "read-only", and on Codex one setting is meant to carry it.

#### The sandbox does not cover the file tools

> Built-in file tools: Read, Edit, and Write use the permission system directly rather than running through the sandbox. ([[9]](#references-part-4))

This configuration reads as "only the worktrees are writable" and is not:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "denyWrite": ["."],
      "allowWrite": ["./.agents/worktrees"]
    }
  }
}
```

A `bash -c 'echo x > docs/design.md'` call is blocked. An `Edit` call on `docs/design.md` is not, because `Edit` never enters the sandbox. The same intent needs a permission rule as well:

```json
{
  "permissions": {
    "deny": ["Edit(//<project-root>/docs/**)", "Edit(//<project-root>/skills/**)"],
    "allow": ["Edit(//<project-root>/.agents/worktrees/**)"]
  }
}
```

Note the path syntax differs between the two blocks: `sandbox.filesystem` uses `./path` for project-relative and `/tmp/x` for absolute, while `Read` and `Edit` rules use `/path` for project-relative and `//path` for absolute.

#### The two layers write exceptions in opposite directions

This is the easiest thing to get wrong, because the same intent needs an inverted shape in each layer.

**Permission rules are deny-first.** The order is fixed, and being more specific does not rescue an allow rule:

> Rules are evaluated in order: deny, then ask, then allow. The first match in that order determines the outcome, and rule specificity doesn't change the order. ([[1]](#references))

So a broad deny cannot carry an exception. Both blocks below block the project as well:

```json
{
  "permissions": {
    "deny": ["Read(//**)"],
    "allow": ["Read(//<project-root>/**)"]
  }
}
```

The exception has to be written into the deny list itself, by never denying the region you want to keep. An exception is expressed by **omission**, and the list is an enumeration of what is closed.

**Sandbox read rules are specificity-first.** The narrower path wins regardless of which list it is in:

> When read rules overlap, the more specific path wins ([[9]](#references-part-4))

| Configuration                                           | Result                                                                       |
| ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `"denyRead": ["~/"]` with `"allowRead": ["~/projects"]` | `~/projects` is readable and the rest of the home directory stays blocked    |
| `"allowRead": ["~/"]` with `"denyRead": ["~/.env"]`     | `~/.env` stays blocked and the rest of the home directory is readable        |
| `"allowRead": ["~/"]` with `"denyRead": ["~/**/.env"]`  | every `.env` under the home directory stays blocked and the rest is readable |

So the same intent, "nothing outside the project", is a closed enumeration in one layer and a broad deny with a narrow allow in the other:

```json
{
  "permissions": {
    "deny": ["Read(~/.ssh/**)", "Read(~/.aws/**)", "Read(//etc/**)"]
  },
  "sandbox": {
    "filesystem": { "denyRead": ["~/"], "allowRead": ["."] }
  }
}
```

Reading these two blocks as variations of one policy is a mistake. The permission block is a blocklist that is silent about everything it forgot; the sandbox block is an allowlist that is closed by default. The failure modes differ accordingly: an unlisted secret stays readable through the file tools, while a legitimate path outside the project stops working for every subprocess until it is added.

Two qualifications keep this from being a clean symmetry.

- The documentation states the specificity rule for **read** rules. It does not state the same for `allowWrite` and `denyWrite`, so do not assume a narrow `allowWrite` re-opens a region inside a broad `denyWrite`.
- Specificity does not always win in the sandbox either. For the configuration paths the sandbox protects, "there is no way to exempt one of these paths: an `allowWrite` entry or an `Edit` allow rule that covers the path doesn't lift the protection" ([[9]](#references-part-4)).

#### Confining `Read` and `Edit` to the project

There is no single switch for it, and the reason is the evaluation order: rules run deny, then ask, then allow, and "rule specificity doesn't change the order" ([[1]](#references)). A blanket deny with a narrow allow therefore cannot work, because the deny wins everywhere:

```json
{
  "permissions": {
    "deny": ["Read(//**)"],
    "allow": ["Read(//<project-root>/**)"]
  }
}
```

That configuration blocks the project too. Three mechanisms cover the intent instead, and they are complementary.

**1. The default already scopes the file tools, as an ask rather than a deny.** "By default, Claude has access to files in the directory where you launched it", and read-only access needs no approval "within the working directory and additional directories" ([[1]](#references)). A path outside prompts. Keep that boundary by not widening it: no `--add-dir`, no `additionalDirectories`, and a `Cd` rule so the session cannot be moved to another root:

```json
{
  "permissions": {
    "additionalDirectories": [],
    "deny": ["Cd"],
    "allow": ["Cd(//<project-root>/**)"]
  }
}
```

A bare `Cd` deny rule disables `/cd` entirely, and any `Cd` allow rule switches it to allowlist mode ([[1]](#references)). `Cd` is not model-invocable, so this constrains the user rather than the agent.

**2. Deny the outside paths that matter, by enumeration.** Since a blanket deny is unavailable, list them:

```json
{
  "permissions": {
    "deny": [
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.config/gh/**)",
      "Read(//etc/**)",
      "Read(**/.env)",
      "Edit(~/.claude/**)"
    ]
  }
}
```

Two properties help here. A `Read` deny rule also blocks `Edit` and `Write` on the same path, though not `NotebookEdit`, so a path no tool may change needs an `Edit` deny rule as well ([[1]](#references)). And a deny rule "applies when either the symlink path or its target matches", while an allow rule applies "only when both the symlink path and its target match", so a symlink inside the project that points outside it still prompts ([[1]](#references)). The escape route this leaves open is a path nobody listed.

Write these rules with `//` or `~/` anchors when they live in user settings, because a `/path` pattern anchors at the settings source: `Read(/secrets/**)` in `~/.claude/settings.json` matches `~/.claude/secrets/**`, not the project ([[1]](#references)).

**3. For everything below the tools, use the sandbox.** The permission documentation points at it by name:

> Read and Edit deny rules apply to Claude's built-in file tools and to file commands Claude Code recognizes in Bash, such as `cat`, `head`, `tail`, and `sed`. They don't apply to arbitrary subprocesses that read or write files indirectly, like a Python or Node script that opens files itself. For OS-level enforcement that blocks all processes from accessing a path, enable the sandbox. ([[1]](#references))

The sandbox is the one layer that can express "deny the whole home directory, re-open the project", because its read rules resolve by specificity instead of deny-first:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "denyRead": ["~/"],
      "allowRead": ["."]
    }
  }
}
```

"When read rules overlap, the more specific path wins" ([[9]](#references-part-4)), so the narrower allow re-opens that part of the denied region. Place this in the project's `.claude/settings.json`, because `.` resolves to the project root only in project settings ([[9]](#references-part-4)).

**The summary.** The confinement is achievable but assembled, not declared:

| Access path                                          | Confined by                                                                     |
| ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| `Read` and `Edit` inside the project                 | Nothing needed; it is the default working directory                             |
| `Read` and `Edit` outside the project                | An approval prompt by default; a hard block only for paths listed in deny rules |
| `cat`, `sed` and other recognized Bash file commands | The same deny rules, plus the sandbox                                           |
| A script that opens files itself                     | The sandbox only                                                                |
| Moving the project boundary                          | `Cd` rules, and not setting `additionalDirectories`                             |

#### An `Edit` allow rule widens the sandbox as well

> `Edit` allow rules: grant write access to specific paths, the same way `sandbox.filesystem.allowWrite` does. ([[9]](#references-part-4))

These two entries have the same effect on a sandboxed `bash` command:

```json
{
  "sandbox": { "filesystem": { "allowWrite": ["~/.cache/colcon"] } },
  "permissions": { "allow": ["Edit(//home/user/.cache/colcon/**)"] }
}
```

A rule added to remove an approval prompt therefore enlarges what is possible. Layer 3 cannot be described as purely a convenience while this holds. Keep every `Edit` grant path-scoped.

#### Writing to the worktrees needs no configuration

> By default, sandboxed commands can write only to the current working directory and the session temp directory. ([[9]](#references-part-4))

`.agents/worktrees` is inside the working directory, so the empty configuration already allows it:

```json
{ "sandbox": { "enabled": true } }
```

The work in this layer is restriction, not permission.

<!--
ここまで理解．Claudeではsandbox設定はBash()の中身にだけ作用し，Editなどその他のtoolには関係なし．sandboxで $HOME/.cache へのread/writeを禁止するだけでは，Editがそこを弄るのを防げない．両方とも設定が必要になる．
-->

#### Allowing the Docker socket removes the layer

> Allowing access to `/var/run/docker.sock` effectively grants access to the host system through the Docker socket. ([[9]](#references-part-4))

This entry ends the sandbox for practical purposes:

```json
{
  "sandbox": {
    "network": { "allowUnixSockets": ["/var/run/docker.sock"] }
  }
}
```

SSH needs care for a different reason: the default read policy grants "read access to the entire computer, except certain denied directories", `~/.ssh` included. Block it explicitly:

```json
{
  "sandbox": {
    "credentials": {
      "files": [
        { "path": "~/.ssh", "mode": "deny" },
        { "path": "~/.aws/credentials", "mode": "deny" }
      ],
      "envVars": [{ "name": "GITHUB_TOKEN", "mode": "deny" }]
    }
  }
}
```

#### The paths that matter are protected for free

Inside the writable directories the sandbox still denies writes to the paths Claude Code loads configuration and code from, `.claude/skills` included, and "there is no way to exempt one of these paths: an `allowWrite` entry or an `Edit` allow rule that covers the path doesn't lift the protection" ([[9]](#references-part-4)). This has no effect:

```json
{ "sandbox": { "filesystem": { "allowWrite": ["./.claude"] } } }
```

A sandboxed command cannot edit a skill or a hook to widen its own access.

#### A repository can neither disable nor enable the layer

`sandbox.filesystem.disabled` cannot be set from project settings ([[9]](#references-part-4)), so this entry in the repository is ignored:

```json
{ "sandbox": { "filesystem": { "disabled": true } } }
```

A checked-out repository cannot weaken a developer's sandbox, and cannot switch one on either. That is why this layer stays a contract stated in the disclaimer, and why an organization that wants it enforced uses managed settings.

### Layer 2: install hooks cross-platform and fire them for this project's components

Feasible, and closer to the goal than expected, with one asymmetry.

#### A `SubAgent` gets exactly the scoping the layer asks for

> **Subagent hooks**: Claude Code runs them only while that subagent is running and removes them when it finishes. ([[10]](#references-part-4))

The hook is declared in the component itself and travels with it:

```yaml
---
name: awh-review-msg-format
description: Review message definitions and report findings.
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/deny-write.sh"
---
```

The restriction covers the isolated context and nothing else.

#### A `Skill` does not

> **Skill hooks**: Claude Code registers them when you or Claude invoke the skill and keeps running them for the rest of the session, on turns after the skill's own turn as well. To have Claude Code remove a hook after its first successful run instead, set `once: true` on it. ([[10]](#references-part-4))

The same block in a non-forked skill denies `Bash` writes for every later turn as well:

```yaml
---
name: awh-create-package
description: Scaffold a package.
hooks:
  PreToolUse:
    - matcher: "Bash"
      once: true
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/deny-write.sh"
---
```

`once: true` removes the hook after its first successful run, which is a different lifetime, not the one the layer wants. A `Skill` runs in the caller's context where the user is present, so it needs no hook at all: the approval prompt is the guardrail.

#### Scoping comes from where the hook is declared, never from a matcher

`matcher` filters on the tool name for `PreToolUse`, and on the agent type for `SubagentStart` and `SubagentStop` ([[10]](#references-part-4)). No hook input field names the active skill, so there is no way to write "fire only while an `awh-` skill runs" in a settings file. A plugin-level hook can still recognize the caller, because the input carries `agent_id` and `agent_type` when the call comes from a subagent:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/deny-for-subagent.sh" }
        ]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/deny-for-subagent.sh
input=$(cat)
agent_type=$(jq -r '.agent_type // ""' <<<"$input")
case "$agent_type" in
  Explore | Plan)
    jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "SubAgent is read-only"}}'
    ;;
  *) exit 0 ;;
esac
```

#### A hook restricts in one direction only

The script above can deny, through `permissionDecision: "deny"` or exit code 2. It cannot approve what a deny rule blocks, and the documentation says to "use the permission system rather than a hook to enforce a hard allow or deny" ([[10]](#references-part-4)), because the Bash `if` filter is best effort and falls through when a command cannot be parsed.

#### Codex reaches the same events with a coarser scope

Codex `PreToolUse` intercepts Bash and `apply_patch` edits and can return a deny decision, and hooks load from `~/.codex/hooks.json`, `<repo>/.codex/hooks.json`, the `config.toml` files, and plugin manifests ([[11]](#references-part-4)):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "apply_patch",
        "hooks": [{ "type": "command", "command": "./.codex/hooks/deny-write.sh" }]
      }
    ]
  }
}
```

Codex hooks are session- or project-scoped rather than attached to a skill or a subagent, so the deny applies to the whole session. Cross-platform enforcement is realistic for Claude and Codex at that price. Cursor and Copilot are unverified and must be checked before the layer is called cross-platform.

### Layer 3: `allowed-tools` for convenience, `disallowed-tools` for the exceptions

Correct as stated for Claude, with one correction and one caveat.

The correction is the coupling shown in layer 1. This front matter is not free of consequence, because the grant reaches the sandbox boundary as well:

```yaml
allowed-tools: Edit
```

Scope it instead:

```yaml
allowed-tools: Edit(/.agents/worktrees/**) Bash(git:*) Glob Grep Read
```

The caveat is that `disallowed-tools` clears at the next user message and its behavior inside a forked context is not documented. Treat it as a second line behind the `agent` field:

```yaml
context: fork
agent: Explore
disallowed-tools: Edit Write NotebookEdit Bash
```

### Layer 4: is the design sound

Yes. It is the standard defense-in-depth ordering, from the layer the model cannot reach to the layer that only states intent, and it correctly refuses to build a guardrail out of prose. Two adjustments make it hold.

**Add the agent type as the first restriction.** One line decides the tool set of the isolated context, needs no settings file, no hook and no user cooperation:

```yaml
context: fork
agent: Explore
```

It is the only per-invocation control that is enforced and travels inside the component itself, so it belongs above hooks in the design rather than beside `disallowed-tools`. Ordered by how little they can be undone:

| Rank | Mechanism                                                | Distributable     | Enforced                                       |
| ---- | -------------------------------------------------------- | ----------------- | ---------------------------------------------- |
| 1    | OS sandbox                                               | No, a contract    | Yes, outside the agent, Bash and children only |
| 2    | `agent` type on a forked skill                           | Yes               | Yes                                            |
| 3    | Hooks in subagent frontmatter, or in the plugin manifest | Yes               | Yes, deny only                                 |
| 4    | Permission deny and ask rules                            | No, settings only | Yes                                            |
| 5    | `disallowed-tools`                                       | Yes               | Yes, until the next user message               |
| 6    | `allowed-tools`                                          | Yes               | No, it pre-approves                            |
| 7    | Prose in `SKILL.md` or `AGENTS.md`                       | Yes               | No                                             |

**Do not let layer 1 carry a restriction that the file tools bypass.** The layer as written assumes the sandbox is the coarse filter that makes everything above it simple. It is that filter for Bash only. Either state the layer as "Bash and its children are sandboxed, and the file tools are governed by `Read` and `Edit` rules", or accept that a `SubAgent` holding `Edit` is outside layer 1 entirely, which is a further argument for the read-only rule in [sub-agent.md](./sub-agent.md).

### References (Part 4)

- [9](https://code.claude.com/docs/en/sandboxing)
- [10](https://code.claude.com/docs/en/hooks)
- [11](https://learn.chatgpt.com/docs/hooks)
