# Onboarding Guide — tw-ai-toolkit

Welcome. This guide gets you from zero to productive in the toolkit in under 10 minutes.

---

## What is this?

`tw-ai-toolkit` is a centralized collection of reusable AI components — skills, agents, prompts,
rules, hooks, and MCP servers — designed to be plugged into any development repo and used with
AI coding assistants like Claude Code, Cursor, or Codex.

Instead of reinventing AI workflows in every project, you install this toolkit once and get
a growing library of battle-tested components.

---

## Core concepts (2 min read)

| Concept | What it does | How you call it |
|---|---|---|
| **Skill** | Atomic tool. Does one thing well. | `/tw-<name>` |
| **Agent** | Orchestrator. Combines skills for complex tasks. | `/tw-<name>` |
| **Prompt** | Reusable prompt template with parameters. | Load the file, fill params |
| **Rule** | Behavioral instruction for an AI model. | Via `CLAUDE.md` or `.cursorrules` |
| **Hook** | Automation triggered by an assistant event. | Via `settings.json` |
| **MCP Server** | Enterprise tool integration via Model Context Protocol. | Via MCP config |

---

## Option A: I want to USE the toolkit in my repo (most common)

### Step 1 — Install

```bash
# From the root of your repo
curl -fsSL https://raw.githubusercontent.com/tw-qa/tw-ai-toolkit/main/scripts/install.sh | bash
```

This will:
1. Create a `.ai/` folder in your repo
2. Add `tw-ai-toolkit` as a git submodule at `.ai/toolkit/`
3. Copy starter config to `.ai/config.json`
4. Add a `.ai/AGENTS.md` pointer file
5. Optionally add a `CLAUDE.md` fragment for Claude Code

### Step 2 — Load context in your AI assistant

Open your repo in Claude Code and say:
```
Load .ai/AGENTS.md and give me an overview of what toolkit components are available.
```

Or if using Cursor, the `.cursorrules` fragment handles this automatically.

### Step 3 — Use a skill

```
/tw-sync-context
```

That's it. Browse `registry.json` or ask your assistant what skills are available.

### Updating the toolkit

```
/tw-update              # shows available versions, you choose
/tw-update v1.2.0       # updates to a specific version
```

---

## Option B: I want to CONTRIBUTE a new component

See the full guide: `docs/contributing.md`

Quick summary:
1. Copy the relevant template from `skills/_template/`, `agents/_template/`, etc.
2. Fill in the required fields (the template tells you which are mandatory)
3. Run `/tw-lint-component` to validate your component
4. Run the tests in `tests/<your-component>/`
5. Open a PR — the CI will validate automatically

---

## Option C: I want to understand the repo structure

```
tw-ai-toolkit/
├── AGENTS.md           # Start here — global AI context (L1)
├── registry.json       # Index of all components (L2)
├── context/            # Auto-generated snapshots for fast context loading
├── skills/             # Atomic tools
├── agents/             # Orchestrators
├── prompts/            # Prompt templates
├── rules/              # Model behavior rules
├── hooks/              # Event automations
├── mcp/                # MCP server integrations
├── docs/               # Human documentation (you are here)
├── config/             # Config schemas and defaults
├── scripts/            # Maintenance scripts
└── tests/              # Component tests
```

For architecture details, read `PLAN.md`.
For integration details, read `docs/integration-guide.md`.

---

## FAQ

**Q: What AI assistants are supported?**
Claude Code (primary), Cursor, Codex. See `docs/compatibility-matrix.md` for details.

**Q: Can I override a toolkit component locally?**
Yes. Place your override at `.ai/skills/<name>/skill.md` in your consumer repo.
Local overrides take precedence over toolkit defaults.

**Q: How do I know if a component is safe to update?**
Check semantic versioning: `patch` and `minor` updates are always backwards compatible.
`major` updates may have breaking changes — check `CHANGELOG.md` before updating.

**Q: A component I was using disappeared.**
It was likely deprecated and then removed in a major version. Check `CHANGELOG.md`
for the replacement component name.

**Q: How do I get help?**
Open an issue in the `tw-ai-toolkit` repository.
