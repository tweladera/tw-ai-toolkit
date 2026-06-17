---
name: sync-context
description: Regenerates the toolkit registry and context snapshots from current component files.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: force
    type: boolean
    required: false
    default: "false"
    description: Force regeneration even if no component files appear to have changed
tags:
  - context
  - maintenance
  - registry
---

# sync-context

## Description

Runs the two sync scripts that keep the Context Layer System up to date:
`sync-registry.sh` scans all component directories and rebuilds `registry.json`,
then `sync-snapshots.sh` reads the registry and regenerates `context/snapshot.md`,
all L3 snapshots, and `context/CHECKPOINT.md`.

Run this after adding, modifying, or removing any toolkit component, or whenever
a model reports that its context seems stale.

## When to Use

- After creating or modifying a component file (`skill.md`, `agent.md`, etc.)
- When `context/CHECKPOINT.md` git hash does not match `git rev-parse --short HEAD`
- When the model's knowledge of available components seems outdated
- After pulling new changes from the remote toolkit repo

## Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `force` | boolean | no | false | Run sync even if no component changes detected |

## Instructions

1. Determine the toolkit root:
   - If running inside the `tw-ai-toolkit` repo: current working directory is the toolkit root.
   - If running from a consumer repo: toolkit root is `.ai/toolkit/`.

2. Run the registry sync:
   ```bash
   bash <toolkit-root>/scripts/sync-registry.sh
   ```

3. Run the snapshot sync:
   ```bash
   bash <toolkit-root>/scripts/sync-snapshots.sh
   ```

4. After both scripts complete successfully, read `context/CHECKPOINT.md` and
   report to the user:
   - How many components are now indexed (total)
   - The new git hash
   - The timestamp of the sync

5. If either script fails, report the exact error output and do not proceed with
   the second script. Tell the user what likely caused the failure.

## Examples

### Basic — run from toolkit root
```
/tw-sync-context
```
Output:
```
Context synced.
- 7 components indexed (3 skills, 2 agents, 1 prompt, 1 rule)
- Hash: a1b2c3d4
- Synced at: 2026-06-17 14:00 UTC
```

### From consumer repo
```
/tw-sync-context
```
The skill detects it's in a consumer repo and runs the scripts from `.ai/toolkit/`.

## Dependencies

- `scripts/sync-registry.sh`
- `scripts/sync-snapshots.sh`

## Notes

- The pre-commit git hook runs this automatically on every commit that touches component files.
  You only need to run this manually when working outside of git commits.
- This skill only updates the registry and snapshots — it does not modify component files.
