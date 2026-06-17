# .cursorrules Fragment — tw-ai-toolkit base rules

> Copy the block below into your repo's `.cursorrules` file.
> This is the ready-to-use version of `rules/cursor-base/rule.md`.

---

```
# tw-ai-toolkit

This repo uses tw-ai-toolkit. On every session:

Context loading:
- Read .ai/AGENTS.md first — it tells you what toolkit components are available
- Check .ai/toolkit/context/CHECKPOINT.md for snapshot freshness (compare git_hash to HEAD)
- Load .ai/toolkit/registry.json for the component list — do not scan directories manually
- Load .ai/toolkit/context/snapshots/<type>.snapshot.md for component details when needed

Invocation:
- Toolkit skills and agents use the /tw- prefix (e.g. /tw-sync-context)
- Local repo skills do not use a prefix
- If a skill is not in registry.json, say so — do not improvise

After editing any component file (skills/, agents/, prompts/, rules/, hooks/, mcp/):
- Run: bash .ai/toolkit/scripts/sync-registry.sh && bash .ai/toolkit/scripts/sync-snapshots.sh
- Never manually edit: registry.json, context/snapshot.md, context/snapshots/, context/CHECKPOINT.md
```
