# Skill Template

Use this template to create a new skill.

## Steps

1. Copy this directory:
   ```bash
   cp -r skills/_template/ skills/your-skill-name/
   ```

2. Rename the definition file — keep it as `skill.md`.

3. Fill in `skill.md`:
   - Replace all frontmatter fields (the section between `---` delimiters)
   - Replace the body sections with real content
   - Remove sections marked as optional if not needed
   - Delete this README and replace with your own

4. Validate:
   ```
   /tw-lint-component skills/your-skill-name
   ```

5. Run sync to register the component:
   ```bash
   bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh
   ```

## Naming Conventions

- Folder name: `kebab-case`, no `tw-` prefix (e.g. `lint-code`, `sync-context`)
- Invoked as: `/tw-<folder-name>` (prefix added at runtime)
- Name field in frontmatter must match the folder name

## Required Frontmatter Fields

| Field | Description |
|---|---|
| `name` | Must match folder name |
| `description` | One sentence, present tense, starts with a verb |
| `status` | `stable` \| `experimental` \| `deprecated` |
| `version_added` | Toolkit version when introduced (e.g. `v0.1.0`) |
| `compatible_with` | At minimum, declare `claude_code` support |

## Rules

- A skill does ONE thing. If it does two things, split it into two skills.
- Instructions must be deterministic enough that two different models produce consistent output.
- At least one example is required.
- Parameters must be documented both in frontmatter AND in the Parameters table.
