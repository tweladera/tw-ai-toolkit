# Skills Snapshot (L3)

> Auto-generated on 2026-10-14 16:47 UTC. Do not edit manually.
> For a quick overview of all types, load `context/snapshot.md` (L2).

---

## a11y-audit

**Description:** Injects axe-core accessibility checks into existing Playwright or Cypress tests, or runs standalone WCAG 2.1 audits on specified pages, and produces a violation report classified by impact level and WCAG criterion.

**Invocation:** `tw-a11y-audit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `framework` | string | False |  | E2E framework: 'playwright' or 'cypress'. Auto-detected. |
| `pages` | string | False |  | Comma-separated page URLs or paths to audit (e.g. '/login,/orders,/dashboard'). If omitted, detects pages from existing E2E tests. |
| `wcag_level` | string | False | AA | WCAG conformance level: 'A', 'AA', or 'AAA'. Default: AA (most common regulatory requirement). |
| `mode` | string | False | inject | 'inject' to add axe-core checks to existing tests. 'standalone' to run a dedicated accessibility scan. 'report-only' to audit without modifying test files. |

**Tags:** `accessibility`, `a11y`, `wcag`, `axe-core`, `playwright`, `cypress`, `compliance`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/a11y-audit/skill.md`

---

## chaos-testing

**Description:** Generates resilience tests for circuit breakers, retry logic, timeout handling, and graceful degradation — verifying that the application behaves correctly when downstream services fail. Stack-agnostic with support for Spring Boot (Resilience4j), NestJS, FastAPI, and generic HTTP clients.

**Invocation:** `tw-chaos-testing`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | False |  | Path to service client files or directory. If omitted, auto-detects HTTP clients and downstream integrations from the codebase. |
| `framework` | string | False |  | Resilience framework: 'resilience4j' (Spring Boot), 'nestjs', 'fastapi', 'generic'. Auto-detected. |
| `scenarios` | string | False | all | Comma-separated resilience scenarios: 'circuit-breaker', 'timeout', 'retry', 'fallback', 'bulkhead', 'rate-limit'. Default: all. |

**Tags:** `resilience`, `chaos-testing`, `circuit-breaker`, `fault-tolerance`, `timeout`, `retry`, `microservices`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/chaos-testing/skill.md`

---

## compliance-audit

**Description:** Generates a compliance gap report and test checklist for GDPR, HIPAA, PCI-DSS, SOX, or ISO 27001. Scans the codebase for compliance-relevant patterns (PII handling, audit logging, data retention, encryption) and maps findings to specific regulatory articles.

**Invocation:** `tw-compliance-audit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `framework` | string | True |  | Compliance framework(s): 'gdpr', 'hipaa', 'pci-dss', 'sox', 'iso27001', or comma-separated for multiple (e.g. 'gdpr,hipaa'). Use 'all' to apply all frameworks. |
| `industry` | string | False |  | Industry context for risk prioritization: 'healthcare', 'finance', 'retail', 'government', 'saas'. Adjusts which requirements are critical vs. informational. |
| `mode` | string | False | assess | 'assess' to analyze current state and generate gap report, 'checklist' to generate a test checklist only (no code scanning), 'full' for both. |
| `output` | string | False | report | 'report' for full compliance gap analysis, 'checklist' for an actionable test checklist, 'csv' for import into GRC tools. |

