# `mock-host-sandbox` regression fixture

A devcontainer that mocks a host machine and checks:

- `.claude/settings.json` provides devcontainer-like isolation
- but it never succeeds in enumerating and protecting all credentials and personal information on the host machine

```bash
devcontainer up && devcontainer exec bash
```

Inside the container, user `vscode` and `$HOME/workspace` plays the role of a developer's home directory. Authenticate `claude` and `gh`, and then run the verification with the `/verify-mock-host-sandbox` skill from inside the container.

## Note

Tested against `claude:2.1.245`
