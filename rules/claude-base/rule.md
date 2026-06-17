---
name: claude-base
description: Base behavioral rules for Claude Code when working in a repo that uses tw-ai-toolkit.
status: stable
version_added: v0.1.0
target:
  - claude
tags:
  - claude-code
  - base
  - context-loading
---

# claude-base

## Description

Defines how Claude Code should discover, load, and interact with tw-ai-toolkit
components. These rules apply to any repo where the toolkit is installed (`.ai/`
directory is present) or when working inside the toolkit repo itself.

## Applies To

| Assistant | Format | Location |
|---|---|---|
| Claude Code | `CLAUDE.md` fragment | Consumer repo root or toolkit repo root |

## Rule Content

---

### tw-ai-toolkit — Context Loading

When you start a session in a repo that contains a `.ai/` directory or an `AGENTS.md` file:

1. **Load toolkit context first.** Read `.ai/AGENTS.md` (consumer repo) or `AGENTS.md`
   (toolkit repo) before doing anything else. This tells you what components are available.

2. **Check snapshot freshness.** Read `context/CHECKPOINT.md` (or `.ai/toolkit/context/CHECKPOINT.md`
   in consumer repos). Compare the `git_hash` field against the result of running
   `git rev-parse --short HEAD` in the toolkit directory. If they differ, warn the user:
   > "Toolkit snapshots may be stale. Run `/tw-sync-context` to refresh."

3. **Load L2 context on demand.** If you need to know what specific components exist,
   load `registry.json` (L2) rather than scanning the directories manually.
   Load `context/snapshots/<type>.snapshot.md` (L3) only when working with a specific
   component type.

4. **Never scan component directories from scratch** when L2/L3 snapshots exist and are fresh.
   Snapshots exist specifically to avoid this.

---

### tw-ai-toolkit — Component Invocation

- All toolkit skills and agents use the `/tw-` prefix. Example: `/tw-sync-context`.
- Local skills in the consumer repo do NOT use the `/tw-` prefix.
- If asked to run a toolkit skill that does not exist in `registry.json`,
  say so clearly rather than attempting to improvise it.

---

### tw-ai-toolkit — Modifying Components

When you create, edit, or delete any file inside `skills/`, `agents/`, `prompts/`,
`rules/`, `hooks/`, or `mcp/`:

1. Validate the component with `/tw-lint-component <path>` before finishing.
2. Run `/tw-sync-context` after the edit is complete so the registry and snapshots
   stay current.
3. Never manually edit the following auto-generated files — they are overwritten by sync:
   - `registry.json`
   - `context/snapshot.md`
   - `context/snapshots/*.snapshot.md`
   - `context/CHECKPOINT.md`

---

### tw-ai-toolkit — Creating New Components

Always scaffold new components with `/tw-scaffold-component` rather than creating
files from scratch. This ensures the correct template and frontmatter structure.

---

#### Examples

**Compliant — loading context efficiently:**
```
Session starts → read .ai/AGENTS.md → check CHECKPOINT.md hash → proceed
User asks "what skills are available?" → load registry.json → answer from registry
```

**Non-compliant — unnecessary directory scan:**
```
Session starts → ls skills/ → read every skill.md one by one → build context manually
```
(This wastes tokens and ignores the Context Layer System.)

---

## Model-Specific Formats

### Claude Code (`CLAUDE.md` fragment)

Add this block to the consumer repo's `CLAUDE.md`:

```markdown
## AI Toolkit (tw-ai-toolkit)

This repo uses tw-ai-toolkit. Follow these rules in every session:

**Context loading:**
1. Read `.ai/AGENTS.md` at session start
2. Check `.ai/toolkit/context/CHECKPOINT.md` — if git hash is stale, warn and offer to run `/tw-sync-context`
3. Load `registry.json` when you need the component list (not directory scanning)
4. Load `context/snapshots/<type>.snapshot.md` only when working with that component type

**Invocation:**
- Toolkit components: `/tw-<name>` prefix
- Local repo skills: no prefix

**After editing components:**
1. Run `/tw-lint-component <path>`
2. Run `/tw-sync-context`
3. Never manually edit: `registry.json`, `context/snapshot.md`, `context/snapshots/`, `context/CHECKPOINT.md`

**Creating components:** Always use `/tw-scaffold-component type=<type> name=<name>`
```

## Notes

- This rule is always active when the `.ai/` directory or `AGENTS.md` is present.
- Priority: high — these rules take precedence over default Claude Code behavior for context loading.
