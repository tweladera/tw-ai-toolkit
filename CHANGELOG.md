# Changelog

All notable changes to tw-ai-toolkit are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [v0.5.0] — 2026-10-14

### Added — Universal Consulting Toolkit

Designed for adaptability across any client, industry, and stack. Adds security and
compliance testing (zero coverage before this release), the Day 1 consultant workflow,
living documentation, resilience testing, and enterprise platform integrations (GitLab,
SonarQube, Azure DevOps, Confluence). Introduces three new behavioral rules that encode
the consulting mindset for AI assistants.

#### Skills

- `skills/security-audit` (`/tw-security-audit`) — Multi-layer security audit: SAST for
  OWASP Top 10 code patterns, SCA for dependency CVEs (npm audit, pip-audit, OWASP Dependency
  Check, govulncheck, dotnet list package --vulnerable), and optional DAST via OWASP ZAP.
  Stack-agnostic. Produces a severity-classified report with specific fix commands per finding.

- `skills/compliance-audit` (`/tw-compliance-audit`) — Generates compliance gap reports and
  test checklists for GDPR, HIPAA, PCI-DSS, SOX, and ISO 27001. Scans code for compliance-
  relevant patterns: PII field detection, consent management, audit logging, data retention,
  encryption. Maps findings to specific regulatory articles. CSV export for GRC tools.

- `skills/test-strategy-generator` (`/tw-test-strategy-generator`) — Generates a complete,
  tailored QA Strategy document from project analysis. Covers test pyramid ratios for the
  detected stack, concrete tooling recommendations, measurable coverage targets, CI/CD gate
  definitions, and a phased implementation roadmap adapted to team size and delivery model.
  The first deliverable a consultant produces for any new client. Confluence output format.

- `skills/stack-health-check` (`/tw-stack-health-check`) — Comprehensive Day 1 project
  assessment. Detects tech stack, measures current test coverage (from Istanbul/coverage.xml/
  Jacoco), evaluates CI pipeline health, identifies outdated dependencies and known CVEs, and
  surfaces technical debt signals (TODOs, God classes, stale documentation). Produces an
  executive summary (management-facing, ≤ 2 pages) and a full technical report.

- `skills/living-docs` (`/tw-living-docs`) — Reads passing Gherkin `.feature` files and test
  results (JUnit XML, Playwright JSON, Cypress JSON) to generate living documentation showing
  which scenarios are verified ✅, failing ❌, or pending ⏳. Outputs Markdown, standalone HTML,
  or Confluence wiki markup. Designed for CI integration: regenerate after every main branch build.

- `skills/chaos-testing` (`/tw-chaos-testing`) — Generates resilience tests for circuit
  breakers, retry logic, timeout handling, fallback responses, and bulkhead patterns. Supports
  Spring Boot with Resilience4j + WireMock, NestJS with nock, and Python/FastAPI with
  unittest.mock. Verifies that the application handles downstream service failures gracefully —
  the missing layer between functional and performance testing.

#### Agents

- `agents/release-readiness` (`/tw-release-readiness`) — Orchestrates all available quality
  gates: unit coverage, mutation score, flaky tests, performance regression, accessibility,
  security findings, visual regression, and contract coverage. Reads existing reports from
  prior skill runs and produces a single **GO / NO-GO decision** with a full evidence matrix.
  Gates marked NOT ESTABLISHED (no baseline) are informational, not blocking.

- `agents/client-bootstrap` (`/tw-client-bootstrap`) — Full Day 1 consultant workflow in a
  single invocation. Executes: stack health check → QA strategy generation → test governance
  baseline → security scan → CI pipeline quality gate setup. Produces the **Engagement Starter
  Kit**: executive health summary, technical report, QA strategy doc, governance report, security
  audit, and updated CI pipeline. Configurable depth: quick (strategy only) / standard / deep
  (adds compliance audit).

#### Rules

- `rules/security-first` — Behavioral rule fragment for `CLAUDE.md`. Instructs the AI to
  surface OWASP implications before implementing any endpoint touching auth, PII, payments, or
  external APIs. Flags insecure patterns (SQL injection via string concat, hardcoded secrets,
  weak hashing, CORS wildcards, JWT without expiration) with specific fix suggestions. Does not
  block implementation — surfaces the concern and continues with the secure pattern.

- `rules/performance-budget` — Behavioral rule fragment for `CLAUDE.md`. Instructs the AI to
  flag N+1 query patterns, unbounded queries, synchronous external calls in the request path,
  and missing pagination before implementing data access code. Includes stack-specific examples
  (TypeORM relations, Django select_related, JPA JOIN FETCH).

- `rules/consultant-mindset` — Behavioral rule fragment for `CLAUDE.md`. Encodes the consulting
  operating mode: assess before assuming, generate artifacts not just answers, adapt recommendations
  to the client's current maturity, communicate findings in business terms (risk and user impact,
  not metrics). Designed for first-week adoption on any new engagement. Remove after foundation phase.

