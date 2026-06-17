# AGENTS.md — tw-ai-toolkit Global Context (L1)

> This file is the primary context for all AI models and assistants using this toolkit.
> Load this first. For deeper context, follow the Context Layer System below.

---

## What is tw-ai-toolkit

A centralized collection of **skills**, **agents**, **prompts**, **rules**, **hooks**, and **MCP servers**
for enterprise AI integration. Designed to be consumed from any development repository by AI coding
assistants (Claude Code, Cursor, Codex) and automation pipelines.

**Repository:** `tw-ai-toolkit`
**Primary assistant:** Claude Code (compatible with Cursor, Codex)

---

## Context Layer System

This toolkit uses a tiered context loading strategy to minimize token usage. Load only what you need:

| Layer | File | When to load |
|---|---|---|
| **L1** | `AGENTS.md` *(this file)* | Always — loaded first in every session |
| **L2** | `registry.json` + `context/snapshot.md` | When you need to know what components exist |
| **L3** | `context/snapshots/<type>.snapshot.md` | When working with a specific component type |
| **L3+** | `context/snapshots/cursor.snapshot.md` | Cursor users — shows only Cursor-compatible components |
| **L3+** | `context/snapshots/codex.snapshot.md` | Codex users — shows only Codex-compatible components |
| **L4** | `skills/<name>/skill.md` *(etc.)* | When executing or modifying a specific component |

> Check `context/CHECKPOINT.md` to verify the snapshots are up to date before relying on L2/L3.

---

## Available Components

> For the full index with descriptions and parameters, load `registry.json` (L2).

### Skills — Atomic tools, invoked with `/tw-<name>`
| Name | Status | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### Agents — Autonomous orchestrators
| Name | Status | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### Prompts — Reusable prompt templates
| Name | Status | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### Rules — Behavioral rules for AI models
| Name | Target | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### Hooks — Event-driven automations
| Name | Event | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### MCP Servers — Enterprise tool integrations
| Name | Tools exposed | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

---

## Key Conventions

```
Language          English — all component content, docs, and field names
Skill invocation  /tw-<skill-name>
Agent invocation  /tw-<agent-name>
Namespace         tw- prefix on all toolkit components to avoid collisions
                  with consumer repo's local skills
```

---

## Consumer Repo Integration

When this toolkit is installed in a consumer repo, it lives at:

```
consumer-repo/
└── .ai/                   # toolkit installation folder
    ├── AGENTS.md           # local pointer back to this file (or copy)
    ├── config.json         # consumer-specific configuration
    ├── skills/             # local overrides (optional)
    └── toolkit/            # git submodule pointing to tw-ai-toolkit
```

> AI models should look for a `.ai/` directory in any repo they work in.
> If found, load `.ai/AGENTS.md` to understand what toolkit context is available.

---

## How to Invoke Components

```
Skills   →  /tw-<name>                    Example: /tw-sync-context
Agents   →  /tw-<name>                    Example: /tw-onboard-repo
Prompts  →  Reference prompt.md content   Example: Load prompts/code-review/prompt.md
Rules    →  Loaded via CLAUDE.md fragment  See rules/claude/base.md
Hooks    →  Configured in settings.json   See hooks/<name>/hook.md
MCP      →  Configured in MCP settings    See mcp/<name>/server.md
```

---

## Deprecation Policy

Components go through this lifecycle before removal:

```
stable → deprecated (min. 2 minor versions) → removed (major version only)
```

When you invoke a deprecated component, it will execute but warn you.
Check `registry.json` fields `deprecated_since` and `removed_in` for migration info.

---

## Quick Links

| Resource | Path |
|---|---|
| Work plan | `PLAN.md` |
| Onboarding guide | `docs/onboarding.md` |
| Integration guide | `docs/integration-guide.md` |
| Contributing guide | `docs/contributing.md` |
| Compatibility matrix | `docs/compatibility-matrix.md` |
| Component registry | `registry.json` |
| Context snapshot | `context/snapshot.md` |
| Snapshot freshness | `context/CHECKPOINT.md` |
