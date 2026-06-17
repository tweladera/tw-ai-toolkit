---
name: cursor-base
description: Base behavioral rules for Cursor when working in a repo that uses tw-ai-toolkit.
status: stable
version_added: v0.1.0
target:
  - cursor
tags:
  - cursor
  - base
  - context-loading
---

# cursor-base

## Description

Defines how Cursor should discover, load, and interact with tw-ai-toolkit components.
Adapted from `claude-base` to fit Cursor's context system (`.cursorrules` and Cursor Composer).

## Applies To

| Assistant | Format | Location |
|---|---|---|
| Cursor | `.cursorrules` fragment | Consumer repo root |

## Rule Content

---

### tw-ai-toolkit — Context

This repo uses tw-ai-toolkit. When you start a session:

1. Check if `.ai/AGENTS.md` exists. If so, read it — it contains the toolkit overview.
2. Check `.ai/toolkit/context/CHECKPOINT.md` for snapshot freshness.
   If the hash is stale, suggest running: `bash .ai/toolkit/scripts/sync-registry.sh && bash .ai/toolkit/scripts/sync-snapshots.sh`
3. The full component list is in `.ai/toolkit/registry.json`.
   Load it when you need to know what tools are available instead of scanning directories.

### Invocation

- Toolkit components use the `/tw-` prefix (e.g. `/tw-sync-context`)
- These are defined in `.ai/toolkit/skills/` and `.ai/toolkit/agents/`
- Local skills in this repo do not use the `/tw-` prefix

### After Editing Components

After modifying any file inside `skills/`, `agents/`, `prompts/`, `rules/`, `hooks/`, or `mcp/`:
- Run: `bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh`
- Do not manually edit `registry.json` or any file in `context/`

---

## Model-Specific Formats

### Cursor (`.cursorrules` fragment)

Add this block to the consumer repo's `.cursorrules`:

```
# tw-ai-toolkit

This repo uses tw-ai-toolkit. When starting a session:
- Read .ai/AGENTS.md for toolkit context
- Check .ai/toolkit/context/CHECKPOINT.md for snapshot freshness
- Load .ai/toolkit/registry.json for the full component list (don't scan directories)

Toolkit components use the /tw- prefix.
After editing component files, run:
  bash .ai/toolkit/scripts/sync-registry.sh && bash .ai/toolkit/scripts/sync-snapshots.sh

Never manually edit: registry.json, context/snapshot.md, context/snapshots/, context/CHECKPOINT.md
```

## Notes

- Cursor has partial support for slash commands — invocation of `/tw-*` skills
  depends on Cursor's command system configuration.
- For full toolkit support, prefer Claude Code as the primary assistant.