#### MCP Servers

- `mcp/tw-gitlab` — GitLab MCP server: merge requests, CI/CD pipelines, issues, repository tools.
  Supports both gitlab.com and self-hosted GitLab instances. Essential for European enterprises and
  teams standardized on GitLab.

- `mcp/tw-sonarqube` — SonarQube/SonarCloud MCP server: quality gate status, issues by severity,
  security hotspots, coverage metrics. Enables AI-assisted triage of SonarQube backlogs.
  Supports both SonarQube (self-hosted) and SonarCloud.

- `mcp/tw-azure-devops` — Azure DevOps MCP server: Boards (work items, sprints), Pipelines
  (runs, logs), Repos (PRs, commits), and Test Plans. Essential for Microsoft-stack clients.
  Accepts WIQL for advanced work item queries.

- `mcp/tw-confluence` — Confluence MCP server: read and publish pages, spaces, and comments.
  Enables direct publishing of living docs, QA strategy documents, and governance reports to the
  team wiki. Supports Confluence Cloud and Data Center.

---

## [v0.4.0] — 2026-10-14

### Added — Advanced Quality Engineering Suite

Completes the enterprise SDET toolkit with 12 new skills across 4 pillars:
CI/CD automation, Java stack support, operational quality layers (performance, accessibility,
visual regression), and observability tools (trend dashboard, test data management).
Introduces the user's proposed `integration-discovery` skill — API autodiscovery from
OpenAPI/AsyncAPI specs and controller annotations → framework-agnostic Gherkin → integration
tests — closing the gap between spec and executable verification without manual authoring.

#### Tier 1 — CI/CD and Test Quality Gates

- `skills/pipeline-generator` (`/tw-pipeline-generator`) — Generates GitHub Actions or GitLab CI
  pipeline YAML with quality gates: lint, unit, coverage threshold, E2E, contract tests, and
  nightly schedules for slow gates (mutation testing, full E2E). Supports TypeScript, Python,
  Java, and multi-stack monorepos.

- `skills/flakiness-analyzer` (`/tw-flakiness-analyzer`) — Parses JUnit XML, GitHub Actions,
  or GitLab CI test results across ≥5 runs to distinguish flaky tests from truly broken ones.
  Classifies 7 root-cause patterns (timing dependency, environment coupling, data ordering,
  shared state, random seeding, async race conditions, external service dependency) and
  generates a prioritized remediation plan.

- `skills/mutation-audit` (`/tw-mutation-audit`) — Runs Stryker (TypeScript/JS) or mutmut
  (Python) mutation testing on tier-A modules from the governance report. Classifies surviving
  mutants by risk (logic, boundary, null, operator) and proposes targeted assertion improvements.
  Threshold: 70% mutation score. A passing mutation score proves that tests actually catch bugs.

#### Tier 2 — Java Stack and Operational Quality

- `skills/java-test-governor` (`/tw-java-test-governor`) — Audits JUnit 5 unit and integration
  test coverage for Java/Spring Boot projects using Jacoco XML reports. Maps Spring stereotypes
  (@Service, @Repository, @RestController, @Component) to test files. Supports Maven and Gradle.
  Produces a governance report with HALT/FIX/CREATE/NO ACTION decisions.

- `skills/java-test-remediator` (`/tw-java-test-remediator`) — Consumes a Java governance
  report and generates JUnit 5 test files following three Spring patterns: @Service with Mockito
  mocks, @RestController with MockMvc + @WebMvcTest, and @Repository with @DataJpaTest + H2.
  Applies AssertJ for fluent assertions, parameterized tests for boundary cases.

- `skills/performance-baseline` (`/tw-performance-baseline`) — Generates k6 (TypeScript/JS) or
  Locust (Python) performance test scripts from OpenAPI specs or detected controller routes.
  Establishes P50/P95/P99 baselines on first run (`mode=baseline`) and compares against them
  on subsequent runs (`mode=compare`) with a regression report. Baselines stored in `.performance/`.

- `skills/a11y-audit` (`/tw-a11y-audit`) — Integrates axe-core accessibility testing into
  Playwright or Cypress tests. Two modes: `inject` (adds checkA11y() to existing tests at zero
  cost) and `standalone` (generates a dedicated accessibility spec). Produces a WCAG 2.1 violation
  report classified by impact (critical/serious/moderate/minor). Catches ~30–40% of WCAG issues
  automatically.

#### Tier 3 — Observability and Test Infrastructure

- `skills/quality-trend` (`/tw-quality-trend`) — Reads all historical governance reports,
  mutation scores, flakiness reports, E2E coverage reports, and performance baselines to generate
  a quality trend dashboard with sparklines, composite quality score, and directional indicators
  (↑ improving / → stable / ↓ degrading). Exports to CSV for Grafana/DataDog ingestion.

