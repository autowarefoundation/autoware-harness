# Agent Prompt

This document describes development rules for **this project**. Distributed skills under `./skills/` are bound to the design rules under [project document](./docs/).

## Hooks

- Run the `pre-commit` command to apply the Git hooks
- Use `/pre-commit` _agent skill_ to lint semantic problems
- When a worktree branch is merged, remove both the worktree and the branch

## Development

Refer to [design.md](./docs/design.md) at first to understand the repository scope and structure.

Then refer to [contributing.md](./docs/contributing.md) and run `/create-new-skill` when one develops new skills.

### Git strategy

To avoid the accident in which multiple agents (including the user themselves) edit same files simultaneously and mix up each other's task, the agent must create a Git worktree (under `.agents/worktrees`) when they start _edit_ step.

**Request user approval** in following situations:

- before merging worktree branches into the feature branch

When making a commit, always add `--signoff` flag.

### PR process

When an agent creates a PR, it must

- apply the [hooks](#hooks)
- create the PR following `.github/pull_request_template.md`
- submit it as a draft PR. Leave it draft until the maintainer opens it up, or until the user gives approval from the prompt and tells the agent to mark it as ready.
