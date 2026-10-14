# Cursor Compatibility Snapshot (L3+)

> Auto-generated on 2026-10-14 16:47 UTC. Do not edit manually.
> Shows only components with `compatible_with.cursor: full` or `partial`.
> For full compatibility details see `docs/compatibility-matrix.md`.

---

## Available for Cursor (44 components)

| Name | Type | Invocation | Compatibility | Description |
|---|---|---|---|---|
| a11y-audit | Skills | `tw-a11y-audit` | partial | Injects axe-core accessibility checks into existing Playwright or Cypress tests, or runs standalone WCAG 2.1 audits on specified pages, and produces a violation report classified by impact level and WCAG criterion. |
| chaos-testing | Skills | `tw-chaos-testing` | partial | Generates resilience tests for circuit breakers, retry logic, timeout handling, and graceful degradation — verifying that the application behaves correctly when downstream services fail. Stack-agnostic with support for Spring Boot (Resilience4j), NestJS, FastAPI, and generic HTTP clients. |
| compliance-audit | Skills | `tw-compliance-audit` | partial | Generates a compliance gap report and test checklist for GDPR, HIPAA, PCI-DSS, SOX, or ISO 27001. Scans the codebase for compliance-relevant patterns (PII handling, audit logging, data retention, encryption) and maps findings to specific regulatory articles. |
| contract-coverage | Skills | `tw-contract-coverage` | partial | Scans a repository for inter-service communication (HTTP, messaging, events), maps consumer-provider relationships, detects missing contract tests, and generates Pact interaction stubs for uncovered integrations. |
| e2e-page-object | Skills | `tw-e2e-page-object` | partial | Generates Page Object Model (POM) classes for Cypress or Playwright from React, Vue, or Angular component files, HTML markup, or route descriptions. Enforces the data-testid selector hierarchy and produces action methods aligned to user behavior. |
| e2e-spec-to-test | Skills | `tw-e2e-spec-to-test` | partial | Converts a Gherkin feature file into runnable Cypress or Playwright E2E test files following the Page Object Model pattern. Closes the spec-first loop by turning executable specs into production-ready tests with stable selectors and proper async handling. |
| e2e-test-governor | Skills | `tw-e2e-test-governor` | partial | Audits E2E test coverage by mapping user flows and feature files to existing Cypress or Playwright test files, classifies gaps by risk, detects stale or brittle tests, and produces a governance report with actionable recommendations. |
| exec-spec-generator | Skills | `tw-exec-spec-generator` | partial | Transforms user stories, acceptance criteria, or existing code into executable Gherkin specs with a QA-first blind spots report surfacing scenarios that developers and BAs typically miss. |
| flakiness-analyzer | Skills | `tw-flakiness-analyzer` | partial | Analyzes CI test run history to identify non-deterministic (flaky) tests, classifies them by failure pattern and frequency, and produces a remediation plan. Restores developer trust in the test suite by distinguishing real failures from environmental noise. |
| golden-master | Skills | `tw-golden-master` | partial | Captures behavioral snapshots of a system (Golden Master) and compares future runs against them to detect regressions, unintended behavior changes, or legacy-to-new equivalence during migrations. |
| install-toolkit | Skills | `tw-install-toolkit` | partial | Guides the user through installing tw-ai-toolkit into a consumer repository. |
| integration-discovery | Skills | `tw-integration-discovery` | partial | Scans OpenAPI/AsyncAPI specs, Spring controllers, NestJS routes, or Express routers to auto-discover API contracts, generates framework-agnostic Gherkin scenarios for each contract, and produces ready-to-run integration tests — without requiring any manual user story authoring. |
| java-test-governor | Skills | `tw-java-test-governor` | partial | Audits JUnit 5 unit test coverage in a Java/Spring Boot repository, maps production classes to test files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. |
| java-test-remediator | Skills | `tw-java-test-remediator` | partial | Consumes a Java/Spring Boot test governance report, assigns Jacoco coverage tiers per class, then generates or updates maintainable JUnit 5 + Mockito test classes to meet tiered line-coverage targets. |
| lint-component | Skills | `tw-lint-component` | partial | Validates that a toolkit component follows all required conventions and schema rules. |
| living-docs | Skills | `tw-living-docs` | partial | Reads passing Gherkin feature files and test results to generate living documentation — human-readable reports showing what behavior is verified, what is pending, and what has failed. Publishes to Confluence, generates HTML, or produces structured Markdown. |
| mutation-audit | Skills | `tw-mutation-audit` | partial | Runs mutation testing (Stryker for TypeScript/JavaScript, mutmut for Python) on tier-A modules identified by the test governor, and produces a mutation score report revealing tests that pass but don't actually catch bugs. |
| performance-baseline | Skills | `tw-performance-baseline` | partial | Generates k6 (TypeScript/JavaScript) or Locust (Python) performance test scripts from OpenAPI specs or detected API endpoints, establishes latency and error rate thresholds, and compares against previously recorded baselines to detect performance regressions. |
| pipeline-generator | Skills | `tw-pipeline-generator` | partial | Generates a complete CI/CD quality pipeline (GitHub Actions or GitLab CI) that chains all tw-ai-toolkit skills as automated quality gates. Turns the toolkit from tribal knowledge into enforced infrastructure. |
| python-test-governor | Skills | `tw-python-test-governor` | partial | Audits Python unit test coverage, maps production modules to tests, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. |
| python-test-remediator | Skills | `tw-python-test-remediator` | partial | Consumes a Python test governance report, assigns coverage tiers per module, then generates or updates maintainable pytest and unittest tests to meet tiered line-coverage targets. |
| qa-coach | Skills | `tw-qa-coach` | partial | Analyzes source code, pull requests, or module designs for testability anti-patterns, explains WHY each pattern makes testing harder, and proposes concrete refactoring paths — bridging the gap between developer decisions and QA consequences. |
| quality-trend | Skills | `tw-quality-trend` | partial | Reads historical governance reports, mutation scores, flakiness analyses, and E2E coverage reports to generate a quality trend dashboard showing whether the test suite is improving or degrading over time. |
| security-audit | Skills | `tw-security-audit` | partial | Runs a multi-layer security audit combining static analysis (OWASP Top 10 code patterns), dependency vulnerability scanning (npm audit, pip-audit, OWASP Dependency Check), and optional DAST with OWASP ZAP. Stack-agnostic and CI-ready. |
| stack-health-check | Skills | `tw-stack-health-check` | partial | Comprehensive Day 1 assessment of any existing project — detects tech stack, measures current test coverage, evaluates CI health, checks dependency freshness, identifies security debt, and produces an executive summary plus technical detail report. The consultant's first deliverable. |
| sync-context | Skills | `tw-sync-context` | partial | Regenerates the toolkit registry and context snapshots from current component files. |
| test-factory | Skills | `tw-test-factory` | partial | Generates test data factory classes from domain models (TypeORM entities, SQLAlchemy models, JPA entities) with cleanup strategies, ensuring E2E and integration tests are isolated, deterministic, and leave no pollution between runs. |
| test-strategy-generator | Skills | `tw-test-strategy-generator` | partial | Analyzes a project's stack, team size, risk profile, and delivery model to generate a tailored QA Strategy document — the first deliverable a consultant produces for any new client. Covers test pyramid, tooling recommendations, coverage targets, CI gates, and a phased implementation roadmap. |
| ts-architecture-analyzer | Skills | `tw-ts-architecture-analyzer` | partial | Analyzes TypeScript/NestJS code with adaptive depth, auto-detects granularity level (L1-L4), identifies architectural risks, silent traps, and scalability issues, and produces a technical health scorecard with Gherkin feature file. |
| ts-test-governor | Skills | `tw-ts-test-governor` | partial | Audits Jest unit test coverage in a TypeScript/NestJS repository, maps production modules to spec files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. |
| ts-test-remediator | Skills | `tw-ts-test-remediator` | partial | Consumes a TypeScript/NestJS test governance report, assigns Istanbul coverage tiers per module, then generates or updates maintainable Jest spec files to meet tiered line-coverage targets. |
| visual-baseline | Skills | `tw-visual-baseline` | partial | Captures visual snapshots of application pages (Golden Master for UI) and compares them pixel-by-pixel to detect unintended visual regressions — CSS changes, layout shifts, or component rendering issues — invisible to functional tests. |
| client-bootstrap | Agents | `tw-client-bootstrap` | partial | Autonomous agent that executes the full Day 1 consultant workflow — stack health check, QA strategy generation, initial test governance, security baseline, and CI pipeline setup. Produces a complete engagement starter kit that establishes quality foundations from the first day. |
| onboard-repo | Agents | `/tw-onboard-repo` | partial | Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project. |
| quality-sprint | Agents | `/tw-quality-sprint` | partial | Autonomous bounded loop that chains test governance and remediation until coverage targets are met or a human checkpoint is reached. Max 3 iterations with mandatory review at iteration 2. |
| release-readiness | Agents | `tw-release-readiness` | partial | Autonomous agent that orchestrates all quality gates — unit coverage, mutation score, flakiness, performance, accessibility, security, visual regression, and contract tests — and produces a single GO / NO-GO decision with a full evidence matrix. The consolidated release quality checkpoint. |
| scaffold-component | Agents | `/tw-scaffold-component` | partial | Creates a new toolkit component from the appropriate template given a type and name. |
| cursor-base | Rules | — | full | Base behavioral rules for Cursor when working in a repo that uses tw-ai-toolkit. |
| tw-azure-devops | MCP Servers | — | full | Azure DevOps MCP server exposing Boards (work items), Pipelines (builds and releases), Repos (PRs, commits), and Test Plans to AI assistants. Essential for Microsoft-stack clients using Azure DevOps as their primary platform. |
| tw-confluence | MCP Servers | — | full | Confluence MCP server exposing space, page, and comment tools to AI assistants. Enables the AI to read and publish documentation — including living docs, QA strategy documents, and governance reports — directly to the team wiki. |
| tw-github | MCP Servers | — | full | GitHub MCP server exposing PR, issue, and repository tools to AI assistants. |
| tw-gitlab | MCP Servers | — | full | GitLab MCP server exposing merge requests, CI/CD pipelines, issues, and repository tools to AI assistants. Essential for teams using GitLab as their primary VCS and CI platform. |
| tw-jira | MCP Servers | — | full | Jira MCP server exposing issue, sprint, and project tools to AI assistants. |
| tw-sonarqube | MCP Servers | — | full | SonarQube/SonarCloud MCP server exposing code quality metrics, security hotspots, code smells, coverage data, and quality gate status to AI assistants. Enables AI-assisted triage of SonarQube findings. |

## Cursor Quick Start

1. Copy `rules/cursor-base/fragment.md` into your `.cursorrules`
2. Configure MCP servers in `.cursor/mcp.json` (see `docs/mcp-guide.md`)
3. Use Cursor Composer for skills and agents
4. For component details, read `context/snapshots/<type>.snapshot.md`
