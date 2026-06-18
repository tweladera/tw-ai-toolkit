# Toolkit Snapshot (L2)

> Auto-generated on 2026-06-18 14:29 UTC. Do not edit manually.
> Check `context/CHECKPOINT.md` for freshness info before relying on this data.

---

## Summary

| Type | Total | Stable | Deprecated | Experimental |
|---|---|---|---|---|
| Skills | 4 | 4 | 0 | 0 |
| Agents | 2 | 2 | 0 | 0 |
| Prompts | 0 | 0 | 0 | 0 |
| Rules | 2 | 2 | 0 | 0 |
| Hooks | 0 | 0 | 0 | 0 |
| MCP Servers | 2 | 2 | 0 | 0 |

---

## Skills

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| install-toolkit | `/tw-install-toolkit` | Guides the user through installing tw-ai-toolkit into a consumer repository. | stable | yes | partial | no |
| lint-component | `/tw-lint-component` | Validates that a toolkit component follows all required conventions and schema rules. | stable | yes | partial | no |
| python-test-governor | `/tw-python-test-governor` | Audits Python unit test coverage, maps production modules to tests, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. | stable | yes | partial | no |
| sync-context | `/tw-sync-context` | Regenerates the toolkit registry and context snapshots from current component files. | stable | yes | partial | no |

## Agents

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| onboard-repo | `/tw-onboard-repo` | Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project. | stable | yes | partial | no |
| scaffold-component | `/tw-scaffold-component` | Creates a new toolkit component from the appropriate template given a type and name. | stable | yes | partial | no |

## Prompts

*(none yet)*

## Rules

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| claude-base | — | Base behavioral rules for Claude Code when working in a repo that uses tw-ai-toolkit. | stable | yes | no | no |
| cursor-base | — | Base behavioral rules for Cursor when working in a repo that uses tw-ai-toolkit. | stable | yes | no | no |

## Hooks

*(none yet)*

## MCP Servers

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| tw-github | — | GitHub MCP server exposing PR, issue, and repository tools to AI assistants. | stable | yes | yes | no |
| tw-jira | — | Jira MCP server exposing issue, sprint, and project tools to AI assistants. | stable | yes | yes | no |

---

For full metadata (parameters, tags), load `registry.json`.
For per-category detail, load `context/snapshots/<type>.snapshot.md`.
