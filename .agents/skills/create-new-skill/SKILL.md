---
name: create-new-skill
description: |
  Use this skill to create a new skill for `autoware-harness`.
  Describe the scope of the new skill in the argument.
allowed-tools: Bash Edit Glob Grep Read WebFetch Write
disable-model-invocation: true
---

## Step 1: Roughly search for existing relevant skills

List up `autoware-harness` skills by navigating `skills/` and search for existing skills that are considered to be necessary to meet the given prompt's purpose.

Report all relevant skills found in that process, and articulate

- completely missing elements to achieve the purpose that are worth sharing across Autoware developers
- partially covered elements in the existing `autoware-harness` skills that need to be shared across Autoware developers

If there are no former ones or latter ones are judged to be trivial, this task is already complete.

Otherwise for each element,

- go to Step 2 for former one
- go to Step 3 for latter one

## Step 2: Create new skills

### Front Matter

To create a new skill, refer to `docs/format.md` and prompt the user to input front matter information.

### Body

When the agent creates `SKILL.md`, relevant `references/*.md`, templates, scripts in the 1st step, the agent should just design outlines / overview and **must leave ambiguous / pending parts as TODO**.

The caller themselves is expected to provide their own live knowledge accumulated through development process.

## Step 3: Modify existing skills

Align with `docs/format.md` when adding new information to skills.

## Step 4: Verification

Once above steps are complete, the agent must double check

1. if the `description` field are sufficient and rich enough to summarize the content
2. if the entire document aligns with `docs/format.md`
3. if the change covers what has been missing in Step 1

Repeat update and verification process until all items are complete.
