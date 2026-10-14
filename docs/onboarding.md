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

**Option A1 — Local install (recommended — nothing pushed to remote)**

```bash
# Clone the toolkit once anywhere on your machine
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit

# Run from your project root
cd /path/to/your-repo
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

Everything gets added to `.gitignore` automatically — your remote repo stays clean.

**Option A2 — Git submodule (only if the team wants the toolkit pinned in the repo)**

> This commits a `.gitmodules` reference to the remote. Only use when the whole team
> should share the same toolkit version via the repository.

```bash
cd /path/to/your-repo
git submodule add https://github.com/tweladera/tw-ai-toolkit.git .ai/toolkit
python3 .ai/toolkit/scripts/install.py
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

The `--link-all` step creates symlinks in `.claude/skills/`, `.cursor/skills/`,
`.claude/commands/` (autocomplete stubs), and `.claude/rules/` / `.cursor/rules/`.
These directories are automatically added to your `.gitignore`.

### Step 2 — Load context in your AI assistant

Open your repo in Claude Code and say:
```
Load .ai/AGENTS.md and give me an overview of what toolkit components are available.
```

Or invoke the toolkit context skill directly:
```
/tw-sync-context
```

If using Cursor, copy the rules fragment into your `.cursorrules`:
```
Copy content of .ai/toolkit/rules/cursor-base/fragment.md into .cursorrules
```

### Step 3 — Use a skill

```
/tw-sync-context
```

Browse `registry.json` or ask your assistant what skills are available.

**Recommended starting point for QA / SDET teams:**

```bash
# Before writing a single line of code for a new feature:
/tw-exec-spec-generator story="[paste your user story here]"
# → Gherkin feature file + blind spots report with what the dev didn't think of

# To audit test coverage of an existing TypeScript/NestJS repo:
/tw-ts-test-governor
# → Governance report: what's covered, what's missing, severity classification

# To automatically fix coverage gaps (guided loop):
/tw-quality-sprint
# → Governor + remediator loop, up to 3 iterations, mandatory human review at iteration 2

# To detect missing contract tests between microservices:
/tw-contract-coverage mode=generate
# → Consumer-provider map + Pact stubs for uncovered integrations

# Before/after a refactor or migration:
/tw-golden-master mode=capture name=my-service target="..." inputs=tests/inputs.json
# refactor or migrate...
/tw-golden-master mode=compare name=my-service
# → Black-box behavioral equivalence report
```

### Updating the toolkit

**If installed with `--local` (recommended):**
```bash
cd ~/tw-ai-toolkit && git pull origin main
# Re-link in case new skills were added
cd /path/to/your-repo && python3 .ai/toolkit/scripts/install.py --link-all
```

**If installed as a submodule:**
```bash
cd /path/to/your-repo
git submodule update --remote .ai/toolkit
python3 .ai/toolkit/scripts/install.py --link-all
```

---

## Option B: I want to CONTRIBUTE a new component

See the full guide: `docs/contributing.md`

Quick summary:
1. Copy the relevant template from `skills/_template/`, `agents/_template/`, etc.
2. Fill in all required frontmatter fields (see contributing guide for reference)
3. Run `make sync && make validate` to validate your component
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
