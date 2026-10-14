# tw-ai-toolkit

[![CI](https://github.com/tweladera/tw-ai-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/tweladera/tw-ai-toolkit/actions/workflows/ci.yml)

A centralized collection of skills, agents, prompts, rules, hooks, and MCP servers
for enterprise AI integration. Designed for AI coding assistants (Claude Code, Cursor, Codex)
and automation pipelines.

Built with an **SDET / QA-first perspective**: the toolkit amplifies the quality engineer's
view that developers often miss — surfacing blind spots, enforcing spec-first thinking,
and automating the full quality loop from spec to coverage to contract testing.

---

## Quick Start

**Use the toolkit in your repo (local only — nothing pushed to remote):**
```bash
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

**Understand the toolkit (AI assistants):**
```
Load AGENTS.md
```

**Contribute (toolkit developers):**
```bash
pip install -r requirements.txt
make sync      # regenerate registry + snapshots
make validate  # validate catalog
make help      # see all available commands
```

---

## Consultant Workflow — Day 1 on Any Client

```
/tw-client-bootstrap          # Full Day 1 kit: health check → strategy → governance → security → CI
/tw-release-readiness         # GO/NO-GO before any deployment
```

## QA Workflow — Full Quality Lifecycle

```
0. Onboarding →  /tw-stack-health-check              # Day 1: what does this codebase look like?
                 /tw-test-strategy-generator          # QA Strategy: pyramid, tooling, roadmap

1. Spec-first →  /tw-exec-spec-generator             # Define behavior before implementation

2. Capture       /tw-golden-master mode=capture      # Behavioral baseline (pre-refactor)

3. Implement     [code follows the spec]

4. Unit layer →  /tw-ts-test-governor                # Audit coverage (TypeScript/NestJS)
                 /tw-python-test-governor             # Audit coverage (Python)
                 /tw-java-test-governor               # Audit coverage (Java/Spring Boot)
                 /tw-quality-sprint                   # Autonomous fix loop
                 /tw-mutation-audit                   # Prove tests actually catch bugs
                 /tw-qa-coach source=<file>           # Detect testability anti-patterns

5. Integration → /tw-integration-discovery           # OpenAPI/controllers → Gherkin + tests
                 /tw-contract-coverage               # Missing Pact/CDC contracts
                 /tw-test-factory source=<entities>  # Test data factories with cleanup

6. E2E layer  →  /tw-e2e-page-object                 # POM from components
                 /tw-e2e-spec-to-test                # .feature → Cypress/Playwright tests
                 /tw-e2e-test-governor               # Flow coverage + selector health
                 /tw-visual-baseline mode=capture    # Visual regression baseline
                 /tw-a11y-audit                      # WCAG 2.1 AA accessibility checks
                 /tw-chaos-testing                   # Resilience: circuit breakers, retries

7. Security   →  /tw-security-audit                  # OWASP + CVE scan + optional DAST
                 /tw-compliance-audit                # GDPR/HIPAA/PCI-DSS/SOX gap report

8. Performance → /tw-performance-baseline            # k6/Locust — baseline + regression

9. Release    →  /tw-release-readiness               # GO/NO-GO — all gates, one decision
                 /tw-golden-master mode=compare      # Behavioral equivalence post-change
                 /tw-living-docs                     # Publish verified behavior to Confluence
                 /tw-quality-trend                   # Is quality improving over time?
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

---

## Available Skills (v0.5.0)

**Consulting & Assessment**

| Skill | Invocation | When to use |
|---|---|---|
| stack-health-check | `/tw-stack-health-check` | Day 1 on any project — executive + technical health report |
| test-strategy-generator | `/tw-test-strategy-generator` | First deliverable: QA strategy document tailored to the client |
| living-docs | `/tw-living-docs` | Feature files + test results → Confluence/HTML living documentation |

**Spec-First & Behavioral**

| Skill | Invocation | When to use |
|---|---|---|
| exec-spec-generator | `/tw-exec-spec-generator` | Before implementation — Gherkin specs + blind spots report |
| golden-master | `/tw-golden-master` | Before/after refactoring — capture and compare behavioral snapshots |

**Unit Test Coverage**

| Skill | Invocation | When to use |
|---|---|---|
| ts-architecture-analyzer | `/tw-ts-architecture-analyzer` | Architecture review of TypeScript/NestJS — risks, scorecard |
| ts-test-governor | `/tw-ts-test-governor` | Audit Jest coverage — gap report with severity classification |
| ts-test-remediator | `/tw-ts-test-remediator` | Generate/fix Jest specs from a governance report |
| python-test-governor | `/tw-python-test-governor` | Audit pytest/unittest coverage — gap report |
| python-test-remediator | `/tw-python-test-remediator` | Generate/fix pytest specs from a governance report |
| java-test-governor | `/tw-java-test-governor` | Audit JUnit 5 coverage for Spring Boot via Jacoco |
| java-test-remediator | `/tw-java-test-remediator` | Generate JUnit 5 tests for Spring Boot from governance report |
| mutation-audit | `/tw-mutation-audit` | Stryker/mutmut — prove tests catch bugs, classify surviving mutants |
| qa-coach | `/tw-qa-coach` | Detect testability anti-patterns, explain why, compute testability score |

**Integration & Contracts**

| Skill | Invocation | When to use |
|---|---|---|
| integration-discovery | `/tw-integration-discovery` | OpenAPI/controllers → Gherkin + supertest/REST Assured/httpx tests |
| contract-coverage | `/tw-contract-coverage` | Detect missing Pact/CDC contract tests |
| test-factory | `/tw-test-factory` | Fishery/factory-boy/Instancio factories with cleanup strategies |
| chaos-testing | `/tw-chaos-testing` | Resilience tests — circuit breakers, retries, timeouts, fallbacks |

**E2E Test Layer**

| Skill | Invocation | When to use |
|---|---|---|
| e2e-spec-to-test | `/tw-e2e-spec-to-test` | Convert .feature → Cypress or Playwright tests with POM pattern |
| e2e-test-governor | `/tw-e2e-test-governor` | Audit E2E flow coverage, stale tests, brittle selectors |
| e2e-page-object | `/tw-e2e-page-object` | Generate POM classes from component files or HTML |
| visual-baseline | `/tw-visual-baseline` | Pixel-diff visual regression detection |
| a11y-audit | `/tw-a11y-audit` | axe-core WCAG 2.1 AA — inject into E2E or standalone |

**Security & Compliance**

| Skill | Invocation | When to use |
|---|---|---|
| security-audit | `/tw-security-audit` | OWASP Top 10 SAST + CVE dependency scan + optional DAST |
| compliance-audit | `/tw-compliance-audit` | GDPR/HIPAA/PCI-DSS/SOX gap report and test checklist |

**Performance & CI**

| Skill | Invocation | When to use |
|---|---|---|
| performance-baseline | `/tw-performance-baseline` | k6/Locust P95 baseline + regression detection |
| pipeline-generator | `/tw-pipeline-generator` | GitHub Actions / GitLab CI / Azure DevOps pipelines with quality gates |
| flakiness-analyzer | `/tw-flakiness-analyzer` | Classify flaky tests by root cause from CI results |
| quality-trend | `/tw-quality-trend` | Longitudinal quality dashboard — is the suite improving? |

**Toolkit Maintenance**

| Skill | Invocation | When to use |
|---|---|---|
| sync-context | `/tw-sync-context` | Regenerate registry and context snapshots |
| lint-component | `/tw-lint-component` | Validate a component against schema and conventions |
| install-toolkit | `/tw-install-toolkit` | Install the toolkit in a consumer repo |

**E2E Test Layer**

| Skill | Invocation | When to use |
|---|---|---|
| e2e-spec-to-test | `/tw-e2e-spec-to-test` | Convert a Gherkin `.feature` file into Cypress or Playwright tests with POM pattern |
| e2e-test-governor | `/tw-e2e-test-governor` | Audit E2E coverage by user flow — flow matrix, selector health, stale test detection |
| e2e-page-object | `/tw-e2e-page-object` | Generate Page Object Model classes from component files, HTML, or descriptions |
| visual-baseline | `/tw-visual-baseline` | Capture visual screenshots and compare pixel-by-pixel to detect visual regressions |
| a11y-audit | `/tw-a11y-audit` | Inject axe-core into E2E tests or run standalone WCAG 2.1 accessibility audits |

**Performance & CI**

| Skill | Invocation | When to use |
|---|---|---|
| performance-baseline | `/tw-performance-baseline` | Generate k6/Locust scripts, establish P95 baselines, detect latency regressions |
| pipeline-generator | `/tw-pipeline-generator` | Generate GitHub Actions / GitLab CI pipelines with quality gates |
| flakiness-analyzer | `/tw-flakiness-analyzer` | Parse CI results to identify flaky tests and classify root causes |
| quality-trend | `/tw-quality-trend` | Aggregate historical reports into a trend dashboard — is quality improving? |

**Toolkit Maintenance**

| Skill | Invocation | When to use |
|---|---|---|
| sync-context | `/tw-sync-context` | Regenerate registry and context snapshots after component changes |
| lint-component | `/tw-lint-component` | Validate a component against schema and conventions |
| install-toolkit | `/tw-install-toolkit` | Install the toolkit in a consumer repo |

## Available Agents (v0.5.0)

| Agent | Invocation | Description |
|---|---|---|
| client-bootstrap | `/tw-client-bootstrap` | Day 1 workflow: health check → strategy → governance → security → CI gates |
| release-readiness | `/tw-release-readiness` | GO/NO-GO from all quality gates with full evidence matrix |
| quality-sprint | `/tw-quality-sprint` | Autonomous governor → remediator loop with human checkpoint at iteration 2 |
| onboard-repo | `/tw-onboard-repo` | Analyze a repo and configure the toolkit for its stack |
| scaffold-component | `/tw-scaffold-component` | Create a new component from the appropriate template |

## Available Rules (v0.5.0)

| Rule | Target | Description |
|---|---|---|
| consultant-mindset | All | Assess before assuming; generate artifacts; adapt to client context; speak business terms |
| security-first | All | Surface OWASP implications before implementing; flag insecure patterns inline |
| performance-budget | All | Flag N+1 queries, unbounded queries, sync external calls in request paths |
| spec-first | All | QA mindset: offer specs before code, surface blind spots |
| claude-base | Claude Code | Base context-loading and navigation behavior |
| cursor-base | Cursor | Base context-loading and navigation behavior |

## Available MCP Servers (v0.5.0)

| Server | Tools exposed | When to configure |
|---|---|---|
| tw-github | PRs, issues, repo | GitHub as primary VCS |
| tw-gitlab | MRs, pipelines, issues | GitLab as primary VCS/CI |
| tw-sonarqube | Quality metrics, hotspots, gates | Client uses SonarQube/SonarCloud |
| tw-azure-devops | Boards, pipelines, repos, test plans | Microsoft-stack client (Azure DevOps) |
| tw-confluence | Pages, spaces, comments | Atlassian stack — publish docs to wiki |
| tw-jira | Issues, sprints, projects | Jira as project management tool |

---

## Primary Assistant

Claude Code. Compatible with Cursor and Codex (see `docs/compatibility-matrix.md`).