- `skills/test-factory` (`/tw-test-factory`) — Generates test data factory classes from entity
  files: Fishery (TypeScript), factory-boy (Python), Instancio (Java). Produces factories with
  deterministic defaults, sequence-based IDs, and three cleanup strategies (afterEach deletion,
  transaction rollback, table truncation). Solves test pollution and coupling to production data.

- `skills/visual-baseline` (`/tw-visual-baseline`) — Captures visual screenshots of application
  pages under controlled conditions using Playwright `toHaveScreenshot` or `cypress-image-snapshot`.
  Compares pixel-by-pixel against saved baselines to detect visual regressions (CSS changes, layout
  shifts, font failures, component appearance changes) invisible to functional tests.
  Default threshold: 0.1% pixel difference.

- `skills/qa-coach` (`/tw-qa-coach`) — Analyzes source code or pull requests for 6 testability
  anti-patterns: hidden static dependencies, God classes, direct infrastructure access, business
  logic in persistence layer, non-deterministic behavior, and missing interfaces for external
  systems. Computes a testability score (0–100) with penalty breakdown. Produces analyze,
  pr-review, or score mode outputs. Bridges the gap between developer design decisions and QA
  consequences — explains WHY code is hard to test, not just that it is.

#### Integration Autodiscovery (user-proposed concept)

- `skills/integration-discovery` (`/tw-integration-discovery`) — **The agnostic test layer.**
  Scans OpenAPI/AsyncAPI specs, Spring @RestController annotations, NestJS @Controller decorators,
  or Express router declarations to auto-discover all API contracts. Generates:
  1. Framework-agnostic Gherkin `.feature` files — the contract spec readable by product owners
  2. Framework-specific integration tests — supertest (NestJS), REST Assured (Spring), httpx (FastAPI)
  Supports `contract_mode=happy+error` (default) or `full` for boundary/auth scenarios.
  The Gherkin layer is the source of truth — swap test frameworks by regenerating from the same spec.

---

## [v0.3.0] — 2026-10-14

### Added — E2E Test Layer (Cypress & Playwright)

Closes the spec-first loop by converting Gherkin feature files into runnable E2E tests.
Introduces the Page Object Model pattern, flow-based coverage auditing, and selector
health analysis for Cypress and Playwright projects.

#### Skills
- `skills/e2e-spec-to-test` (`/tw-e2e-spec-to-test`) — Converts a Gherkin `.feature` file
  into Cypress or Playwright test files following the Page Object Model pattern. Auto-detects
  framework from `cypress.config.*` or `playwright.config.*`. Enforces the selector hierarchy
  (data-testid > ARIA > text > CSS) and generates condition-based waits — never hardcoded sleeps.
  Produces: test file, POM classes, and fixture file. Reference: `references/selector-strategy.md`.
- `skills/e2e-test-governor` (`/tw-e2e-test-governor`) — Audits E2E test coverage by mapping
  user flows and `.feature` files to existing test files. Classifies gaps as CRITICAL/HIGH/MEDIUM/LOW.
  Detects stale tests (routes or selectors no longer in codebase) and brittle selector patterns
  (CSS classes, nth-child). Produces a flow coverage matrix and selector health report.
  Reference: `references/analysis-guide.md`.
- `skills/e2e-page-object` (`/tw-e2e-page-object`) — Generates Page Object Model classes
  from React/Vue/Angular component files, HTML markup, or text descriptions. Reads actual
  `data-testid` and ARIA attributes from source — never invents selectors. Generates TODOs
  for missing attributes that must be added to components before tests can run stably.

---

## [v0.2.0] — 2026-10-14

### Added — QA-First Skill Suite

Introduces 3 new skills, 1 new agent, and 1 new rule implementing the SDET / spec-first
quality paradigm: executable specs before implementation, behavioral equivalence testing,
contract coverage detection, and autonomous quality loops.

#### Skills
- `skills/exec-spec-generator` (`/tw-exec-spec-generator`) — Generates executable Gherkin specs
  from user stories or requirements. Applies 6 QA lenses (functional, boundary, error, security,
  state, contract) and produces a **Blind Spots Report** surfacing scenarios the developer didn't
  think of. The spec-first entry point of the quality workflow.
- `skills/golden-master` (`/tw-golden-master`) — Captures behavioral snapshots of a system
  (`mode=capture`) and compares future runs against them (`mode=compare`) to detect regressions
  or prove legacy-to-new equivalence during migrations. Normalizes UUIDs, timestamps, and secrets
  by default. Reference: `skills/golden-master/references/masking-guide.md`.
