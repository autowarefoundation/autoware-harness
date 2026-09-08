# `mock-host-sandbox` regression fixture

A devcontainer that mocks a host machine and checks:

- `.claude/settings.json` provides devcontainer-like isolation
- but it never succeeds in enumerating and protecting all credentials and personal information on the host machine

```bash
devcontainer up && devcontainer exec bash
```

Inside the container, user `vscode` and `$HOME/workspace` plays the role of a developer's home directory. Authenticate `claude` and `gh`, and then run the verification with the `/verify-mock-host-sandbox` skill from inside the container.

## What the fixture plants, and what protects it

`Bash` is governed by `sandbox.filesystem`, where `denyRead: ["~/"]` covers the whole home directory. `Read` / `Grep` / `Glob` are governed by `permissions`, where rules are evaluated deny-first, so the same blanket cannot be written and each path has to be named. The settings name most of them and forget one.

| Planted by `post_create.sh`    | Named in the settings                     | `Bash`                           | `Read`                           |
| ------------------------------ | ----------------------------------------- | -------------------------------- | -------------------------------- |
| `~/Downloads/`, `~/Documents/` | no                                        | denied by `denyRead: ["~/"]`     | prompt only                      |
| `~/.ssh/id_ed25519`            | `permissions.deny`                        | denied by `denyRead: ["~/"]`     | denied by rule                   |
| `~/.aws/credentials`           | **no — the forgotten entry**              | denied by `denyRead: ["~/"]`     | **prompt only, then readable**   |
| `~/.gitconfig`, `~/.config/gh` | `permissions.allow` + sandbox `allowRead` | readable, as the toolchain needs | readable, as the toolchain needs |

The `~/.aws/credentials` row is the deliberate leak. It is as sensitive as `~/.ssh/id_ed25519` and sits beside it in the same home directory, and `Bash` stops both alike — but nobody wrote it into `permissions.deny`, so through `Read` nothing but the approval prompt stands in the way.

Environment variables have no blanket rule at all — `sandbox.credentials.envVars` protects exactly the names written into it:

| Injected by `remoteEnv` | Named in `credentials.envVars` | Visible to a sandboxed command |
| ----------------------- | ------------------------------ | ------------------------------ |
| `ANTHROPIC_API_KEY`     | yes                            | no                             |
| `GITHUB_TOKEN`          | **no**                         | **yes, in full**               |

These settings are therefore **not** a policy to copy, and the gaps must not be closed by extending the lists: the fixture would then only show that a list can name the entries already written into it. See [`docs/security.md`](../../../docs/security.md) for the argument this supports.

## Note

Tested against `claude:2.1.245`
