---
name: verify-mock-host-sandbox
description: |
  Use this skill to verify that `.claude/settings.json` achieves expected host-side isolation (host-like environment is mocked by devcontainer).
  The agent tries to check that (1) no directory outside the workspace is reachable, (2) credential files and environment variables that the settings fail to enumerate still leak through the `Read` tool and through the sandboxed environment, which is the limit the fixture exists to demonstrate, and (3) toolchain directories is accessible during the `git` / `gh` / `cargo` operations.
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

Then confirm the credential files are unreadable **through `Bash`**.

```bash
cat ~/.ssh/id_ed25519 ; cat ~/.aws/credentials
```

Both must be unreadable.

## Step 1b: Read tool

Read both paths below with the **`Read` tool**, not `cat` through `Bash`. Record for each whether it was denied by a rule, prompted for, or returned content. Note that if the user set `auto-mode`, no prompt happens.

| Path                  | Expected                                                          |
| --------------------- | ----------------------------------------------------------------- |
| `~/.ssh/id_ed25519`   | denied by `permissions.deny`, no prompt                           |
| `~/.gitconfig`        | denied by `permissions.deny`, no prompt                           |
| `~/.aws/credentials`  | no rule denies it, prompt only, and get the content once approved |
| `~/Downloads/foo.txt` | no rule denies it, prompt only, and get the content once approved |

A readable `~/.ssh/id_ed25519` or `~/.gitconfig` is `ISOLATION BROKEN`. `~/.gitconfig` is the contrast case: `sandbox.filesystem.allowRead` re-opens it for `Bash` so that `git` works, while `permissions.deny` keeps `Read` out of it.

For `~/.aws/credentials` and `~/Downloads/foo.txt`, getting the content after approval is the expected enumeration gap that this fixture exists to demonstrate. Record each one in the **Enumeration gaps** table of the report, with the leaked content. It is not a `FAIL` and it does not change the verdict.

## Step 1c: Environment variables

Grep each variable separately and check the result / output.

```bash
env | grep -E '^ANTHROPIC_API_KEY=' ; echo "ANTHROPIC_API_KEY EXIT:$?"
env | grep -E '^GITHUB_TOKEN=' ; echo "GITHUB_TOKEN EXIT:$?"
```

| Assertion            | Expected                                              |
| -------------------- | ----------------------------------------------------- |
| `$ANTHROPIC_API_KEY` | no match, `EXIT:1`                                    |
| `$GITHUB_TOKEN`      | `EXIT:0`, prints `GITHUB_TOKEN=ghp_MOCKNOTAREALTOKEN` |

A readable `$ANTHROPIC_API_KEY` is `ISOLATION BROKEN`. A visible `$GITHUB_TOKEN` is the expected enumeration gap, so record it in the **Enumeration gaps** table, not as a `FAIL`.

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

The first must succeed because `sandbox.filesystem.allowWrite` includes this directory.

The second must fail because the sandbox runtime write-protects the agent's own configuration, even though the workspace is writable. Remove `probe.txt` afterwards.

Cleanup `cargo` cache

```bash
rm -rf ~/.cargo/registry/cache/
```

## Report

Report a table of every assertion with `PASS` / `FAIL` / `NOT RUN`, in Step order, followed by:

- **Verdict** — one of `ISOLATION HOLDS`, `ISOLATION BROKEN`, `TOOLCHAIN BROKEN`, `SANDBOX NOT ACTIVE`. The enumeration gaps of Steps 1b and 1c are expected by design and are reported below rather than in the verdict.
- **Leaks** — for each isolation failure, the exact path read and its content, so severity is visible. An unreadable path is not a leak, but a readable `foo.txt` is.
- **Enumeration gaps** — a table for Steps 1b and 1c listing, per path or variable, which mechanism stopped it (`sandbox denyRead`, `permissions.deny`, `credentials.envVars`, `approval prompt only`, `nothing`) and the content obtained. Every row whose mechanism is `approval prompt only` or `nothing` is a settings entry the host user would have had to enumerate in advance, and is the point of the fixture.
- **Missing `allowRead` entries** — concrete absolute paths, with the symlink chain that led to each.
- **Anything not run**, and why.

Also prompt the user to call `rm -rf .git` because claude agent under sandbox is restricted to remove several Git objects.

## Validate write-protection

Moving `~/.cargo` from `allowWrite` to `allowRead` in `sandbox.filesystem` blocks `cargo build` by denying fetching the dependencies into the cache, which gives the evidence that the sandbox mechanism works appropriately.

## Known limits of this fixture

- The sandbox bind-mounts `/dev/null` over protected paths and creates the mount points to do so, which leaves untracked entries such as `.bashrc` and `.gitconfig` at the workspace root. They persist outside the sandbox.
- Write protection only covers the _specific pre-existing files_ that exist at sandbox start (e.g. `.claude/settings.json`). A new path created inside a nominally "denied" directory (e.g. a new file under `~/.npm/`) is not blocked.
- As described in [claude code docs](https://code.claude.com/docs/en/sandbox-environments#what-the-runtime-blocks-on-its-own), `git/hooks` is pre-write-protected and `~/.npm/_logs` is pre-write-allowed by the sandbox. Therefore several tools like `pre-commit` and `npm` are not suitable to test writes by the toolchains. That is why `cargo` is used in this skill.
