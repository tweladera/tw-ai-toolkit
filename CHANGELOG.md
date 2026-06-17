# Changelog

All notable changes to tw-ai-toolkit are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

#### Architecture
- `AGENTS.md` — global L1 context file for AI models
- `PLAN.md` — project roadmap with 8 phases and architectural decisions
- `registry.json` + `config/registry.schema.json` — machine-readable component index
- `config/config.schema.json` — consumer repo configuration schema
- `config/.env.example` — environment variables template

#### Context Layer System (L1–L4)
- `context/snapshot.md` — L2 auto-generated snapshot of all components
- `context/snapshots/*.snapshot.md` — L3 per-type snapshots (skills, agents, prompts, rules, hooks, mcp)
- `context/CHECKPOINT.md` — snapshot freshness tracking (git hash + timestamp)
- `scripts/sync-registry.sh` — scans components and regenerates `registry.json`
- `scripts/sync-snapshots.sh` — regenerates L2/L3 snapshots and CHECKPOINT.md
- `scripts/install-git-hooks.sh` — installs pre-commit hook
- `scripts/git-hooks/pre-commit` — auto-syncs context on commits that touch component files

#### Templates (all 6 component types)
- `skills/_template/` — skill definition template with full frontmatter schema
- `agents/_template/` — agent definition template with flow structure
- `prompts/_template/` — prompt template with `{{variable}}` convention
- `rules/_template/` — rule template with model-specific format sections
- `hooks/_template/` — hook template with Claude Code events reference
- `mcp/_template/` — MCP server template with tools, auth, and setup sections
- `tests/_template/` — test case template with input/expected/pass-criteria structure

#### Core Skills
- `skills/sync-context` (`/tw-sync-context`) — regenerates registry and context snapshots
- `skills/lint-component` (`/tw-lint-component`) — validates component against schema and conventions
- `skills/install-toolkit` (`/tw-install-toolkit`) — AI-guided toolkit installation in consumer repos

#### Core Agents
- `agents/scaffold-component` (`/tw-scaffold-component`) — scaffolds new components from templates
- `agents/onboard-repo` (`/tw-onboard-repo`) — analyzes a repo and sets up the toolkit with tailored config

#### Core Rules
- `rules/claude-base/` — base rules for Claude Code + ready-to-paste `fragment.md`
- `rules/cursor-base/` — base rules for Cursor + ready-to-paste `fragment.md`

#### Integration Scripts
- `scripts/install.sh` — shell script for installing toolkit in consumer repos (curl-able)
- `scripts/update.sh` — shell script for updating toolkit to a specific version

#### Documentation
- `docs/onboarding.md` — getting started guide (< 10 minutes to first skill)
- `docs/integration-guide.md` — install, configure, update, and override from consumer repos
- `docs/contributing.md` — how to create and contribute new components
- `docs/compatibility-matrix.md` — feature support matrix by AI assistant
- `docs/versioning.md` — semver strategy, component lifecycle, branching model

---

## Version History

*(No stable releases yet — working toward v0.1.0)*

---

## How to Read This File

Each release entry looks like:

```markdown
## [v1.2.0] — 2026-07-01

### Added
- `skills/new-skill` — description

### Deprecated
- `skills/old-skill` → replaced by `skills/new-skill` (removed in v2.0.0)

### Removed
- `skills/very-old-skill` — was deprecated since v1.0.0
```