**Tags:** `compliance`, `gdpr`, `hipaa`, `pci-dss`, `sox`, `iso27001`, `regulatory`, `security`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/compliance-audit/skill.md`

---

## contract-coverage

**Description:** Scans a repository for inter-service communication (HTTP, messaging, events), maps consumer-provider relationships, detects missing contract tests, and generates Pact interaction stubs for uncovered integrations.

**Invocation:** `tw-contract-coverage`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `mode` | string | False | detect | 'detect' to report missing contracts only. 'generate' to also create Pact interaction stubs for uncovered integrations. |
| `path` | string | False |  | Directory to scan (defaults to repo root). Use to focus on a specific service or module. |
| `focus` | string | False |  | Service name or path to focus the report on (e.g. 'payment-service'). Shows only contracts where this service is consumer or provider. |

**Tags:** `contract-testing`, `pact`, `integration`, `microservices`, `qa`, `cdc`

**Added in:** v0.2.0

**Definition file:** `skills/contract-coverage/skill.md`

---

## e2e-page-object

**Description:** Generates Page Object Model (POM) classes for Cypress or Playwright from React, Vue, or Angular component files, HTML markup, or route descriptions. Enforces the data-testid selector hierarchy and produces action methods aligned to user behavior.

**Invocation:** `tw-e2e-page-object`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | True |  | Path to a component file (React/Vue/Angular), HTML file, or a text description of the page (e.g. 'Order form with amount input, currency selector, submit button'). |
| `framework` | string | False |  | Target E2E framework: 'cypress' or 'playwright'. Auto-detected if omitted. |
| `name` | string | False |  | Name for the POM class (e.g. 'OrderPage', 'LoginPage'). Inferred from source file name if omitted. |
| `output_dir` | string | False |  | Directory for the generated POM file. Defaults to 'cypress/pages/' or 'tests/pages/'. |

**Tags:** `e2e`, `cypress`, `playwright`, `page-object-model`, `selectors`, `qa`

**Added in:** v0.3.0

**Definition file:** `skills/e2e-page-object/skill.md`

---

## e2e-spec-to-test

**Description:** Converts a Gherkin feature file into runnable Cypress or Playwright E2E test files following the Page Object Model pattern. Closes the spec-first loop by turning executable specs into production-ready tests with stable selectors and proper async handling.

**Invocation:** `tw-e2e-spec-to-test`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `feature` | string | True |  | Path to the .feature file to convert. Typically produced by /tw-exec-spec-generator. |
| `framework` | string | False |  | Target E2E framework: 'cypress' or 'playwright'. Auto-detected from cypress.config.* or playwright.config.* if omitted. |
| `pages` | string | False |  | Comma-separated page names to generate POM classes for (e.g. 'LoginPage,OrderPage'). If omitted, inferred from feature file scenarios. |
| `base_url` | string | False |  | Base URL of the application under test (e.g. 'http://localhost:3000'). Read from framework config if omitted. |
| `output_dir` | string | False |  | Directory for generated test files. Defaults to 'cypress/e2e/' for Cypress or 'tests/' for Playwright. |

**Tags:** `e2e`, `cypress`, `playwright`, `bdd`, `gherkin`, `page-object-model`, `qa`

**Added in:** v0.3.0

**Definition file:** `skills/e2e-spec-to-test/skill.md`

---

## e2e-test-governor

**Description:** Audits E2E test coverage by mapping user flows and feature files to existing Cypress or Playwright test files, classifies gaps by risk, detects stale or brittle tests, and produces a governance report with actionable recommendations.

**Invocation:** `tw-e2e-test-governor`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `framework` | string | False |  | E2E framework to audit: 'cypress' or 'playwright'. Auto-detected from config files if omitted. |
| `features_dir` | string | False |  | Directory containing .feature files to cross-reference. Defaults to 'specs/' or 'features/' if present. |
| `base_ref` | string | False |  | Git ref to diff against (e.g. origin/main). When provided, focuses the report on flows touched by changed code. |
| `strict_selectors` | boolean | False | false | When true, flags any selector that is not data-testid or ARIA-based as a selector health risk. |

**Tags:** `e2e`, `cypress`, `playwright`, `governance`, `coverage`, `qa`

**Added in:** v0.3.0

**Definition file:** `skills/e2e-test-governor/skill.md`

---

## exec-spec-generator

**Description:** Transforms user stories, acceptance criteria, or existing code into executable Gherkin specs with a QA-first blind spots report surfacing scenarios that developers and BAs typically miss.

**Invocation:** `tw-exec-spec-generator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `story` | string | True |  | User story text, acceptance criteria, or feature description. Paste inline or provide a file path. |
| `artifact` | string | False |  | Path to existing code, OpenAPI/AsyncAPI spec, or JSON schema that contextualizes the story. Optional but improves scenario quality significantly. |
| `stack` | string | False |  | Target test framework for generated step stubs (jest/pytest/junit5). If omitted, auto-detected from the repo. |
| `output_dir` | string | False | specs/ | Directory where the .feature file and blind spots report are saved. |

