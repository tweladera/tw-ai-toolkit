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
| Name | Invocation | Description |
|---|---|---|
| install-toolkit | `/tw-install-toolkit` | Guided toolkit installation in a consumer repo |
| lint-component | `/tw-lint-component` | Validates a component against schema and conventions |
| sync-context | `/tw-sync-context` | Regenerates registry and context snapshots |
| python-test-governor | `/tw-python-test-governor` | Audits Python unit test coverage and produces a governance report |
| python-test-remediator | `/tw-python-test-remediator` | Generates or repairs pytest/unittest files from a governance report |
| ts-architecture-analyzer | `/tw-ts-architecture-analyzer` | Deep architectural analysis of TypeScript/NestJS code with Gherkin output |
| ts-test-governor | `/tw-ts-test-governor` | Audits Jest unit test coverage and produces a governance report |
| ts-test-remediator | `/tw-ts-test-remediator` | Generates or repairs Jest spec files from a governance report |
| exec-spec-generator | `/tw-exec-spec-generator` | Generates executable Gherkin specs from user stories with a QA blind spots report |
| golden-master | `/tw-golden-master` | Captures behavioral snapshots and compares runs to detect regressions |
| contract-coverage | `/tw-contract-coverage` | Detects missing contract tests (Pact) across inter-service integrations |
| e2e-spec-to-test | `/tw-e2e-spec-to-test` | Converts a Gherkin feature file into Cypress or Playwright tests with POM pattern |
| e2e-test-governor | `/tw-e2e-test-governor` | Audits E2E coverage by user flow, detects stale tests and brittle selectors |
| e2e-page-object | `/tw-e2e-page-object` | Generates Page Object Model classes from component files or descriptions |
| pipeline-generator | `/tw-pipeline-generator` | Generates GitHub Actions or GitLab CI pipelines with quality gates and nightly schedules |
| flakiness-analyzer | `/tw-flakiness-analyzer` | Parses CI results to identify flaky tests and classify root causes by pattern |
| mutation-audit | `/tw-mutation-audit` | Runs Stryker/mutmut mutation testing and proposes targeted assertion improvements |
| java-test-governor | `/tw-java-test-governor` | Audits JUnit 5 coverage for Spring Boot via Jacoco — gap report with Spring stereotype mapping |
| java-test-remediator | `/tw-java-test-remediator` | Generates JUnit 5 tests for Spring Boot (@Service+Mockito, @RestController+MockMvc, @DataJpaTest) |
| performance-baseline | `/tw-performance-baseline` | Generates k6/Locust scripts, establishes P95 baselines, detects performance regressions |
| a11y-audit | `/tw-a11y-audit` | Injects axe-core into Playwright/Cypress tests or runs standalone WCAG 2.1 accessibility audits |
| quality-trend | `/tw-quality-trend` | Aggregates historical governance reports into a trend dashboard showing quality direction |
| test-factory | `/tw-test-factory` | Generates Fishery/factory-boy/Instancio test data factories with cleanup strategies |
| visual-baseline | `/tw-visual-baseline` | Captures visual screenshots and compares pixel-by-pixel to detect visual regressions |
| qa-coach | `/tw-qa-coach` | Analyzes code for testability anti-patterns, explains why, and proposes refactoring paths |
| integration-discovery | `/tw-integration-discovery` | Scans OpenAPI/AsyncAPI/controllers, generates Gherkin + integration tests (supertest/REST Assured/httpx) |
| security-audit | `/tw-security-audit` | OWASP Top 10 SAST + dependency CVE scan (npm audit/pip-audit/OWASP DC) + optional DAST |
| compliance-audit | `/tw-compliance-audit` | GDPR/HIPAA/PCI-DSS/SOX/ISO 27001 gap report and test checklist |
| test-strategy-generator | `/tw-test-strategy-generator` | QA Strategy document: pyramid, tooling, coverage targets, CI gates, phased roadmap |
| stack-health-check | `/tw-stack-health-check` | Day 1 technical assessment: stack, coverage, CI, dependencies, debt — executive + technical reports |
| living-docs | `/tw-living-docs` | Feature files + test results → living documentation (Confluence/HTML/Markdown) |
| chaos-testing | `/tw-chaos-testing` | Resilience tests for circuit breakers, retries, timeouts, and graceful degradation |

### Agents — Autonomous orchestrators
| Name | Invocation | Description |
|---|---|---|
| onboard-repo | `/tw-onboard-repo` | Analyzes a repo and configures the toolkit for its stack |
| scaffold-component | `/tw-scaffold-component` | Creates a new component from the appropriate template |
| quality-sprint | `/tw-quality-sprint` | Bounded governor → remediator loop with human checkpoint at iteration 2 |
| release-readiness | `/tw-release-readiness` | GO/NO-GO decision from all quality gates with full evidence matrix |
| client-bootstrap | `/tw-client-bootstrap` | Full Day 1 consultant workflow: health check → strategy → governance → security → CI |

### Prompts — Reusable prompt templates
| Name | Status | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### Rules — Behavioral rules for AI models
| Name | Target | Description |
|---|---|---|
| claude-base | Claude Code | Base context-loading and navigation rules |
| cursor-base | Cursor | Base context-loading and navigation rules |
| spec-first | All | QA mindset: surface blind spots, spec before code, fix source not output |
| security-first | All | Surface OWASP implications before implementation; flag insecure patterns |
| performance-budget | All | Flag N+1 queries, unbounded queries, sync external calls in request paths |
| consultant-mindset | All | Assess before assuming; generate artifacts; adapt to client context |

### Hooks — Event-driven automations
| Name | Event | Description |
|---|---|---|
| *(none yet — see registry.json)* | | |

### MCP Servers — Enterprise tool integrations
| Name | Tools exposed | Description |
|---|---|---|
| tw-github | PR, issues, repo | GitHub integration for AI assistants |
| tw-gitlab | MRs, pipelines, issues | GitLab integration (VCS + CI platform) |
| tw-sonarqube | Quality metrics, hotspots | SonarQube/SonarCloud code quality and security |
| tw-azure-devops | Boards, pipelines, repos, test plans | Azure DevOps integration (Microsoft-stack clients) |
| tw-confluence | Pages, spaces, comments | Confluence documentation publishing |
| tw-jira | Issues, sprints, projects | Jira integration for AI assistants |

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
| Onboarding guide | `docs/onboarding.md` |
| Integration guide | `docs/integration-guide.md` |
| Contributing guide | `docs/contributing.md` |
| Compatibility matrix | `docs/compatibility-matrix.md` |
| Component registry | `registry.json` |
| Context snapshot | `context/snapshot.md` |
| Snapshot freshness | `context/CHECKPOINT.md` |
| Developer commands | `Makefile` (`make help`) |
