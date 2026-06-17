---
name: scaffold-component
description: Creates a new toolkit component from the appropriate template given a type and name.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
tags:
  - scaffolding
  - development
  - maintenance
---

# scaffold-component

## Description

Copies the right `_template/` directory for the given component type, renames it
to the given name, pre-fills the `name` and `version_added` fields in the frontmatter,
and confirms the structure with the user. After scaffolding, runs `/tw-lint-component`
to ensure the new component passes baseline checks before the user starts editing.

## Trigger

When the user says:
- "Create a new [skill/agent/prompt/rule/hook/mcp server] called [name]"
- "Scaffold a [type] component named [name]"
- `/tw-scaffold-component`

## Skills Used

- `/tw-lint-component` — validates the scaffolded component immediately after creation

## Inputs

| Input | Required | Description |
|---|---|---|
| `type` | yes | Component type: `skill`, `agent`, `prompt`, `rule`, `hook`, or `mcp` |
| `name` | yes | Component name in kebab-case, no `tw-` prefix (e.g. `lint-code`, `onboard-repo`) |

## Flow

```
Step 1 — Validate inputs
  Action: Verify `type` is one of the six valid types.
          Verify `name` is kebab-case, no spaces, no `tw-` prefix.
          Verify the target directory does NOT already exist (no overwrite).
  Output: Confirmed valid inputs, or error message.

Step 2 — Determine paths
  Action: Map type to folder and template:
            skill  → skills/   template: skills/_template/
            agent  → agents/   template: agents/_template/
            prompt → prompts/  template: prompts/_template/
            rule   → rules/    template: rules/_template/
            hook   → hooks/    template: hooks/_template/
            mcp    → mcp/      template: mcp/_template/
          Target: <folder>/<name>/
  Output: Confirmed source and destination paths.

Step 3 — Copy template
  Action: Copy the entire _template/ directory to <folder>/<name>/
          using the Bash tool or file operations.
  Output: New directory created with template files.

Step 4 — Pre-fill frontmatter
  Action: In the definition file (skill.md / agent.md / etc.):
          - Replace `name: example-<type>` with `name: <name>`
          - Replace `version_added: v0.1.0` with the current toolkit version
            (read from registry.json's `version` field)
          - Leave all other fields as placeholders for the user to fill
  Output: Frontmatter partially filled.

Step 5 — Validate scaffold
  Action: Run /tw-lint-component <folder>/<name>
  Expected: Errors about placeholder content are EXPECTED at this stage and
            should be listed for the user, not treated as a blocker.
  Output: List of fields and sections the user still needs to fill.

Step 6 — Report to user
  Action: Show the scaffolded structure and a clear next-steps list.
  Output: See Output section below.
```

## Outputs

```
Scaffolded: skills/my-new-skill/
├── skill.md    ← Edit this file to define your skill
└── README.md   ← Update with human documentation

Next steps:
1. Open skills/my-new-skill/skill.md
2. Fill in these required fields:
   - description (currently placeholder)
   - compatible_with.cursor and compatible_with.codex
   - ## When to Use section
   - ## Instructions section
   - ## Examples section (at least one)
3. Run /tw-lint-component skills/my-new-skill to validate
4. Run /tw-sync-context to register the component
```

## Examples

### Create a new skill
```
/tw-scaffold-component type=skill name=review-pr-description
```

### Create a new MCP server
```
/tw-scaffold-component type=mcp name=tw-jira
```

## Notes

- This agent does NOT edit the full component for you — it only copies the template and pre-fills `name`.
- The user is responsible for filling in the content.
- If `name` contains the `tw-` prefix, the agent will strip it and warn the user.