**Tags:** `bdd`, `gherkin`, `spec-first`, `qa`, `testing`, `requirements`

**Added in:** v0.2.0

**Definition file:** `skills/exec-spec-generator/skill.md`

---

## flakiness-analyzer

**Description:** Analyzes CI test run history to identify non-deterministic (flaky) tests, classifies them by failure pattern and frequency, and produces a remediation plan. Restores developer trust in the test suite by distinguishing real failures from environmental noise.

**Invocation:** `tw-flakiness-analyzer`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | False | junit-xml | Source of test history: 'junit-xml' (reads test-results/ directory) or 'github-actions' (reads via GitHub MCP) or 'gitlab-ci' (reads via GitLab API). |
| `results_dir` | string | False | test-results | Directory containing JUnit XML test result files from multiple CI runs. Used when source=junit-xml. |
| `threshold` | number | False | 10 | Minimum flakiness rate (%) to flag a test as flaky. Default: 10 (fails in 10% of runs with the same code). |
| `window` | string | False | 30d | Time window for analysis: '7d', '30d', '90d'. Longer windows surface intermittent flakiness. |

**Tags:** `flakiness`, `test-reliability`, `ci-cd`, `quality`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/flakiness-analyzer/skill.md`

---

## golden-master

**Description:** Captures behavioral snapshots of a system (Golden Master) and compares future runs against them to detect regressions, unintended behavior changes, or legacy-to-new equivalence during migrations.

**Invocation:** `tw-golden-master`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `mode` | string | True |  | Operation mode: 'capture' to record a new Golden Master, 'compare' to diff current output against the saved master. |
| `name` | string | True |  | Identifier for this Golden Master set (e.g. 'order-placement', 'pricing-engine'). Used as directory name under .golden/. |
| `target` | string | False |  | Command, script, or function path to execute for capture/compare. Required for 'capture'. For 'compare', defaults to same target used during capture (stored in manifest). |
| `inputs` | string | False |  | Path to a JSON file containing an array of test input objects. If omitted in capture mode, Claude will prompt for or infer representative inputs. |
| `tolerance` | string | False | normalized | Comparison mode: 'strict' (exact byte match) or 'normalized' (masks UUIDs, timestamps, auto-increment IDs before diffing). Default: normalized. |
| `version` | string | False |  | Version tag for the captured master (e.g. 'v1.2.0', 'pre-refactor'). Defaults to current git short SHA. |

**Tags:** `golden-master`, `regression`, `migration`, `equivalence`, `snapshot`, `qa`

**Added in:** v0.2.0

**Definition file:** `skills/golden-master/skill.md`

---

## install-toolkit

**Description:** Guides the user through installing tw-ai-toolkit into a consumer repository.

**Invocation:** `tw-install-toolkit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `repo_path` | string | False | . | Absolute or relative path to the consumer repo root (defaults to current directory) |
| `version` | string | False | latest | Toolkit version tag to install (e.g. v1.0.0). Defaults to latest stable tag. |

**Tags:** `setup`, `installation`, `onboarding`

**Added in:** v0.1.0

**Definition file:** `skills/install-toolkit/skill.md`

---

## integration-discovery