- `skills/contract-coverage` (`/tw-contract-coverage`) — Scans the codebase for HTTP clients,
  Kafka producers, and message consumers; maps consumer-provider relationships; detects missing
  Pact/CDC contract tests; and generates Pact interaction stubs (`mode=generate`) for Python,
  TypeScript, and Java.

#### Agents
- `agents/quality-sprint` (`/tw-quality-sprint`) — Bounded autonomous loop: runs the appropriate
  test governor, evaluates the decision, runs the remediator, verifies, and iterates up to
  `max_iterations` (default: 3). Mandatory human checkpoint at iteration 2 to review generated
  test quality before continuing.

#### Rules
- `rules/spec-first` — Behavioral rule fragment for `CLAUDE.md` / `.cursorrules`. Instructs the
  AI to offer spec generation before implementation, surface QA blind spots proactively, and fix
  the spec/prompt rather than patching generated output.

---

## [v0.1.0] — 2026-06-19

### Added — Foundation Release

#### Architecture
- `AGENTS.md` — global L1 context file for AI models
- `registry.json` + `config/registry.schema.json` — machine-readable component index
- `config/config.schema.json` — consumer repo configuration schema
- `config/.env.example` — environment variables template

#### Context Layer System (L1–L4)
- `context/snapshot.md` — L2 auto-generated snapshot of all components
- `context/snapshots/*.snapshot.md` — L3 per-type snapshots (skills, agents, prompts, rules, hooks, mcp)
- `context/CHECKPOINT.md` — snapshot freshness tracking (git hash + timestamp)
- `scripts/sync_registry.py` — scans components and regenerates `registry.json`
- `scripts/sync-snapshots.sh` — regenerates L2/L3 snapshots and CHECKPOINT.md
- `scripts/git-hooks/pre-commit` — auto-syncs context on commits that touch component files

#### Templates (all 6 component types)
- `skills/_template/`, `agents/_template/`, `prompts/_template/`, `rules/_template/`,
  `hooks/_template/`, `mcp/_template/`, `tests/_template/`

#### Skills
- `skills/sync-context` (`/tw-sync-context`) — regenerates registry and context snapshots
- `skills/lint-component` (`/tw-lint-component`) — validates component against schema and conventions
- `skills/install-toolkit` (`/tw-install-toolkit`) — AI-guided toolkit installation in consumer repos
- `skills/python-test-governor` (`/tw-python-test-governor`) — audits Python unit test coverage
- `skills/python-test-remediator` (`/tw-python-test-remediator`) — generates/fixes pytest tests from governance report
- `skills/ts-architecture-analyzer` (`/tw-ts-architecture-analyzer`) — deep architectural analysis with Gherkin output
- `skills/ts-test-governor` (`/tw-ts-test-governor`) — audits Jest coverage with severity classification
- `skills/ts-test-remediator` (`/tw-ts-test-remediator`) — generates/fixes Jest specs from governance report

#### Agents
- `agents/scaffold-component` (`/tw-scaffold-component`) — scaffolds new components from templates
- `agents/onboard-repo` (`/tw-onboard-repo`) — analyzes a repo and configures the toolkit

#### Rules
- `rules/claude-base/` — base rules for Claude Code
- `rules/cursor-base/` — base rules for Cursor

#### MCP Servers
- `mcp/tw-github` — GitHub integration (PRs, issues, repository tools)
- `mcp/tw-jira` — Jira integration (issues, sprints, project tools)

#### Scripts and Documentation
- `scripts/install.py` — Python installer for consumer repos
- `scripts/validate.py` — component schema validator
- `docs/onboarding.md`, `docs/contributing.md`, `docs/integration-guide.md`,
  `docs/compatibility-matrix.md`

---

## Version History

| Version | Date | Highlights |
|---|---|---|
| v0.5.0 | 2026-10-14 | 15 new components: security-audit, compliance-audit, test-strategy-generator, stack-health-check, living-docs, chaos-testing, release-readiness agent, client-bootstrap agent, 3 rules (security-first/performance-budget/consultant-mindset), 4 MCP servers (GitLab/SonarQube/Azure DevOps/Confluence) |
| v0.4.0 | 2026-10-14 | 12 new skills: CI pipeline generator, flakiness analyzer, mutation audit, Java stack, performance baseline, a11y audit, visual baseline, quality trend, test factories, qa-coach, integration autodiscovery |
| v0.3.0 | 2026-10-14 | E2E layer: e2e-spec-to-test, e2e-test-governor, e2e-page-object (Cypress + Playwright) |
| v0.2.0 | 2026-10-14 | QA-first suite: exec-spec-generator, golden-master, contract-coverage, quality-sprint agent, spec-first rule |
| v0.1.0 | 2026-06-19 | Foundation: 8 skills (Python + TS governors/remediators + architecture analyzer), 2 agents, 2 rules, 2 MCP servers |

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
