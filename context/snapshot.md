# Toolkit Snapshot (L2)

> Auto-generated on 2026-10-14 16:47 UTC. Do not edit manually.
> Check `context/CHECKPOINT.md` for freshness info before relying on this data.

---

## Summary

| Type | Total | Stable | Deprecated | Experimental |
|---|---|---|---|---|
| Skills | 32 | 32 | 0 | 0 |
| Agents | 5 | 5 | 0 | 0 |
| Prompts | 0 | 0 | 0 | 0 |
| Rules | 6 | 6 | 0 | 0 |
| Hooks | 0 | 0 | 0 | 0 |
| MCP Servers | 6 | 6 | 0 | 0 |

---

## Skills

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| a11y-audit | `tw-a11y-audit` | Injects axe-core accessibility checks into existing Playwright or Cypress tests, or runs standalone WCAG 2.1 audits on specified pages, and produces a violation report classified by impact level and WCAG criterion. | stable | yes | partial | no |
| chaos-testing | `tw-chaos-testing` | Generates resilience tests for circuit breakers, retry logic, timeout handling, and graceful degradation — verifying that the application behaves correctly when downstream services fail. Stack-agnostic with support for Spring Boot (Resilience4j), NestJS, FastAPI, and generic HTTP clients. | stable | yes | partial | no |
| compliance-audit | `tw-compliance-audit` | Generates a compliance gap report and test checklist for GDPR, HIPAA, PCI-DSS, SOX, or ISO 27001. Scans the codebase for compliance-relevant patterns (PII handling, audit logging, data retention, encryption) and maps findings to specific regulatory articles. | stable | yes | partial | no |
| contract-coverage | `tw-contract-coverage` | Scans a repository for inter-service communication (HTTP, messaging, events), maps consumer-provider relationships, detects missing contract tests, and generates Pact interaction stubs for uncovered integrations. | stable | yes | partial | no |
| e2e-page-object | `tw-e2e-page-object` | Generates Page Object Model (POM) classes for Cypress or Playwright from React, Vue, or Angular component files, HTML markup, or route descriptions. Enforces the data-testid selector hierarchy and produces action methods aligned to user behavior. | stable | yes | partial | no |
| e2e-spec-to-test | `tw-e2e-spec-to-test` | Converts a Gherkin feature file into runnable Cypress or Playwright E2E test files following the Page Object Model pattern. Closes the spec-first loop by turning executable specs into production-ready tests with stable selectors and proper async handling. | stable | yes | partial | no |
| e2e-test-governor | `tw-e2e-test-governor` | Audits E2E test coverage by mapping user flows and feature files to existing Cypress or Playwright test files, classifies gaps by risk, detects stale or brittle tests, and produces a governance report with actionable recommendations. | stable | yes | partial | no |
| exec-spec-generator | `tw-exec-spec-generator` | Transforms user stories, acceptance criteria, or existing code into executable Gherkin specs with a QA-first blind spots report surfacing scenarios that developers and BAs typically miss. | stable | yes | partial | no |
| flakiness-analyzer | `tw-flakiness-analyzer` | Analyzes CI test run history to identify non-deterministic (flaky) tests, classifies them by failure pattern and frequency, and produces a remediation plan. Restores developer trust in the test suite by distinguishing real failures from environmental noise. | stable | yes | partial | no |
| golden-master | `tw-golden-master` | Captures behavioral snapshots of a system (Golden Master) and compares future runs against them to detect regressions, unintended behavior changes, or legacy-to-new equivalence during migrations. | stable | yes | partial | no |
| install-toolkit | `tw-install-toolkit` | Guides the user through installing tw-ai-toolkit into a consumer repository. | stable | yes | partial | no |
| integration-discovery | `tw-integration-discovery` | Scans OpenAPI/AsyncAPI specs, Spring controllers, NestJS routes, or Express routers to auto-discover API contracts, generates framework-agnostic Gherkin scenarios for each contract, and produces ready-to-run integration tests — without requiring any manual user story authoring. | stable | yes | partial | no |
| java-test-governor | `tw-java-test-governor` | Audits JUnit 5 unit test coverage in a Java/Spring Boot repository, maps production classes to test files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. | stable | yes | partial | no |
| java-test-remediator | `tw-java-test-remediator` | Consumes a Java/Spring Boot test governance report, assigns Jacoco coverage tiers per class, then generates or updates maintainable JUnit 5 + Mockito test classes to meet tiered line-coverage targets. | stable | yes | partial | no |
| lint-component | `tw-lint-component` | Validates that a toolkit component follows all required conventions and schema rules. | stable | yes | partial | no |
| living-docs | `tw-living-docs` | Reads passing Gherkin feature files and test results to generate living documentation — human-readable reports showing what behavior is verified, what is pending, and what has failed. Publishes to Confluence, generates HTML, or produces structured Markdown. | stable | yes | partial | no |
| mutation-audit | `tw-mutation-audit` | Runs mutation testing (Stryker for TypeScript/JavaScript, mutmut for Python) on tier-A modules identified by the test governor, and produces a mutation score report revealing tests that pass but don't actually catch bugs. | stable | yes | partial | no |
| performance-baseline | `tw-performance-baseline` | Generates k6 (TypeScript/JavaScript) or Locust (Python) performance test scripts from OpenAPI specs or detected API endpoints, establishes latency and error rate thresholds, and compares against previously recorded baselines to detect performance regressions. | stable | yes | partial | no |
| pipeline-generator | `tw-pipeline-generator` | Generates a complete CI/CD quality pipeline (GitHub Actions or GitLab CI) that chains all tw-ai-toolkit skills as automated quality gates. Turns the toolkit from tribal knowledge into enforced infrastructure. | stable | yes | partial | no |
| python-test-governor | `tw-python-test-governor` | Audits Python unit test coverage, maps production modules to tests, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. | stable | yes | partial | no |
| python-test-remediator | `tw-python-test-remediator` | Consumes a Python test governance report, assigns coverage tiers per module, then generates or updates maintainable pytest and unittest tests to meet tiered line-coverage targets. | stable | yes | partial | no |
| qa-coach | `tw-qa-coach` | Analyzes source code, pull requests, or module designs for testability anti-patterns, explains WHY each pattern makes testing harder, and proposes concrete refactoring paths — bridging the gap between developer decisions and QA consequences. | stable | yes | partial | no |
| quality-trend | `tw-quality-trend` | Reads historical governance reports, mutation scores, flakiness analyses, and E2E coverage reports to generate a quality trend dashboard showing whether the test suite is improving or degrading over time. | stable | yes | partial | no |
| security-audit | `tw-security-audit` | Runs a multi-layer security audit combining static analysis (OWASP Top 10 code patterns), dependency vulnerability scanning (npm audit, pip-audit, OWASP Dependency Check), and optional DAST with OWASP ZAP. Stack-agnostic and CI-ready. | stable | yes | partial | no |
| stack-health-check | `tw-stack-health-check` | Comprehensive Day 1 assessment of any existing project — detects tech stack, measures current test coverage, evaluates CI health, checks dependency freshness, identifies security debt, and produces an executive summary plus technical detail report. The consultant's first deliverable. | stable | yes | partial | no |
| sync-context | `tw-sync-context` | Regenerates the toolkit registry and context snapshots from current component files. | stable | yes | partial | no |
| test-factory | `tw-test-factory` | Generates test data factory classes from domain models (TypeORM entities, SQLAlchemy models, JPA entities) with cleanup strategies, ensuring E2E and integration tests are isolated, deterministic, and leave no pollution between runs. | stable | yes | partial | no |
| test-strategy-generator | `tw-test-strategy-generator` | Analyzes a project's stack, team size, risk profile, and delivery model to generate a tailored QA Strategy document — the first deliverable a consultant produces for any new client. Covers test pyramid, tooling recommendations, coverage targets, CI gates, and a phased implementation roadmap. | stable | yes | partial | no |
| ts-architecture-analyzer | `tw-ts-architecture-analyzer` | Analyzes TypeScript/NestJS code with adaptive depth, auto-detects granularity level (L1-L4), identifies architectural risks, silent traps, and scalability issues, and produces a technical health scorecard with Gherkin feature file. | stable | yes | partial | no |
| ts-test-governor | `tw-ts-test-governor` | Audits Jest unit test coverage in a TypeScript/NestJS repository, maps production modules to spec files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions. | stable | yes | partial | no |
| ts-test-remediator | `tw-ts-test-remediator` | Consumes a TypeScript/NestJS test governance report, assigns Istanbul coverage tiers per module, then generates or updates maintainable Jest spec files to meet tiered line-coverage targets. | stable | yes | partial | no |
| visual-baseline | `tw-visual-baseline` | Captures visual snapshots of application pages (Golden Master for UI) and compares them pixel-by-pixel to detect unintended visual regressions — CSS changes, layout shifts, or component rendering issues — invisible to functional tests. | stable | yes | partial | no |