**Description:** Scans OpenAPI/AsyncAPI specs, Spring controllers, NestJS routes, or Express routers to auto-discover API contracts, generates framework-agnostic Gherkin scenarios for each contract, and produces ready-to-run integration tests — without requiring any manual user story authoring.

**Invocation:** `tw-integration-discovery`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | True |  | Path to OpenAPI/AsyncAPI YAML/JSON, or source directory for annotation scanning (e.g. 'openapi/orders.yaml', 'src/controllers/', 'src/main/java/'). |
| `output` | string | False | both | 'gherkin' for Gherkin .feature files only, 'tests' for framework-specific test files only, 'both' for Gherkin + tests. |
| `framework` | string | False |  | Test framework: 'supertest' (NestJS/Express), 'rest-assured' (Spring), 'httpx' (FastAPI/Django). Auto-detected. |
| `focus` | string | False | all | Comma-separated HTTP methods to focus on: 'GET,POST' limits generation to read and create scenarios. Default: all. |
| `contract_mode` | string | False | happy+error | 'happy' for 200/201 flows only, 'error' for 4xx/5xx flows only, 'happy+error' for both (default), 'full' adds boundary and auth scenarios. |

**Tags:** `integration`, `autodiscovery`, `openapi`, `asyncapi`, `gherkin`, `contract`, `spring`, `nestjs`, `express`, `fastapi`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/integration-discovery/skill.md`

---

## java-test-governor

**Description:** Audits JUnit 5 unit test coverage in a Java/Spring Boot repository, maps production classes to test files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions.

**Invocation:** `tw-java-test-governor`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `base_ref` | string | False |  | Git ref to diff against (e.g. origin/main). When provided, focuses on changed classes. |
| `jacoco_xml` | string | False |  | Path to Jacoco XML coverage report (e.g. target/site/jacoco/jacoco.xml). Enables per-class coverage signals. |
| `test_results_dir` | string | False |  | Directory containing Surefire/Failsafe JUnit XML output for failing test detection. |
| `build_tool` | string | False |  | Build tool: 'maven' or 'gradle'. Auto-detected from pom.xml or build.gradle. |

**Tags:** `java`, `spring-boot`, `junit5`, `mockito`, `jacoco`, `testing`, `coverage`, `governance`

**Added in:** v0.4.0

**Definition file:** `skills/java-test-governor/skill.md`

---

## java-test-remediator

**Description:** Consumes a Java/Spring Boot test governance report, assigns Jacoco coverage tiers per class, then generates or updates maintainable JUnit 5 + Mockito test classes to meet tiered line-coverage targets.

**Invocation:** `tw-java-test-remediator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `report_file` | string | False |  | Path to the governance report produced by /tw-java-test-governor. If omitted, uses the most recent TEST_GOVERNANCE_REPORT_*.md. |
| `base_ref` | string | False |  | Git ref used by /tw-java-test-governor. Used to regenerate the report if no report file is provided. |
| `build_tool` | string | False |  | Build tool: 'maven' or 'gradle'. Auto-detected. |

**Tags:** `java`, `spring-boot`, `junit5`, `mockito`, `testing`, `coverage`, `remediation`

**Added in:** v0.4.0

**Definition file:** `skills/java-test-remediator/skill.md`

---

## lint-component

**Description:** Validates that a toolkit component follows all required conventions and schema rules.

**Invocation:** `tw-lint-component`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | True |  | Relative path to the component directory (e.g. skills/lint-component) |

**Tags:** `validation`, `quality`, `maintenance`

**Added in:** v0.1.0

**Definition file:** `skills/lint-component/skill.md`

---

## living-docs

**Description:** Reads passing Gherkin feature files and test results to generate living documentation — human-readable reports showing what behavior is verified, what is pending, and what has failed. Publishes to Confluence, generates HTML, or produces structured Markdown.

