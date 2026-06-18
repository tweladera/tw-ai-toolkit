# Cursor Compatibility Snapshot (L3+)

> Auto-generated on 2026-06-18 15:37 UTC. Do not edit manually.
> Shows only components with `compatible_with.cursor: full` or `partial`.
> For full compatibility details see `docs/compatibility-matrix.md`.

---

## Available for Cursor (12 components)

| Name | Type | Invocation | Compatibility | Description |
|---|---|---|---|---|
| install-toolkit | Skills | `/tw-install-toolkit` | partial | Guides the user through installing tw-ai-toolkit into a consumer repository. |
| lint-component | Skills | `/tw-lint-component` | partial | Validates that a toolkit component follows all required conventions and schema rules. |
| python-test-governor | Skills | `/tw-python-test-governor` | partial | Audits Python unit test coverage, maps production modules to tests, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. |
| python-test-remediator | Skills | `/tw-python-test-remediator` | partial | Consumes a Python test governance report, assigns coverage tiers per module, then generates or updates maintainable pytest and unittest tests to meet tiered line-coverage targets. |
| sync-context | Skills | `/tw-sync-context` | partial | Regenerates the toolkit registry and context snapshots from current component files. |
| ts-architecture-analyzer | Skills | `/tw-ts-architecture-analyzer` | partial | Analyzes TypeScript/NestJS code with adaptive depth, auto-detects granularity level (L1-L4), identifies architectural risks, silent traps, and scalability issues, and produces a technical health scorecard with Gherkin feature file. |
| ts-test-governor | Skills | `/tw-ts-test-governor` | partial | Audits Jest unit test coverage in a TypeScript/NestJS repository, maps production modules to spec files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. |
| ts-test-remediator | Skills | `/tw-ts-test-remediator` | partial | Consumes a TypeScript/NestJS test governance report, assigns Istanbul coverage tiers per module, then generates or updates maintainable Jest spec files to meet tiered line-coverage targets. |
| onboard-repo | Agents | `/tw-onboard-repo` | partial | Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project. |
| scaffold-component | Agents | `/tw-scaffold-component` | partial | Creates a new toolkit component from the appropriate template given a type and name. |
| tw-github | MCP Servers | — | full | GitHub MCP server exposing PR, issue, and repository tools to AI assistants. |
| tw-jira | MCP Servers | — | full | Jira MCP server exposing issue, sprint, and project tools to AI assistants. |

## Cursor Quick Start

1. Copy `rules/cursor-base/fragment.md` into your `.cursorrules`
2. Configure MCP servers in `.cursor/mcp.json` (see `docs/mcp-guide.md`)
3. Use Cursor Composer for skills and agents
4. For component details, read `context/snapshots/<type>.snapshot.md`
