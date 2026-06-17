# Agent Template

Use this template to create a new agent.

## Steps

1. Copy this directory:
   ```bash
   cp -r agents/_template/ agents/your-agent-name/
   ```

2. Fill in `agent.md` — replace all placeholder content.

3. Validate:
   ```
   /tw-lint-component agents/your-agent-name
   ```

4. Run sync:
   ```bash
   bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh
   ```

## Agent vs Skill — When to use each

| Use a Skill when... | Use an Agent when... |
|---|---|
| The task is atomic (one action) | The task requires multiple steps |
| The output is deterministic | The agent needs to make decisions mid-flow |
| No branching logic needed | Different inputs lead to different execution paths |
| Can be described in one instruction | Requires orchestrating 2+ other skills |

## Required Frontmatter Fields

Same as skills: `name`, `description`, `status`, `version_added`, `compatible_with`.

## Rules

- An agent must declare every skill it uses in the "Skills Used" section.
- The Flow must be specific enough that the model can follow it without ambiguity.
- Define failure behavior explicitly — what should the agent do when a step fails?
- Agents should ask for confirmation before irreversible actions unless the user
  has explicitly granted full autonomy.