**Invocation:** `tw-living-docs`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | False |  | Path to .feature files or directory. Defaults to 'features/' or 'specs/'. Can also be a test results directory (JUnit XML, Playwright JSON, Cypress JSON). |
| `output` | string | False | markdown | 'markdown' for .md files, 'html' for standalone HTML report, 'confluence' for Confluence wiki markup ready to publish. |
| `output_dir` | string | False | docs/living/ | Directory where documentation files are saved. |
| `include_pending` | boolean | False | true | When true, includes pending/unimplemented scenarios marked as 'not yet automated'. Default: true. |

**Tags:** `documentation`, `living-docs`, `gherkin`, `bdd`, `confluence`, `reporting`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/living-docs/skill.md`

---

## mutation-audit

**Description:** Runs mutation testing (Stryker for TypeScript/JavaScript, mutmut for Python) on tier-A modules identified by the test governor, and produces a mutation score report revealing tests that pass but don't actually catch bugs.

**Invocation:** `tw-mutation-audit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `modules` | string | False |  | Comma-separated paths to modules to mutate. If omitted, reads tier-A modules from the latest TEST_GOVERNANCE_REPORT_*.md. |
| `framework` | string | False |  | Mutation framework: 'stryker' (TypeScript/JS) or 'mutmut' (Python). Auto-detected from project. |
| `timeout` | number | False | 300 | Timeout in seconds per module. Mutation testing is slow — default 5 minutes per module. |
| `threshold` | number | False | 70 | Minimum acceptable mutation score (%). Below this threshold the report flags a quality debt warning. |

**Tags:** `mutation-testing`, `stryker`, `mutmut`, `test-quality`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/mutation-audit/skill.md`

---

## performance-baseline

**Description:** Generates k6 (TypeScript/JavaScript) or Locust (Python) performance test scripts from OpenAPI specs or detected API endpoints, establishes latency and error rate thresholds, and compares against previously recorded baselines to detect performance regressions.

**Invocation:** `tw-performance-baseline`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `spec` | string | False |  | Path to OpenAPI YAML/JSON spec file. If omitted, endpoints are detected from Spring controllers or Express/NestJS routes. |
| `tool` | string | False |  | Performance tool: 'k6' or 'locust'. Auto-detected: k6 if TypeScript/JS project, locust if Python. |
| `mode` | string | False | baseline | 'baseline' to establish thresholds from first run, 'compare' to diff against saved baseline, 'generate' to only output scripts without running. |
| `p95_threshold_ms` | number | False | 500 | P95 latency threshold in milliseconds. Requests exceeding this are flagged as regressions. Default: 500ms. |
| `error_rate_threshold` | number | False | 1 | Maximum acceptable error rate (%). Default: 1%. |
| `vus` | number | False | 10 | Virtual users (concurrent load). Default: 10 for baseline, increase for load testing. |

**Tags:** `performance`, `k6`, `locust`, `load-testing`, `regression`, `api`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/performance-baseline/skill.md`

---

## pipeline-generator

**Description:** Generates a complete CI/CD quality pipeline (GitHub Actions or GitLab CI) that chains all tw-ai-toolkit skills as automated quality gates. Turns the toolkit from tribal knowledge into enforced infrastructure.

