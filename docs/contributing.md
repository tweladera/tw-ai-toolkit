# Contributing Guide — Creating and Contributing Components

This guide explains how to create new components, follow conventions,
and contribute them back to the toolkit.

---

## Before You Start

1. Read `AGENTS.md` to understand the toolkit architecture
2. Read this guide fully before writing any code
3. Check `registry.json` — the component you want might already exist
4. Open an issue first for new agents or MCP servers (discuss before building)

---

## Component Types and When to Use Each

| Use this | When you want to... |
|---|---|
| **Skill** | Automate one specific, reusable action |
| **Agent** | Orchestrate multiple skills for a complex autonomous task |
| **Prompt** | Provide a reusable, parameterizable prompt template |
| **Rule** | Define behavioral constraints for an AI model |
| **Hook** | Trigger automation on an assistant event |
| **MCP Server** | Integrate an enterprise tool via Model Context Protocol |

**Rule of thumb:** If it does more than one thing, it's probably an agent, not a skill.

---

## Creating a New Component

### Step 1 — Copy the template

```bash
# Replace <type> with: skills, agents, prompts, rules, hooks, or mcp
cp -r <type>/_template/ <type>/<your-component-name>/
```

### Step 2 — Fill in required fields

Every component type has a definition file with required and optional fields.
Required fields are marked with `[REQUIRED]` in the template.
Do not leave `[REQUIRED]` fields empty — the linter will catch it.

### Step 3 — Write tests

```bash
cp -r tests/_template/ tests/<your-component-name>/
# Fill in test cases
```

### Step 4 — Validate

```bash
/tw-lint-component <type>/<your-component-name>
```

Fix any errors before opening a PR.

### Step 5 — Update the registry

```bash
bash scripts/sync-registry.sh
bash scripts/sync-snapshots.sh
```

This auto-updates `registry.json` and the context snapshots.

### Step 6 — Open a PR

The CI will run the linter and tests automatically.

---

## Component Naming Conventions

```
Format:     kebab-case
Prefix:     tw- (added automatically at invocation, not in folder name)
Examples:   lint-code, sync-context, onboard-repo, review-pr

Folder:     skills/lint-code/        (no tw- prefix in folder)
Invoked as: /tw-lint-code            (tw- prefix added at runtime)
```

---

## Skill Definition (`skill.md`)

Required fields:

```markdown
# <skill-name>

## Description
[REQUIRED] One sentence describing what this skill does.

## When to Use
[REQUIRED] Describe the trigger condition or use case.

## Parameters
[REQUIRED if any] List all parameters the skill accepts.
| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| param_name | string | yes | — | Description |

## Instructions
[REQUIRED] The actual prompt/instructions the AI model will follow.
Be specific and unambiguous.

## Examples
[REQUIRED] At least one example invocation with expected output.

## Dependencies
[OPTIONAL] Other skills or external tools this skill requires.

## Compatible With
[REQUIRED] List of supported assistants.
- Claude Code: yes
- Cursor: yes/no/partial
- Codex: yes/no/partial

## Status
[REQUIRED] stable | deprecated | experimental
```

---

## Agent Definition (`agent.md`)

Required fields:

```markdown
# <agent-name>

## Description
[REQUIRED] What autonomous task this agent accomplishes.

## Trigger
[REQUIRED] When should this agent be invoked?

## Skills Used
[REQUIRED] List of skills this agent orchestrates.
- /tw-skill-one
- /tw-skill-two

## Flow
[REQUIRED] Step-by-step description of the agent's execution flow.

## Inputs
[REQUIRED if any] What the agent needs to start.

## Outputs
[REQUIRED] What the agent produces when done.

## Compatible With
[REQUIRED] Same format as skill.

## Status
[REQUIRED] stable | deprecated | experimental
```

---

## Prompt Definition (`prompt.md`)

```markdown
# <prompt-name>

## Description
[REQUIRED] What this prompt template is for.

## Parameters
[REQUIRED if any] Variables in the template use {{double_braces}}.

## Template
[REQUIRED] The actual prompt. Use {{variable}} for parameters.

## Example
[REQUIRED] Filled example with real values.

## Status
[REQUIRED] stable | deprecated | experimental
```

---

## Hook Definition (`hook.md`)

```markdown
# <hook-name>

## Description
[REQUIRED] What this hook does.

## Event
[REQUIRED] Which assistant event triggers this hook.
Examples: PreToolUse, PostToolUse, Stop, Notification

## Condition
[OPTIONAL] Additional condition to filter when the hook fires.

## Action
[REQUIRED] The command or script executed when the hook fires.

## Configuration
[REQUIRED] How to add this hook to settings.json.

## Status
[REQUIRED] stable | deprecated | experimental
```

---

## Deprecating a Component

When a component needs to be removed or replaced:

1. Change its `Status` field to `deprecated`
2. Add a `Deprecated Since` field with the current version
3. Add a `Removed In` field with the planned major version for removal
4. Add a `Replacement` field pointing to the new component
5. Run `sync-registry.sh` to update `registry.json`
6. Add an entry to `CHANGELOG.md`

The component will continue to work but will warn users when invoked.

**Never remove a component in a minor or patch release.**

---

## Code Quality Standards

- All content in English
- No secrets or credentials in component files
- Every component must have at least one test case
- Skills must be atomic (one responsibility)
- Instructions must be specific enough that two different models produce consistent output
- Components must declare their compatibility explicitly

---

## Changelog Format

Add an entry to `CHANGELOG.md` for every new component, deprecation, or breaking change:

```markdown
## [v1.1.0] — 2026-06-17

### Added
- `skills/tw-lint-code` — Lints code following project conventions

### Deprecated
- `skills/tw-old-lint` → replaced by `skills/tw-lint-code` (removed in v2.0.0)

### Fixed
- `agents/tw-onboard-repo` — Fixed incorrect path resolution on Windows
```
