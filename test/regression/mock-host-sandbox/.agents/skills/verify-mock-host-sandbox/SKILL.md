---
name: verify-mock-host-sandbox
description: |
  Use this skill to verify that `.claude/settings.json` achieves expected host-side isolation (host-like environment is mocked by devcontainer).
  The agent tries to check that (1) no directory outside the workspace is reachable and (2) toolchain directories is accesible during the `git` / `gh` / `cargo` operations.
  Call this skill from `~/workspace` after the user has authenticated `claude` and `gh`.
allowed-tools: Bash Read Grep Glob
disable-model-invocation: true
---

This skill is tailored for claude code.

## Step 0: Check if sandbox is active

```bash
claude sandbox status
grep -E 'Seccomp|NoNewPrivs' /proc/self/status
```

Pass criteria:

- `claude sandbox status` should report `"enabled":true` and lists no missing dependencies in the JSON format.
- `/proc/self/status` shows a non-zero `Seccomp` and `NoNewPrivs: 1`.

If either fails, report `SANDBOX NOT ACTIVE` and terminate.

Then setup dummy Git log

```bash
git init --quiet --initial-branch=main
git add --all
git -c commit.gpgsign=false commit --quiet --signoff -m "chore: initial commit"
```

## Step 1: Isolation

Run following commands and assert that denied entries are surely unreadable.

```bash
ls ~/Downloads/ ; ls ~/Documents/ ; ls ~/ ; ls ~/workspace
cat ~/Downloads/foo.txt
```

| Assertion                      | Expected                              |
| ------------------------------ | ------------------------------------- |
| `~/Downloads/`, `~/Documents/` | `No such file or directory`           |
| `~/Downloads/foo.txt`          | unreadable                            |
| `~/`                           | lists nothing all but allowed entries |
| `~/workspace`                  | lists the fixture normally            |

Then confirm following files are unreadable.

```bash
cat ~/.ssh/id_ed25519 ; cat ~/.aws/credentials
```

## Step 2: Toolchain

```bash
git --version && git log --oneline -1 && git config user.email
gh --version && gh auth status
cargo --version && rustc --version
```

Pass criteria:

- `git config user.email` must print `mock-host@example.invalid`, which lives in `~/.gitconfig` inside the masked home and therefore only works if `allowRead` allows it.
- `gh` executes and has access to `~/.config/gh/`.
- `cargo`/`rustc` report their versions

```bash
cd ~/workspace
cargo build
ls ~/.cargo/registry/cache/*/*.crate 2>&1 && echo "dependency fetch + ~/.cargo write: OK"
rm -rf target Cargo.lock
```

## Step 3: Asserted failures

```bash
touch ~/workspace/probe.txt && echo "workspace writable"
printf '\n' >> .claude/settings.json
```

The first must succeed, the second must fail (`.claude/settings.json` is bind-mounted read-only even though it sits inside the writable workspace, because it defines the agent's own permissions). Remove `probe.txt` afterwards.

Finanlly, cleanup Git setup

```bash
rm -rf .git
rm -rf ~/.cargo/registry/cache/
```

## Report

Report a table of every assertion with `PASS` / `FAIL` / `NOT RUN`, in Step order, followed by:

- **Verdict** — one of `ISOLATION HOLDS`, `ISOLATION BROKEN`, `TOOLCHAIN BROKEN`, `SANDBOX NOT ACTIVE`.
- **Leaks** — for each isolation failure, the exact path read and its content, so severity is visible. An unreadable path is not a leak, but a readable `foo.txt` is.
- **Missing `allowRead` entries** — concrete absolute paths, with the symlink chain that led to each.
- **Anything not run**, and why.

Also prompt the user to call `rm -rf .git` because claude agent under sandbox is restricted to remove several Git objects.

## Validate write-protection

Moving `~/.cargo` from `allowWrite` to `allowRead` in `sandbox.filesystem` blocks `cargo build` by denying fetching the dependencies into the cache, which gives the evidence that the sandbox mechanism works appropriately.

## Known limits of this fixture

- The sandbox bind-mounts `/dev/null` over protected paths and creates the mount points to do so, which leaves untracked entries such as `.bashrc` and `.gitconfig` at the workspace root. They persist outside the sandbox.
- Read/Write protection only covers the _specific pre-existing files_ that exist at sandbox start (e.g. `~/.ssh/id_ed25519`, `.claude/settings.json`). A new path created inside a nominally "denied" directory (e.g. `~/.ssh/config`, a new file under `~/.npm/`) is not blocked.
- As described in [claude code docs](https://code.claude.com/docs/en/sandbox-environments#what-the-runtime-blocks-on-its-own), `git/hooks` is pre-write-protected and `~/.npm/_logs` is pre-write-allowed by the sandbox. Therefore several tools like `pre-commit` and `npm` are not suitable to test writes by the toolchains. That is why `cargo` is used in this skill.
