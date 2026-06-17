# CLAUDE.md Fragment — tw-ai-toolkit base rules

> Copy the block below into your repo's `CLAUDE.md` file.
> This is the ready-to-use version of `rules/claude-base/rule.md`.

---

```markdown
## AI Toolkit (tw-ai-toolkit)

This repo uses tw-ai-toolkit. Follow these rules in every session:

### Context Loading

1. Read `.ai/AGENTS.md` at session start — this tells you what toolkit components are available.
2. Check `.ai/toolkit/context/CHECKPOINT.md`:
   - Compare `git_hash` field against `git rev-parse --short HEAD` in `.ai/toolkit/`
   - If they differ, warn: "Toolkit snapshots may be stale — run `/tw-sync-context`"
3. Load `.ai/toolkit/registry.json` when you need the component list. Do NOT scan directories manually.
4. Load `.ai/toolkit/context/snapshots/<type>.snapshot.md` only when working with that component type.

### Invoking Components

- Toolkit skills and agents: `/tw-<name>` prefix (e.g. `/tw-sync-context`)
- Local repo skills: no prefix
- If a skill does not exist in registry.json, say so — do not improvise

### After Editing Any Component File

1. Run `/tw-lint-component <path>` to validate
2. Run `/tw-sync-context` to update the registry and snapshots
3. Never manually edit these auto-generated files:
   - `registry.json`
   - `context/snapshot.md`
   - `context/snapshots/*.snapshot.md`
   - `context/CHECKPOINT.md`

### Creating New Components

Always use `/tw-scaffold-component type=<type> name=<name>` — never create component files from scratch.
```