**Invocation:** `tw-pipeline-generator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `platform` | string | False |  | CI platform: 'github' or 'gitlab'. Auto-detected from .github/ or .gitlab-ci.yml presence. |
| `stack` | string | False |  | Project stack: 'typescript', 'python', or 'java'. Auto-detected from project files. |
| `stages` | string | False | lint,unit,e2e,contracts | Comma-separated pipeline stages to include: lint, unit, e2e, contracts, mutation, performance, a11y. Default: lint,unit,e2e,contracts |
| `nightly` | boolean | False | false | When true, generates a separate nightly job for expensive checks (mutation testing, full performance baseline). |
| `fail_on` | string | False | critical | Pipeline fail threshold: 'critical' (only CRITICAL gaps block merge), 'high' (HIGH + CRITICAL), 'any' (any gap blocks merge). |

**Tags:** `ci-cd`, `github-actions`, `gitlab-ci`, `pipeline`, `quality-gates`, `automation`

**Added in:** v0.4.0

**Definition file:** `skills/pipeline-generator/skill.md`

---

## python-test-governor

**Description:** Audits Python unit test coverage, maps production modules to tests, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions.

**Invocation:** `tw-python-test-governor`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `base_ref` | string | False |  | Git ref to diff against (e.g. origin/main). When provided, the report focuses on changed modules. |
| `coverage_xml` | string | False |  | Path to coverage.xml generated by coverage.py. Enables per-module coverage signals. |
| `test_results_dir` | string | False |  | Directory containing pytest JUnit XML output for failing test detection. |

**Tags:** `python`, `testing`, `coverage`, `qa`, `governance`

**Added in:** v0.1.0

**Definition file:** `skills/python-test-governor/skill.md`

---

## python-test-remediator

**Description:** Consumes a Python test governance report, assigns coverage tiers per module, then generates or updates maintainable pytest and unittest tests to meet tiered line-coverage targets.

**Invocation:** `tw-python-test-remediator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `report_file` | string | False |  | Path to the governance report file produced by /tw-python-test-governor. If omitted, Claude will look for the most recent TEST_GOVERNANCE_REPORT_*.md in the project root. |
| `base_ref` | string | False |  | Git ref used by /tw-python-test-governor (e.g. origin/main). Passed to the inventory script to regenerate the report when no report file is provided. |

**Tags:** `python`, `testing`, `coverage`, `qa`, `remediation`

**Added in:** v0.1.0

**Definition file:** `skills/python-test-remediator/skill.md`

---

## qa-coach

**Description:** Analyzes source code, pull requests, or module designs for testability anti-patterns, explains WHY each pattern makes testing harder, and proposes concrete refactoring paths — bridging the gap between developer decisions and QA consequences.

**Invocation:** `tw-qa-coach`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | True |  | Path to file, directory, or 'git-diff' to analyze the current staged/unstaged changes. |
| `mode` | string | False | analyze | 'analyze' to report testability issues and refactoring suggestions. 'pr-review' to produce a QA-focused PR review comment. 'score' to output a numeric testability score (0–100) per module. |
| `stack` | string | False |  | Tech stack context: 'spring', 'nestjs', 'express', 'django', 'fastapi'. Auto-detected from imports. |

