---
name: lint-component
description: Validates that a toolkit component follows all required conventions and schema rules.
status: stable
version_added: v0.1.0
lint_skip:
  - placeholder_check
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: path
    type: string
    required: true
    default: ""
    description: Relative path to the component directory (e.g. skills/lint-component)
tags:
  - validation
  - quality
  - maintenance
---

# lint-component

## Description

Reads a component's definition file, validates its frontmatter against the required
schema, checks that all mandatory body sections are present and filled, and verifies
no placeholder text from the template remains. Reports a structured list of errors
and warnings.

## When to Use

- Before opening a PR with a new component
- After editing an existing component to verify it's still valid
- As part of the CI pipeline to block malformed components

## Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | yes | — | Relative path to the component directory (e.g. `skills/my-skill`) |

## Instructions

1. Determine the component type from the path prefix (`skills/`, `agents/`, `prompts/`, `rules/`, `hooks/`, `mcp/`).
   If the prefix does not match any known type, report an error and stop.

2. Identify the definition file based on type:
   - `skills/`  → `skill.md`
   - `agents/`  → `agent.md`
   - `prompts/` → `prompt.md`
   - `rules/`   → `rule.md`
   - `hooks/`   → `hook.md`
   - `mcp/`     → `server.md`

3. Read the definition file. If it does not exist, report: `ERROR: definition file not found`.

4. **Validate frontmatter.** Check that the YAML block between `---` delimiters exists and contains:
   - `name` — must be non-empty and match the directory name exactly
   - `description` — must be non-empty, not contain placeholder text
   - `status` — must be one of: `stable`, `experimental`, `deprecated`
   - `version_added` — must match pattern `v\d+\.\d+\.\d+`
   - `compatible_with.claude_code` — must be `full`, `partial`, or `none`
   - Report each missing or invalid field as an individual `ERROR`.

5. **Validate no placeholder text remains.** Scan the entire file for these patterns
   and report each as an `ERROR`:
   - `[REPLACE:`
   - `example-skill`, `example-agent`, `example-prompt`, `example-rule`, `example-hook`, `example-server`
   - `One sentence describing` (indicates description was not replaced)
   - `v0.1.0` in `version_added` if the toolkit is past v0.1.0 (report as `WARNING`)

6. **Validate required body sections** by component type:

   **skill.md** — must contain all headings:
   - `## Description`, `## When to Use`, `## Instructions`, `## Examples`

   **agent.md** — must contain all headings:
   - `## Description`, `## Trigger`, `## Skills Used`, `## Flow`, `## Outputs`

   **prompt.md** — must contain all headings:
   - `## Description`, `## Parameters`, `## Template`, `## Example`
   - Template section must contain at least one `{{variable}}` pattern

   **rule.md** — must contain all headings:
   - `## Description`, `## Applies To`, `## Rule Content`
   - Frontmatter must have `target` field with at least one value

   **hook.md** — must contain all headings:
   - `## Description`, `## Event`, `## Action`, `## Configuration`

   **server.md** — must contain all headings:
   - `## Description`, `## Tools Exposed`, `## Authentication`, `## Setup`

   Report each missing section as an `ERROR`.

7. **Check README.md exists** in the component directory. If missing, report a `WARNING`.

8. **Produce the report** in this format:

   ```
   lint-component: skills/my-skill
   ─────────────────────────────────
   ERROR   frontmatter.name does not match directory name (found "my-skil", expected "my-skill")
   ERROR   description contains placeholder text "One sentence describing"
   WARNING README.md not found in skills/my-skill/
   ─────────────────────────────────
   2 errors, 1 warning

   Status: FAIL
   ```

   If no issues are found:
   ```
   lint-component: skills/my-skill
   ─────────────────────────────────
   No issues found.
   Status: PASS
   ```

9. **If the component is an MCP server**, additionally validate `config.json`:
   - File exists at `mcp/<name>/config.json`
   - Contains `server_name`, `package`, `required_env`, and `tools` fields
   - Each entry in `required_env` has `var` (starting with `TW_`), `maps_to`, and `description`
   - Report missing fields as `ERROR`, missing `TW_` prefix on var names as `WARNING`

10. Exit with status FAIL if there are any ERRORs. WARNINGs do not cause a FAIL.

## Examples

### Passing component
```
/tw-lint-component skills/sync-context
```
Output:
```
lint-component: skills/sync-context
─────────────────────────────────
No issues found.
Status: PASS
```

### Component with errors
```
/tw-lint-component skills/my-new-skill
```
Output:
```
lint-component: skills/my-new-skill
─────────────────────────────────
ERROR   frontmatter.description contains placeholder text "One sentence describing"
ERROR   body section "## Examples" not found
WARNING README.md not found in skills/my-new-skill/
─────────────────────────────────
2 errors, 1 warning

Status: FAIL
```

## Dependencies

- `config/mcp-server.schema.json` — used when linting MCP server components
- `scripts/validate-config.sh` — separate script for validating consumer repo `.ai/config.json`

## Notes

- This skill does NOT run the sync scripts — run `/tw-sync-context` separately after fixing errors.
- The `_template/` directory is excluded from linting.
