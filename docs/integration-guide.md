# Integration Guide — Using tw-ai-toolkit from Another Repo

This guide covers everything needed to install, configure, update, and extend
the toolkit from a consumer repository.

---

## Installation

The toolkit installs **locally only** — nothing is committed or pushed to the consumer repo.
All generated files (`.ai/`, `.claude/skills/`, `.cursor/skills/`, `CLAUDE.md`) are added
to `.gitignore` automatically.

### Method A — Local install (recommended)

```bash
# Step 1 — clone the toolkit once anywhere on your machine
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit

# Step 2 — run from your project root
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

### Method B — Git submodule (only when the full team pins the toolkit via the repo)

> This commits a `.gitmodules` reference to the remote. Only use when every team member
> should share the same toolkit version through the repository.

```bash
git submodule add https://github.com/tweladera/tw-ai-toolkit.git .ai/toolkit
python3 .ai/toolkit/scripts/install.py
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

---

## Folder Structure in the Consumer Repo

After installation, your repo will have:

```
your-repo/
├── .ai/
│   ├── AGENTS.md           # Pointer file — tells AI models the toolkit is here
│   ├── config.json         # Your repo-specific toolkit configuration
│   ├── skills/             # Local skill overrides (optional)
│   ├── agents/             # Local agent overrides (optional)
│   └── toolkit/            # Git submodule — the actual tw-ai-toolkit
│       ├── AGENTS.md
│       ├── registry.json
│       ├── skills/
│       └── ...
├── CLAUDE.md               # Includes fragment pointing to .ai/AGENTS.md
└── ...
```

### `.ai/AGENTS.md` — The pointer file

This file tells any AI assistant that opens your repo that the toolkit is installed
and how to load its context. Minimal version:

```markdown
# AI Toolkit Context

This repo uses tw-ai-toolkit. Load context from:
- Toolkit overview: `.ai/toolkit/AGENTS.md`
- Available components: `.ai/toolkit/registry.json`
- Local overrides: `.ai/skills/`, `.ai/agents/`
- Local config: `.ai/config.json`

All toolkit skills are invoked with the `/tw-` prefix.
```

### `CLAUDE.md` fragment

Add this to your repo's `CLAUDE.md` so Claude Code loads toolkit context automatically:

```markdown
## AI Toolkit

This repo uses tw-ai-toolkit. On session start:
1. Read `.ai/AGENTS.md` for toolkit context
2. Check `.ai/config.json` for repo-specific configuration
3. Toolkit skills use the `/tw-` prefix — run `/tw-sync-context` if context seems stale
```

---

## Configuration

### `.ai/config.json`

Consumer repos can configure toolkit behavior per project:

```json
{
  "toolkit_version": "v1.0.0",
  "enabled_components": ["skills", "agents", "prompts"],
  "disabled_skills": [],
  "local_overrides": true,
  "mcp_servers": [],
  "env_file": ".env"
}
```

Full schema: `.ai/toolkit/config/config.schema.json`

### Environment variables

Copy and fill the secrets template:

```bash
cp .ai/toolkit/config/.env.example .env
# Fill in required values — never commit .env
```

---

## Updating the Toolkit

### Default method — `/tw-update` skill

```bash
/tw-update              # Interactive — shows available versions, you choose
/tw-update v1.2.0       # Update to a specific version
/tw-update latest       # Update to the latest stable version
```

The skill will:
1. Show a diff of changes between current and target version
2. Warn about any breaking changes (major version bumps)
3. Apply the update (git submodule update)
4. Regenerate context snapshots automatically
5. Show migration notes if needed

### Manual method

```bash
cd .ai/toolkit
git fetch --tags
git checkout v1.2.0
cd ../..
git add .ai/toolkit
git commit -m "chore: update tw-ai-toolkit to v1.2.0"
```

### Automated method — Dependabot (optional)

Add to `.github/dependabot.yml` in your consumer repo:

```yaml
version: 2
updates:
  - package-ecosystem: gitsubmodules
    directory: "/"
    schedule:
      interval: weekly
    labels:
      - "dependencies"
      - "ai-toolkit"
```

Dependabot will open PRs automatically when new versions are available.
Your team reviews and merges — no automatic updates without approval.

---

## Version Pinning

Always pin to a specific version tag in production repos:

```bash
# Good — pinned to exact version
cd .ai/toolkit && git checkout v1.2.0

# Acceptable — pinned to minor (gets patches automatically)
cd .ai/toolkit && git checkout v1.2

# Risky — always latest, may break without notice
cd .ai/toolkit && git checkout main
```

Version semantics:
```
v1.0.0  →  major.minor.patch
major   →  breaking changes — requires manual migration
minor   →  new features, backwards compatible — safe to update
patch   →  bug fixes — always safe to update
```

---

## Local Overrides

You can override any toolkit component locally without modifying the submodule.

### Override a skill

Create `.ai/skills/<skill-name>/skill.md` in your consumer repo.
The local version takes precedence over the toolkit version.

```
.ai/
├── skills/
│   └── tw-lint/
│       └── skill.md    # Your override of the tw-lint skill
└── toolkit/
    └── skills/
        └── tw-lint/
            └── skill.md  # Original — ignored when override exists
```

### Override priority order

```
1. .ai/skills/<name>/skill.md          (consumer repo local override)
2. .ai/toolkit/skills/<name>/skill.md  (toolkit default)
```

---

## Multiple Repos Using the Toolkit

If you manage multiple repos, consider:

1. **Central `.env` management** — use a secrets manager (AWS Secrets Manager, Vault)
   and point all repos to it via the `env_file` config field.

2. **Shared overrides** — if multiple repos need the same override, contribute it
   back to the toolkit as a new component or a config option.

3. **Version alignment** — keep repos on the same toolkit version to avoid
   support complexity. Use Dependabot (optional) to keep them in sync.
