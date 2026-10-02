# Release

## Versioning policy

This project follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **MAJOR** — a change that breaks an existing agent workflow built on this plugin. Examples: renaming or removing a skill (its `awh-*` name or trigger `description`), removing a skill domain, or changing a plugin manifest field that a coding agent relies on.
- **MINOR** — a backward-compatible addition. Examples: a new skill, a new skill domain, or a new capability added to an existing skill without changing its existing behavior.
- **PATCH** — a backward-compatible fix that does not change a skill's contract. Examples: correcting a skill's instructions, fixing a broken link, or a dependency bump applied by Dependabot.

## Version surface

A release tag is named `MAJOR.MINOR.PATCH`, with no `v` prefix, so `git tag --list --sort=-v:refname | head -n1` parses it directly.

A release bumps the `version` field of every plugin manifest at once, so all supported coding agents (see [development.md](./development.md)) observe the same version:

- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.github/plugin/plugin.json`
- `.github/plugin/marketplace.json` (`metadata.version` and `plugins[0].version`)

## Release procedure

1. **Bump pull request and merge.** A maintainer dispatches `version-bump` from `main` (`workflow_dispatch`) and picks `major`, `minor`, or `patch`. Its `bump` job reads the latest `MAJOR.MINOR.PATCH` tag, computes the next version, and opens a draft pull request against `main`, labeled `release:bump-version`. A maintainer reviews it, marks it ready, and merges it, keeping the label.
2. **Create release.** Merging a pull request labeled `release:bump-version` triggers `version-bump`'s `tag-release` job (`pull_request: closed`). The job reads the manifest's `version` field at the merge commit and runs `gh release create`, which both creates the `MAJOR.MINOR.PATCH` tag and drafts the GitHub Release (titled `vMAJOR.MINOR.PATCH`). A maintainer reviews the draft and publishes it manually.
