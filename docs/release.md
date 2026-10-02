# Release

## Versioning policy

This project follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **MAJOR** — a change that breaks an existing agent workflow built on this plugin. Examples: renaming or removing a skill (its `awh-*` name or trigger `description`), removing a skill domain, or changing a plugin manifest field that a coding agent relies on.
- **MINOR** — a backward-compatible addition. Examples: a new skill, a new skill domain, or a new capability added to an existing skill without changing its existing behavior.
- **PATCH** — a backward-compatible fix that does not change a skill's contract. Examples: correcting a skill's instructions, fixing a broken link, or a dependency bump applied by Dependabot.

## Version surface

The Git tag on `main`, not any manifest file, is the source of truth for the current version. A release tag is named `MAJOR.MINOR.PATCH`, with no `v` prefix, which keeps it trivial to parse (`git tag --list --sort=-v:refname | head -n1`). When no such tag exists yet, the current version is treated as `0.0.0`.

A release bumps the `version` field of every plugin manifest at once, so all supported coding agents (see [development.md](./development.md)) observe the same version:

- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.github/plugin/plugin.json`
- `.github/plugin/marketplace.json` (`metadata.version` and `plugins[0].version`)

## Release procedure

Releasing is a two-step process, driven by the single [`version-bump`](../.github/workflows/version-bump.yaml) workflow:

1. **Bump PR and merge.** A maintainer dispatches `version-bump` from `main` (`workflow_dispatch`) and picks `major`, `minor`, or `patch`. Its `bump` job reads the latest `MAJOR.MINOR.PATCH` tag (or `0.0.0` if none exists), computes the next version, and opens a draft pull request against `main`, labeled `release:bump-version`. A maintainer reviews it like any other change (DCO, `pre-commit`, `semantic-pull-request` checks all run on it), marks it ready, and merges it, keeping the label.
2. **Create release.** Merging a pull request labeled `release:bump-version` triggers `version-bump`'s `tag-release` job (`pull_request: closed`). That job compares the manifest's `version` field at the merge commit against the latest existing tag, and if they differ, runs `gh release create`, which both creates the `MAJOR.MINOR.PATCH` tag and drafts the GitHub Release (titled `vMAJOR.MINOR.PATCH`) in one call. A maintainer reviews the draft and publishes it manually.

**Note:** `version-bump`'s `bump` job opens the pull request with a token from `actions/create-github-app-token`, authenticated as a GitHub App via the organization-wide `secrets.APP_ID` / `secrets.PRIVATE_KEY` — the same pattern other `autowarefoundation` projects use (for example `autoware_lanelet2_extension`'s `bump-new-version.yaml`). A pull request opened with the default `GITHUB_TOKEN` would not trigger other `pull_request`-triggered workflows (DCO, `pre-commit`, `semantic-pull-request`), since GitHub suppresses workflow runs caused by the default token; the App token behaves like a real actor, so those checks still run on the release pull request.