## Agents

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| client-bootstrap | `tw-client-bootstrap` | Autonomous agent that executes the full Day 1 consultant workflow — stack health check, QA strategy generation, initial test governance, security baseline, and CI pipeline setup. Produces a complete engagement starter kit that establishes quality foundations from the first day. | stable | yes | partial | no |
| onboard-repo | `/tw-onboard-repo` | Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project. | stable | yes | partial | no |
| quality-sprint | `/tw-quality-sprint` | Autonomous bounded loop that chains test governance and remediation until coverage targets are met or a human checkpoint is reached. Max 3 iterations with mandatory review at iteration 2. | stable | yes | partial | no |
| release-readiness | `tw-release-readiness` | Autonomous agent that orchestrates all quality gates — unit coverage, mutation score, flakiness, performance, accessibility, security, visual regression, and contract tests — and produces a single GO / NO-GO decision with a full evidence matrix. The consolidated release quality checkpoint. | stable | yes | partial | no |
| scaffold-component | `/tw-scaffold-component` | Creates a new toolkit component from the appropriate template given a type and name. | stable | yes | partial | no |

## Prompts

*(none yet)*

## Rules

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| claude-base | — | Base behavioral rules for Claude Code when working in a repo that uses tw-ai-toolkit. | stable | yes | no | no |
| consultant-mindset | — | Behavioral rule that instructs AI assistants to operate with a consulting mindset when joining a new project — assess before assuming, make findings visible, generate artifacts that communicate value, and adapt recommendations to the client's context and constraints. | stable | no | no | no |
| cursor-base | — | Base behavioral rules for Cursor when working in a repo that uses tw-ai-toolkit. | stable | no | yes | no |
| performance-budget | — | Behavioral rule that instructs AI assistants to flag potential performance regressions at design time — before implementing queries, loops, API calls, or data transformations that could silently degrade P95 latency. | stable | no | no | no |
| security-first | — | Behavioral rule that instructs AI assistants to surface security implications proactively — before implementing features that handle sensitive data, before suggesting third-party integrations, and before any code that touches auth, payments, PII, or external APIs. | stable | no | no | no |
| spec-first | — | Establishes a spec-first quality mindset for AI assistants — surface test scenarios before implementation, treat the spec as the product, and apply the QA perspective that individual developers typically miss. | stable | no | no | no |

