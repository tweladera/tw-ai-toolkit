# tw-ai-toolkit

![CI](https://github.com/tw-qa/tw-ai-toolkit/actions/workflows/ci.yml/badge.svg)

A centralized collection of skills, agents, prompts, rules, hooks, and MCP servers
for enterprise AI integration. Designed for AI coding assistants (Claude Code, Cursor, Codex)
and automation pipelines.

---

## Quick Start

**Use the toolkit in your repo:**
```bash
curl -fsSL https://raw.githubusercontent.com/tw-qa/tw-ai-toolkit/main/scripts/install.sh | bash
```

**Understand the toolkit (AI assistants):**
```
Load AGENTS.md
```

---

## Documentation

| Document | Description |
|---|---|
| `AGENTS.md` | Global AI context — start here if you are an AI assistant |
| `docs/onboarding.md` | Getting started guide for new users |
| `docs/integration-guide.md` | How to install and use from another repo |
| `docs/contributing.md` | How to create and contribute new components |
| `docs/compatibility-matrix.md` | Supported assistants and feature matrix |
| `PLAN.md` | Project roadmap and architecture decisions |

---

## Component Types

| Type | Description | Invocation |
|---|---|---|
| **Skills** | Atomic reusable tools | `/tw-<name>` |
| **Agents** | Autonomous orchestrators | `/tw-<name>` |
| **Prompts** | Reusable prompt templates | Load `prompt.md` |
| **Rules** | AI model behavioral rules | Via `CLAUDE.md` / `.cursorrules` |
| **Hooks** | Event-driven automations | Via `settings.json` |
| **MCP Servers** | Enterprise tool integrations | Via MCP config |

See `registry.json` for the full index of available components.

---

## Primary Assistant

Claude Code. Compatible with Cursor and Codex (see `docs/compatibility-matrix.md`).