**Tags:** `testability`, `refactoring`, `code-review`, `design`, `coaching`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/qa-coach/skill.md`

---

## quality-trend

**Description:** Reads historical governance reports, mutation scores, flakiness analyses, and E2E coverage reports to generate a quality trend dashboard showing whether the test suite is improving or degrading over time.

**Invocation:** `tw-quality-trend`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `since` | string | False | 30d | Time window for analysis: '7d', '30d', '90d', or a git ref (e.g. 'v1.0.0'). Default: 30d. |
| `metrics` | string | False | all | Comma-separated metrics to include: coverage, mutation, e2e, flakiness, contracts, performance. Default: all. |
| `output` | string | False | report | 'report' to generate markdown dashboard, 'csv' to export raw data for external tools (Grafana, DataDog). |

**Tags:** `metrics`, `trend`, `dashboard`, `governance`, `qa`, `reporting`

**Added in:** v0.4.0

**Definition file:** `skills/quality-trend/skill.md`

---

## security-audit

**Description:** Runs a multi-layer security audit combining static analysis (OWASP Top 10 code patterns), dependency vulnerability scanning (npm audit, pip-audit, OWASP Dependency Check), and optional DAST with OWASP ZAP. Stack-agnostic and CI-ready.

**Invocation:** `tw-security-audit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `mode` | string | False | scan | 'scan' for static + dependency analysis (no running app needed), 'dast' for dynamic scan against a running instance, 'full' for both. |
| `target` | string | False |  | For 'dast' mode: base URL of the running application (e.g. http://localhost:3000). Required only for dast/full. |
| `stack` | string | False |  | Tech stack: 'typescript', 'python', 'java', 'dotnet', 'go', 'ruby'. Auto-detected. |
| `owasp_categories` | string | False | all | Comma-separated OWASP Top 10 categories to focus on (e.g. 'A01,A02,A03'). Default: all. |
| `severity_threshold` | string | False | medium | Minimum severity to report: 'critical', 'high', 'medium', 'low'. Default: medium. |

**Tags:** `security`, `owasp`, `vulnerability`, `dependency-scan`, `dast`, `sast`, `compliance`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/security-audit/skill.md`

---

## stack-health-check

**Description:** Comprehensive Day 1 assessment of any existing project — detects tech stack, measures current test coverage, evaluates CI health, checks dependency freshness, identifies security debt, and produces an executive summary plus technical detail report. The consultant's first deliverable.

**Invocation:** `tw-stack-health-check`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `depth` | string | False | standard | 'quick' for a 5-minute snapshot (stack + coverage + CI status), 'standard' for full assessment (default), 'deep' for standard + security + dependency analysis. |
| `output` | string | False | report | 'report' for full technical report, 'executive' for a management-facing summary (2 pages max), 'both'. |

**Tags:** `consulting`, `assessment`, `onboarding`, `discovery`, `health-check`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/stack-health-check/skill.md`

---

## sync-context

**Description:** Regenerates the toolkit registry and context snapshots from current component files.

**Invocation:** `tw-sync-context`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `force` | boolean | False | false | Force regeneration even if no component files appear to have changed |

**Tags:** `context`, `maintenance`, `registry`

**Added in:** v0.1.0

**Definition file:** `skills/sync-context/skill.md`

---

## test-factory

**Description:** Generates test data factory classes from domain models (TypeORM entities, SQLAlchemy models, JPA entities) with cleanup strategies, ensuring E2E and integration tests are isolated, deterministic, and leave no pollution between runs.

**Invocation:** `tw-test-factory`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | string | True |  | Path to entity/model file or directory (e.g. 'src/entities/' or 'src/orders/order.entity.ts'). |
| `framework` | string | False |  | Factory framework: 'fishery' (TypeScript), 'factory-boy' (Python), 'instancio' (Java). Auto-detected. |
| `cleanup` | string | False | afterEach | Cleanup strategy: 'afterEach' (delete after each test), 'transaction' (rollback after each test), 'truncate' (truncate tables in afterAll). |
| `output_dir` | string | False |  | Output directory for factory files. Defaults to 'src/test/factories/' or 'tests/factories/'. |

**Tags:** `test-data`, `factories`, `fishery`, `factory-boy`, `instancio`, `test-isolation`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/test-factory/skill.md`

---

## test-strategy-generator

**Description:** Analyzes a project's stack, team size, risk profile, and delivery model to generate a tailored QA Strategy document — the first deliverable a consultant produces for any new client. Covers test pyramid, tooling recommendations, coverage targets, CI gates, and a phased implementation roadmap.

**Invocation:** `tw-test-strategy-generator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_name` | string | False |  | Project or product name. Used as the document title. Defaults to repo name. |
| `team_size` | string | False |  | Approximate team size: 'small' (1-5), 'medium' (6-15), 'large' (16+). Affects tooling and process recommendations. |
| `delivery_model` | string | False |  | Delivery model: 'agile', 'kanban', 'scaled-agile', 'waterfall'. Affects sprint cadence and gate definitions. |
| `risk_profile` | string | False | medium | Application risk profile: 'critical' (financial, healthcare, safety), 'high' (customer-facing, data-intensive), 'medium' (internal tooling), 'low' (prototypes, MVPs). |
| `regulatory` | string | False |  | Applicable regulations: 'gdpr', 'hipaa', 'pci-dss', 'sox', 'none'. Adds compliance layer to strategy. |
| `output_format` | string | False | markdown | 'markdown' for a .md document, 'confluence' for Confluence-ready wiki markup. |

**Tags:** `strategy`, `consulting`, `onboarding`, `qa-planning`, `test-pyramid`, `documentation`, `qa`

**Added in:** v0.5.0

**Definition file:** `skills/test-strategy-generator/skill.md`

---

## ts-architecture-analyzer

**Description:** Analyzes TypeScript/NestJS code with adaptive depth, auto-detects granularity level (L1-L4), identifies architectural risks, silent traps, and scalability issues, and produces a technical health scorecard with Gherkin feature file.

**Invocation:** `tw-ts-architecture-analyzer`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `artifact` | string | False |  | Path or pasted code to analyze. If omitted, Claude analyzes the full repo at L1. |

**Tags:** `typescript`, `nestjs`, `architecture`, `code-review`, `qa`

**Added in:** v0.1.0

**Definition file:** `skills/ts-architecture-analyzer/skill.md`

---

## ts-test-governor

**Description:** Audits Jest unit test coverage in a TypeScript/NestJS repository, maps production modules to spec files, classifies gaps by severity, and generates a structured governance report with actionable remediation decisions.

**Invocation:** `tw-ts-test-governor`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `base_ref` | string | False |  | Git ref to diff against (e.g. origin/master). When provided, the report focuses on changed modules. |
| `coverage_summary` | string | False |  | Path to coverage/coverage-summary.json generated by jest --coverage. Enables per-module coverage signals. |
| `test_results_dir` | string | False |  | Directory containing Jest JUnit XML output for failing test detection. |

**Tags:** `typescript`, `nestjs`, `jest`, `testing`, `coverage`, `qa`, `governance`

**Added in:** v0.1.0

**Definition file:** `skills/ts-test-governor/skill.md`

---

## ts-test-remediator

**Description:** Consumes a TypeScript/NestJS test governance report, assigns Istanbul coverage tiers per module, then generates or updates maintainable Jest spec files to meet tiered line-coverage targets.

**Invocation:** `tw-ts-test-remediator`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `report_file` | string | False |  | Path to the governance report produced by /tw-ts-test-governor. If omitted, Claude looks for the most recent TEST_GOVERNANCE_REPORT_*.md in the project root. |
| `base_ref` | string | False |  | Git ref used by /tw-ts-test-governor (e.g. origin/master). Passed to the inventory script to regenerate the report when no report file is provided. |

**Tags:** `typescript`, `nestjs`, `jest`, `testing`, `coverage`, `qa`, `remediation`

**Added in:** v0.1.0

**Definition file:** `skills/ts-test-remediator/skill.md`

---

## visual-baseline

**Description:** Captures visual snapshots of application pages (Golden Master for UI) and compares them pixel-by-pixel to detect unintended visual regressions — CSS changes, layout shifts, or component rendering issues — invisible to functional tests.

**Invocation:** `tw-visual-baseline`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `mode` | string | True |  | 'capture' to record visual baseline screenshots, 'compare' to diff current screenshots against baseline. |
| `pages` | string | False |  | Comma-separated page paths to capture (e.g. '/login,/dashboard,/orders'). Auto-detected from E2E tests if omitted. |
| `framework` | string | False |  | E2E framework: 'playwright' or 'cypress'. Auto-detected. |
| `threshold` | number | False | 0.1 | Maximum acceptable pixel difference (%). Default: 0.1% — stricter than most defaults. |
| `viewports` | string | False | desktop | Viewport profiles: 'desktop' (1280x720), 'mobile' (375x667), 'tablet' (768x1024), or 'all'. |

**Tags:** `visual-regression`, `screenshot`, `playwright`, `cypress`, `golden-master`, `qa`

**Added in:** v0.4.0

**Definition file:** `skills/visual-baseline/skill.md`

---