## Hooks

*(none yet)*

## MCP Servers

| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |
|---|---|---|---|---|---|---|
| tw-azure-devops | — | Azure DevOps MCP server exposing Boards (work items), Pipelines (builds and releases), Repos (PRs, commits), and Test Plans to AI assistants. Essential for Microsoft-stack clients using Azure DevOps as their primary platform. | stable | yes | yes | no |
| tw-confluence | — | Confluence MCP server exposing space, page, and comment tools to AI assistants. Enables the AI to read and publish documentation — including living docs, QA strategy documents, and governance reports — directly to the team wiki. | stable | yes | yes | no |
| tw-github | — | GitHub MCP server exposing PR, issue, and repository tools to AI assistants. | stable | yes | yes | no |
| tw-gitlab | — | GitLab MCP server exposing merge requests, CI/CD pipelines, issues, and repository tools to AI assistants. Essential for teams using GitLab as their primary VCS and CI platform. | stable | yes | yes | no |
| tw-jira | — | Jira MCP server exposing issue, sprint, and project tools to AI assistants. | stable | yes | yes | no |
| tw-sonarqube | — | SonarQube/SonarCloud MCP server exposing code quality metrics, security hotspots, code smells, coverage data, and quality gate status to AI assistants. Enables AI-assisted triage of SonarQube findings. | stable | yes | yes | no |

---

For full metadata (parameters, tags), load `registry.json`.
For per-category detail, load `context/snapshots/<type>.snapshot.md`.
