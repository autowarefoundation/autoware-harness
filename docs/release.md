# Release

## Versioning policy

This project follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`. The whole plugin carries a single version; skills are not versioned individually.

- **MAJOR** — a change that breaks an existing agent workflow built on this plugin. Examples: renaming or removing a skill (its `awh-*` name or trigger `description`), removing a skill domain, or changing a plugin manifest field that a coding agent relies on.
- **MINOR** — a backward-compatible addition. Examples: a new skill, a new skill domain, or a new capability added to an existing skill without changing its existing behavior.
- **PATCH** — a backward-compatible fix that does not change a skill's contract. Examples: correcting a skill's instructions, fixing a broken link, or a dependency bump applied by Dependabot.

When unsure which part to bump, treat the change as breaking for the agent workflows described in [design.md](./design.md), and pick the smallest bump that still covers the change.

## Version surface

A release bumps the `version` field of every plugin manifest at once, so all supported coding agents (see [development.md](./development.md)) observe the same version:

- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.github/plugin/plugin.json`
- `.github/plugin/marketplace.json` (`metadata.version` and `plugins[0].version`)

`.claude-plugin/plugin.json` is the source of truth for the current version. The other manifests without a `version` field (`.claude-plugin/marketplace.json`, `.cursor-plugin/marketplace.json`, `.agents/plugins/marketplace.json`) are out of scope, since they carry no version to bump.

## Release procedure

Releasing is a two-step, manually triggered process:

1. **Bump.** A maintainer dispatches the [`version-bump`](../.github/workflows/version-bump.yaml) workflow from `main` and picks `major`, `minor`, or `patch`. The workflow computes the next version from the current one, updates every manifest listed above, and opens a draft pull request against `main`.
2. **Review and merge.** A maintainer reviews the draft pull request like any other change (DCO — Developer Certificate of Origin, `pre-commit`, `semantic-pull-request` checks all run on it), marks it ready, and merges it into `main`.

Merging the release pull request changes `.claude-plugin/plugin.json` on `main`, which triggers the [`tag-release`](../.github/workflows/tag-release.yaml) workflow. That workflow detects the version change, creates the `vMAJOR.MINOR.PATCH` tag, and publishes the corresponding GitHub Release with auto-generated notes.

No release step runs automatically from a regular commit or merge to `main`; a release only happens when a maintainer explicitly dispatches the `version-bump` workflow.

**Note:** `version-bump` opens the pull request with `secrets.RELEASE_PR_TOKEN` when configured, falling back to the default `GITHUB_TOKEN`. A pull request opened with the default `GITHUB_TOKEN` does not trigger other `pull_request`-triggered workflows (DCO, `pre-commit`, `semantic-pull-request`), so a maintainer must configure `RELEASE_PR_TOKEN` with a token from a real user or GitHub App to keep those checks running on the release pull request.

## Dependency updates

[Dependabot](../.github/dependabot.yml) keeps two kinds of pinned dependencies current, each on a weekly schedule:

- `github-actions` — the actions pinned in `.github/workflows/`.
- `pre-commit` — the hook `rev` values pinned in [`.pre-commit-config.yaml`](../.pre-commit-config.yaml).

Dependabot pull requests go through the same `pre-commit` and `DCO` checks as any other pull request before merging. This project has no `package.json` yet; if one is introduced, add an `npm` entry to `dependabot.yml`.
