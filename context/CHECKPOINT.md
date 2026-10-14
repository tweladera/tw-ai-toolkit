# Context Checkpoint

This file tracks the freshness of the Context Layer System snapshots.
AI models should check this file before relying on L2/L3 snapshots.

## Current Snapshot State

| Field | Value |
|---|---|
| **Last sync** | 2026-10-14 20:42 UTC |
| **Git hash at sync** | `83fef568` |
| **Toolkit version** | 0.5.0 |
| **Components indexed** | 49 |
| **Snapshot files** | `context/snapshot.md`, `context/snapshots/` |

## How to Check Freshness

Run in the toolkit repo root:
```bash
git rev-parse --short HEAD
```

If the result does not match `83fef568`, snapshots are stale. Regenerate:
```bash
bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh
```

Or use the skill once available:
```
/tw-sync-context
```

## Auto-sync

The pre-commit git hook in this repo regenerates snapshots automatically
whenever component files are staged. Install it once with:
```bash
bash scripts/install-git-hooks.sh
```
