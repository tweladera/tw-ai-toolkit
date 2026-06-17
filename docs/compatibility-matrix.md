# Compatibility Matrix

This document defines which toolkit components and features work with each supported
AI assistant. Updated automatically when components are added or modified.

---

## Supported Assistants

| Assistant | Support Level | Config file | Skill invocation |
|---|---|---|---|
| **Claude Code** | Primary — full support | `CLAUDE.md` | `/tw-<name>` |
| **Cursor** | Secondary — most features | `.cursorrules` | `/tw-<name>` (Composer) |
| **Codex / GitHub Copilot** | Partial — prompts and rules only | `.github/copilot-instructions.md` | Not supported |

---

## Feature Support by Assistant

| Feature | Claude Code | Cursor | Codex |
|---|---|---|---|
| Skill invocation (`/tw-<name>`) | Yes | Yes (Cursor Composer) | No |
| Agent invocation | Yes | Partial (Composer only) | No |
| Prompt templates | Yes | Yes | Yes |
| Rules | Yes (`CLAUDE.md`) | Yes (`.cursorrules`) | Yes (`copilot-instructions.md`) |
| Hooks | Yes (`settings.json` events) | Partial (onSave, onFileOpen) | No |
| MCP Servers | Yes | Yes | No |
| Context Layer L1 (AGENTS.md) | Yes | Yes | Yes |
| Context Layer L2 (registry.json) | Yes | Yes | Manual only |
| Context Layer L3 (snapshots) | Yes | Yes | No |
| Context Layer L4 (component files) | Yes | Yes | No |
| `/tw-sync-context` | Yes | Partial | No |
| `/tw-update` | Yes | Partial | No |
| `validate-config.sh` | Yes | Yes (terminal) | Yes (terminal) |

---

## Component-Level Compatibility

> Auto-populated from `registry.json`. For live data load `context/snapshot.md`.

### Skills

| Component | Claude Code | Cursor | Codex | Notes |
|---|---|---|---|---|
| `/tw-sync-context` | full | partial | none | Cursor: run via Composer or terminal |
| `/tw-lint-component` | full | partial | none | Cursor: run via Composer |
| `/tw-install-toolkit` | full | partial | none | Cursor: use `scripts/install.sh` instead |

### Agents

| Component | Claude Code | Cursor | Codex | Notes |
|---|---|---|---|---|
| `/tw-scaffold-component` | full | partial | none | Cursor: works in Composer with full context |
| `/tw-onboard-repo` | full | partial | none | Cursor: works in Composer, some steps manual |

### Rules

| Component | Claude Code | Cursor | Codex | Notes |
|---|---|---|---|---|
| `claude-base` | full | none | none | Claude Code only by design |
| `cursor-base` | none | full | none | Cursor only by design |

### MCP Servers

| Component | Claude Code | Cursor | Codex | Notes |
|---|---|---|---|---|
| `tw-github` | full | full | none | Both assistants support MCP natively |
| `tw-jira` | full | full | none | Both assistants support MCP natively |

---

## Known Limitations and Workarounds

### Cursor

| Limitation | Workaround |
|---|---|
| Agents require multi-step orchestration | Use Cursor Composer — it supports multi-turn flows |
| Hook events limited (`onSave`, `onFileOpen`) | Use Claude Code for full hook event support |
| No auto-loading of L3 snapshots | Load `context/snapshots/<type>.snapshot.md` manually when needed |
| Slash commands may require Composer mode | Invoke `/tw-<skill>` inside a Composer session |
| MCP config format differs slightly | See `mcp/<server>/server.md` — Cursor section has specific JSON |

**Quick setup for Cursor:**
1. Copy `rules/cursor-base/fragment.md` into your `.cursorrules`
2. Configure MCP servers in `.cursor/mcp.json`
3. Use Composer for agent-level tasks

---

### Codex / GitHub Copilot

| Limitation | Workaround |
|---|---|
| No slash command system | Copy the `## Instructions` section of a skill and use as a chat prompt |
| No event hooks | Not available — use Claude Code for hook-based automations |
| No MCP support (native) | Not available in standard Copilot experience |
| No L2/L3 context auto-loading | Load `AGENTS.md` manually as context in Copilot Chat |
| No agent orchestration | Break agents into manual sequential steps |

**What Codex CAN use from this toolkit:**
- All prompts in `prompts/` — paste the template and fill variables
- Rules via `.github/copilot-instructions.md`
- `scripts/install.sh`, `scripts/update.sh`, `scripts/validate.sh` — run directly in terminal

**Quick setup for Codex:**
1. Create `.github/copilot-instructions.md` with toolkit context
2. Add relevant prompt templates from `prompts/` to your workflow
3. Use scripts directly in the terminal for maintenance tasks

---

## Context Layer Compatibility

| Layer | File | Claude Code | Cursor | Codex |
|---|---|---|---|---|
| L1 | `AGENTS.md` | Auto-loaded via CLAUDE.md | Auto-loaded via .cursorrules | Manual |
| L2 | `registry.json` | Loaded on demand | Loaded on demand | Manual (paste relevant section) |
| L3 | `context/snapshots/*.snapshot.md` | Loaded selectively | Loaded selectively | Not practical |
| L3+ | `context/snapshots/cursor.snapshot.md` | — | **Recommended entry point** | — |
| L3+ | `context/snapshots/codex.snapshot.md` | — | — | **Recommended entry point** |
| L4 | Component files (`skill.md`, etc.) | On execution | On execution | Manual |

> **For Cursor users:** Load `context/snapshots/cursor.snapshot.md` to see only what's compatible with your assistant.
> **For Codex users:** Load `context/snapshots/codex.snapshot.md` for your specific subset.

---

## Adding Support for a New Assistant

1. Add the assistant to the tables in this file
2. Add a column to the feature support table
3. Update `config/registry.schema.json` — add assistant to `compatible_with` enum
4. Update each existing component's `compatible_with` field
5. Create `rules/<assistant>-base/` with base rules for the new assistant
6. Run `bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh`
7. Open a PR with label `compatibility`
