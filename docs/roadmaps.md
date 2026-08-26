# Roadmaps

## Project Scaffold

### Front matter linter

A machine check that enforces front matter style in [format.md](./format.md).

### Evaluation of skills

A `description` is the only thing that decides whether a skill is picked up, so it needs a regression test rather than a one-off review.

Scope:

- for each skill, keep at least one prompt that **must** trigger it and one nearby prompt that
  **must not** trigger it
- run them on a fresh context and diff the invoked skill against the expectation

Candidate tooling: `claude plugin eval` and `/skill-doctor` on the Claude side. Since this project targets four platforms, the eval definition should stay platform-neutral (plain prompt/expectation pairs) even if only one runner exists at first.

### Versioning and release

- versioning policy (semantic versioning, and what counts as a breaking change for a skill)
- release procedure that bumps every plugin manifest consistently
  (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `.github/plugin`, `.agents/plugins/marketplace.json`)

## Skill Capability

The goal of this project is for an agent to complete a real Autoware development task on its own, using only the skills distributed here.

We use that as our quality metric. There are still a lot of tacit knowledge among Autoware development: naming and design conventions, debugging / integration know-how, release cycle.

Currently that knowledge is held by a small number of long-time developers, and a newcomer or an external contributor has no dependable way to reach it. But if an agent can finish a task unattended, it shows that such tacit knowledge and the process behind that task have been captured as skills — and once it's captured, it can be shared across the team.

The more complex the task, the more has been captured. Therefore we measure `autoware-harness` by the complexity of the tasks an agent can complete autonomously, not by the number of skills it ships.

The effect compounds. Once a domain is covered by skills, any developer can work in it through an agent without spending months catching up its context. Capturing each step as an explicit skill also makes the development process itself clear and reproducible, which makes the next piece of tacit knowledge easier to extract.
