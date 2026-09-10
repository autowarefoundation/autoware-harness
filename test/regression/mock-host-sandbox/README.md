# `mock-host-sandbox` regression fixture

A devcontainer that mocks a host machine and checks:

- `.claude/settings.json` provides devcontainer-like isolation
- but it never succeeds in enumerating and protecting all credentials and personal information on the host machine

```bash
devcontainer up && devcontainer exec bash
```

Inside the container, user `vscode` and `$HOME/workspace` plays the role of a developer's home directory. Authenticate `claude` and `gh`, and then run the verification with the `/verify-mock-host-sandbox` skill from inside the container.

## What the fixture tests

Following files are created to mock host environment, and `sandbox`(for `Bash`) feature isolates `"~/"` at first, and them expose required ones like `~/.gitconfig`.

However, if `permission`(for `Read`) denies `"~/"` at first, allowing `~/.gitconfig` later is not effective and it remains denied. This asymmetric behavior forces the host user to

- allow working directory, which is located somewhere under `~/` most of the time,
- deny credentials like `~/.config/gh` one by one

and end up forgetting to enumerate other credentials.

| Created by `post_create.sh`    | `Bash`                              | `Read`                                     |
| ------------------------------ | ----------------------------------- | ------------------------------------------ |
| `~/Downloads/`, `~/Documents/` | denied access by `denyRead: ["~/"]` | prompt only, then readable                 |
| `~/.ssh/id_ed25519`            | denied access by `denyRead: ["~/"]` | denied by rule                             |
| `~/.aws/credentials`           | denied access by `denyRead: ["~/"]` | prompt only, then readable                 |
| `~/.gitconfig`, `~/.config/gh` | `allowRead` for `git, gh`           | `permissions.allow` as the toolchain needs |

`~/.aws/credentials` is deliberate leak. It is as sensitive as `~/.ssh/id_ed25519` and sits beside it in the same home directory, and `Bash` stops both alike, but it is still open to `Read`.

`sandbox.credentials.envVars` only protects the names enumerated in it:

| Injected by `remoteEnv` | Named in `credentials.envVars` | Visible to a sandboxed command |
| ----------------------- | ------------------------------ | ------------------------------ |
| `ANTHROPIC_API_KEY`     | yes                            | no                             |
| `GITHUB_TOKEN`          | no                             | yes, in full                   |

## Note

Tested against `claude:2.1.245`
