# tw-ai-toolkit — Quickstart

Guide to install, configure, and use the toolkit in any development repository.

---

## What is tw-ai-toolkit?

A centralized collection of skills, agents, rules, and MCP servers that extend the capabilities
of your AI assistant (Claude Code, Cursor) inside your projects. The toolkit lives in its own
repository and is installed locally in each repo where you want to use it — without becoming
part of your source code.

Built with a **QA / SDET-first perspective**: the toolkit amplifies the quality engineer's
view that developers often miss — surfacing blind spots, enforcing spec-first thinking, and
automating the full quality loop from spec generation to coverage to contract testing.

---

## Prerequisites

- Git installed
- Claude Code (recommended) or Cursor
- Access to the toolkit repository (`https://github.com/tweladera/tw-ai-toolkit`)

---

## Installation

### Option A — Local install (recommended — nothing pushed to remote)

```bash
# Step 1 — clone the toolkit once anywhere on your machine
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit
```
```bash
# Step 2 — run from your project root
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
```
```bash
# Step 3 — Link skills 
python3 .ai/toolkit/scripts/install.py --link-all
```
```bash
# Step 4 — Verify the installation
python3 .ai/toolkit/scripts/install.py --verify
```
```bash
# Step 5 — Update when a new version is released
cd ~/tw-ai-toolkit && git pull origin main
cd /path/to/your-repo && python3 .ai/toolkit/scripts/install.py --link-all
```
### Option B — Git submodule (when the team wants the toolkit pinned in the repo)

> Note: this commits a `.gitmodules` reference to your remote repo.
> Only use this if the whole team should share the same toolkit version via the repo.

```bash
git submodule add https://github.com/tweladera/tw-ai-toolkit.git .ai/toolkit
```
```bash
python3 .ai/toolkit/scripts/install.py
```
```bash
python3 .ai/toolkit/scripts/install.py --link-all
```
```bash
python3 .ai/toolkit/scripts/install.py --verify
```
```bash
python3 .ai/toolkit/scripts/install.py --update
```
### What the installer does

1. Creates `.ai/AGENTS.md` — toolkit context loaded by Claude Code on every session
2. Creates `.ai/config.json` with the local configuration
3. Creates `CLAUDE.md` at the root with context-loading instructions for Claude Code
4. Creates symlinks in `.claude/skills/` and `.cursor/skills/` for all toolkit skills
5. Adds `.ai/toolkit/`, `.claude/skills/`, `.cursor/skills/` to `.gitignore` — **never committed, never pushed**

---

## Verify the installation

After installing, open Claude Code in that repo and type:

```
What toolkit components are available?
```

Claude Code will automatically read `CLAUDE.md` and load the toolkit context.

---

## Available Components (v0.5.0)

### Skills — Atomic tools (invocation: `/tw-<name>`)

Skills are single-purpose actions you ask the AI to execute.

#### Consulting & Assessment Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **stack-health-check** | `/tw-stack-health-check` | Day 1 technical assessment. Auto-detects stack, CI, cloud, coverage, dependency CVEs, and debt signals. Produces an executive summary (≤2 pages) + full technical report | First thing on any new engagement — before touching any code |
| **test-strategy-generator** | `/tw-test-strategy-generator` | Generates a complete QA Strategy document: test pyramid with ratios, tooling per layer, CI gate definitions, 4-phase implementation roadmap, RACI | First deliverable for any client — defines the quality plan before work starts |
| **living-docs** | `/tw-living-docs` | Reads `.feature` files + CI test results (JUnit XML / Playwright JSON) and produces pass/fail/pending living documentation in Markdown, HTML, or Confluence wiki markup | After each main branch build to keep docs in sync with passing behavior |

#### Spec-First & Behavioral Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **exec-spec-generator** | `/tw-exec-spec-generator` | Generates executable Gherkin specs from user stories. Applies 6 QA lenses and produces a Blind Spots Report with scenarios the developer didn't think of | Before writing any implementation code for a new feature |
| **golden-master** | `/tw-golden-master` | Captures behavioral snapshots (`mode=capture`) and compares future runs against them (`mode=compare`) to detect regressions or prove equivalence | Before/after any refactor or legacy migration |

#### Unit Test Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **ts-architecture-analyzer** | `/tw-ts-architecture-analyzer` | Deep architectural analysis of TypeScript/NestJS code. Produces risk analysis, technical health scorecard, and Gherkin feature file from identified risks | Before a code review, PR merge, or architecture decision |
| **ts-test-governor** | `/tw-ts-test-governor` | Audits Jest unit test coverage, maps modules to spec files, classifies gaps by severity, produces a governance report | Before a release or sprint review in a TS/NestJS repo |
| **ts-test-remediator** | `/tw-ts-test-remediator` | Generates or repairs Jest spec files from a governance report | After running `/tw-ts-test-governor` |
| **python-test-governor** | `/tw-python-test-governor` | Audits pytest/unittest coverage, maps modules to tests, classifies gaps by severity, produces a governance report | Before a release or sprint review in a Python repo |
| **python-test-remediator** | `/tw-python-test-remediator` | Generates or repairs pytest/unittest tests from a governance report | After running `/tw-python-test-governor` |
| **java-test-governor** | `/tw-java-test-governor` | Audits JUnit 5 coverage for Spring Boot via Jacoco. Maps Spring stereotypes to tests, classifies gaps by severity | Before a release in a Java/Spring Boot repo |
| **java-test-remediator** | `/tw-java-test-remediator` | Generates JUnit 5 test files following Spring patterns: @Service+Mockito, @RestController+MockMvc, @DataJpaTest | After running `/tw-java-test-governor` |
| **mutation-audit** | `/tw-mutation-audit` | Runs Stryker (TypeScript) or mutmut (Python) to prove tests actually catch bugs. Classifies surviving mutants by risk | After reaching coverage targets — verify test quality, not just quantity |
| **qa-coach** | `/tw-qa-coach` | Analyzes code or PRs for testability anti-patterns (hidden deps, god classes, non-determinism). Computes testability score 0–100 | When governance flags a module as hard to test, or during PR review |

#### E2E Test Skills — Cypress & Playwright

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **e2e-page-object** | `/tw-e2e-page-object` | Generates Page Object Model (POM) classes from component files or HTML. Enforces data-testid selector hierarchy | Before writing E2E tests for a new page or after a UI refactor broke POMs |
| **e2e-spec-to-test** | `/tw-e2e-spec-to-test` | Converts a Gherkin `.feature` file into Cypress or Playwright test files using the POM pattern. Auto-detects framework | After `/tw-exec-spec-generator` — close the spec-first loop with runnable tests |
| **e2e-test-governor** | `/tw-e2e-test-governor` | Audits E2E coverage by user flow, detects stale tests (routes/selectors no longer exist), flags brittle selectors | Before a release or to assess E2E test health |
| **visual-baseline** | `/tw-visual-baseline` | Captures screenshots (`mode=capture`) and compares pixel-by-pixel (`mode=compare`). Detects CSS shifts, layout changes, and component regressions invisible to functional tests | Before/after a CSS refactor, design system update, or component change |
| **a11y-audit** | `/tw-a11y-audit` | Injects axe-core into existing E2E tests (`mode=inject`) or runs a standalone WCAG 2.1 AA audit (`mode=standalone`). Classifies violations by impact: critical → block release | Before a release with accessibility compliance requirements |

#### Integration, Contract & Resilience Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **integration-discovery** | `/tw-integration-discovery` | Scans OpenAPI/AsyncAPI specs or controller annotations, generates framework-agnostic Gherkin + integration tests (supertest/REST Assured/httpx) automatically | When a new API exists without integration tests, or after spec changes |
| **contract-coverage** | `/tw-contract-coverage` | Scans for HTTP clients, Kafka producers/consumers; maps consumer-provider relationships; detects missing Pact/CDC contract tests; generates stubs | After unit coverage is good — next layer is integration contracts |
| **test-factory** | `/tw-test-factory` | Generates test data factory classes (Fishery/factory-boy/Instancio) from entity files. Solves test pollution and coupling to production data with 3 cleanup strategies | Before writing integration or E2E tests that need real DB objects |
| **chaos-testing** | `/tw-chaos-testing` | Generates resilience tests for circuit breakers, retries, timeouts, and graceful degradation. Auto-detects Spring/Resilience4j, NestJS/nock, or FastAPI/unittest.mock | Before any service goes to production — verify it degrades gracefully under failure |

#### Performance & CI Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **performance-baseline** | `/tw-performance-baseline` | Generates k6 (TypeScript) or Locust (Python) scripts. Establishes P95 baselines (`mode=baseline`) and compares against them (`mode=compare`) to detect latency regressions | Before a release or after a DB migration / ORM change |
| **pipeline-generator** | `/tw-pipeline-generator` | Generates GitHub Actions or GitLab CI YAML with quality gates: lint → unit → coverage → E2E → contracts. Optional nightly schedule for mutation testing | When setting up CI for a new project or adding quality gates to existing pipelines |
| **flakiness-analyzer** | `/tw-flakiness-analyzer` | Parses CI test results across ≥5 runs to identify flaky tests and classify root causes (timing, environment, data ordering, shared state, external service) | When tests pass locally but fail intermittently in CI |
| **quality-trend** | `/tw-quality-trend` | Reads all historical governance reports and generates a trend dashboard with direction indicators (↑ ↓ →) and a composite quality score. CSV export for Grafana/DataDog | Monthly quality review, quarterly reports, after a quality-sprint initiative |

#### Security & Compliance Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **security-audit** | `/tw-security-audit` | Three-layer scan: SAST (OWASP Top 10 code patterns), SCA (dependency CVEs via npm audit/pip-audit/OWASP DC), optional DAST (OWASP ZAP). Produces executive summary + specific findings with file:line | Before any release, or when adding auth/payments/PII handling |
| **compliance-audit** | `/tw-compliance-audit` | Scans for GDPR/HIPAA/PCI-DSS/SOX/ISO 27001 gaps. Maps findings to regulatory articles. Produces gap report + test checklist + CSV export for GRC tools | When working with regulated industries: healthcare, finance, public sector |

#### Toolkit Maintenance Skills

| Skill | Invocation | What it does | When to use |
|---|---|---|---|
| **sync-context** | `/tw-sync-context` | Regenerates the registry and context snapshots | After modifying or adding components to the toolkit |
| **lint-component** | `/tw-lint-component` | Validates a component against schema and conventions | Before committing a new or modified component |
| **install-toolkit** | `/tw-install-toolkit` | AI-guided toolkit installation in a consumer repo | When you want to install the toolkit without leaving Claude Code |

---

### Agents — Autonomous orchestrators (invocation: `/tw-<name>`)

Agents execute multi-step flows autonomously.

| Agent | Invocation | What it does | When to use |
|---|---|---|---|
| **client-bootstrap** | `/tw-client-bootstrap` | Full Day 1 consultant workflow: health check → QA strategy → governance → security audit → CI pipeline. Produces an Engagement Starter Kit document | First hour on any new client engagement |
| **release-readiness** | `/tw-release-readiness` | Reads all existing report files and produces a GO/NO-GO decision with an evidence matrix across 8 quality gates: coverage, mutation, flakiness, performance, a11y, security, visual, contracts | Before any production deployment |
| **quality-sprint** | `/tw-quality-sprint` | Bounded autonomous loop: runs the test governor, evaluates the decision, runs the remediator, verifies, and iterates. Mandatory human checkpoint at iteration 2 | When you want to improve coverage automatically without running each step manually |
| **onboard-repo** | `/tw-onboard-repo` | Analyzes your repo and configures the toolkit for your stack | When installing the toolkit in a project for the first time |
| **scaffold-component** | `/tw-scaffold-component` | Creates a new toolkit component from the appropriate template | When adding a new skill, agent, rule, or prompt to the toolkit |

**Usage examples:**

```
/tw-client-bootstrap                                     # Day 1: full engagement setup
/tw-release-readiness                                    # GO/NO-GO before deploying
/tw-quality-sprint stack=typescript base_ref=origin/main
/tw-onboard-repo
/tw-scaffold-component type=skill name=my-new-skill
```

---

### Rules — AI behavioral rules

Rules are loaded automatically via `CLAUDE.md` and define how the AI behaves in repos
that use the toolkit. They are not invoked manually.

| Rule | Target | What it does |
|---|---|---|
| **claude-base** | Claude Code | Defines how to load toolkit context, which files not to edit manually, and how to invoke components |
| **cursor-base** | Cursor | Equivalent to claude-base adapted for the Cursor workflow |
| **spec-first** | All | QA mindset: offers spec generation before implementation, surfaces blind spots proactively, fixes source not output |
| **security-first** | All | Surfaces OWASP implications before implementing any auth, PII, payment, or query code. Flags insecure patterns inline with exact fixes |
| **performance-budget** | All | Flags N+1 queries, unbounded queries, and sync external calls in request paths before implementation, with stack-specific examples |
| **consultant-mindset** | All | Assess before assuming; generate artifacts not just answers; communicate impact in business terms (risk, not metrics); adapt to client maturity |

To activate rules, add the rule fragment to your `CLAUDE.md`:
```
See .ai/toolkit/rules/<rule-name>/rule.md for the fragment to paste
```

**Recommended combination for new engagements:**
```
consultant-mindset + spec-first + security-first
```

---

### MCP Servers — Enterprise integrations

MCP servers expose external tools directly to the AI. Configured once in Claude Code and
available in every session.

| Server | What it does | When to configure |
|---|---|---|
| **tw-github** | Lets the AI read PRs, issues, commits, and repos from GitHub directly | When you work with GitHub and want the AI to have PR/issue context without copy-pasting |
| **tw-gitlab** | Lets the AI read/create MRs, get pipeline status, trigger jobs, and query issues from GitLab | When you work with GitLab (cloud or self-hosted) |
| **tw-sonarqube** | Lets the AI read quality gate status, issues, hotspots, and coverage metrics from SonarQube or SonarCloud | When the client uses SonarQube/SonarCloud as quality gate |
| **tw-azure-devops** | Lets the AI query Boards (work items, WIQL), Pipelines (runs, logs, trigger), Repos (PRs, files), and Test Plans | When the client is on the Microsoft stack (Azure DevOps) |
| **tw-confluence** | Lets the AI get, search, create, and update Confluence pages and publish living docs automatically | When the client uses Confluence and you want living docs published after each CI run |
| **tw-jira** | Lets the AI query and update Jira tickets | When your team uses Jira and you want the AI to link code to tickets automatically |

To configure an MCP server, read its guide at:
```
.ai/toolkit/mcp/tw-github/server.md
.ai/toolkit/mcp/tw-gitlab/server.md
.ai/toolkit/mcp/tw-sonarqube/server.md
.ai/toolkit/mcp/tw-azure-devops/server.md
.ai/toolkit/mcp/tw-confluence/server.md
.ai/toolkit/mcp/tw-jira/server.md
```

---

## Recommended QA Workflow

```
Step 0 — Day 1: understand before touching anything
  /tw-client-bootstrap                              # Full engagement setup (health + strategy + CI)
  — or individually:
  /tw-stack-health-check                            # Technical health report (executive + engineering)
  /tw-test-strategy-generator                       # QA Strategy document for the engagement

Step 1 — Define behavior before implementation
  /tw-exec-spec-generator story="As a buyer I want to place an order..."
  → Gherkin feature file + Blind Spots Report

Step 2 — Capture behavioral baseline (before any refactor)
  /tw-golden-master mode=capture name=order-service target="..." inputs=tests/inputs.json

Step 3 — Implement (code follows the spec)
  [write implementation until all scenarios in the .feature file pass]

Step 4 — Audit and fix unit coverage
  /tw-ts-test-governor                              # TypeScript
  /tw-python-test-governor                          # Python
  /tw-java-test-governor                            # Java/Spring Boot
  /tw-quality-sprint                                # Autonomous fix loop
  /tw-mutation-audit                                # Prove tests catch bugs

Step 5 — Check testability before writing more tests
  /tw-qa-coach source=src/orders/order.service.ts  # Detect anti-patterns
  /tw-test-factory source=src/entities/            # Generate test data factories

Step 6 — Integration layer
  /tw-integration-discovery source=openapi/api.yaml   # Auto-generate Gherkin + tests
  /tw-contract-coverage mode=generate                  # Pact stubs for missing contracts
  /tw-chaos-testing                                    # Resilience: circuit breakers, retries, timeouts

Step 7 — Build E2E test layer (Cypress or Playwright)
  /tw-e2e-page-object source=src/orders/OrderForm.tsx
  /tw-e2e-spec-to-test feature=specs/order-placement.feature
  /tw-e2e-test-governor
  /tw-visual-baseline mode=capture                  # Visual regression baseline
  /tw-a11y-audit mode=inject                        # Accessibility checks (zero cost)

Step 8 — Security & compliance
  /tw-security-audit                                # OWASP SAST + CVE scan
  /tw-compliance-audit framework=GDPR               # Regulatory gap report (if applicable)

Step 9 — Performance and quality gates
  /tw-performance-baseline mode=baseline            # Establish P95 baseline
  /tw-pipeline-generator                            # Generate CI with quality gates

Step 10 — Verify and release
  /tw-golden-master mode=compare name=order-service
  /tw-release-readiness                             # GO/NO-GO across all 8 gates
  /tw-living-docs output=markdown                   # Publish verified behavior
  /tw-quality-trend since=30d                       # Dashboard: is quality improving?
```

---

## Typical daily workflow

```
1. Open Claude Code in your repo
2. Claude Code loads CLAUDE.md automatically
3. Work on your code normally
4. Use /tw-<skill> when you need a specific toolkit action
5. git add / commit / push — only your code, the toolkit never appears
```

---

## Update the toolkit

```bash
cd .ai/toolkit && git pull origin main
```

---

## Uninstall / clean up

```bash
rm -rf .ai/
rm -f CLAUDE.md
rm -f .env.toolkit.example
```

These files were in `.git/info/exclude`, so git never tracked them — nothing to revert in history.

---

## Reinstall from scratch

After cleaning up, run the installer again:

```bash
bash /path/to/tw-ai-toolkit/scripts/install.sh --local-only
```

---

## File structure after installation

```
your-repo/
├── .ai/
│   ├── toolkit/          # cloned toolkit (gitignored)
│   │   ├── AGENTS.md
│   │   ├── registry.json
│   │   ├── skills/
│   │   ├── agents/
│   │   ├── rules/
│   │   └── mcp/
│   ├── AGENTS.md         # local pointer to the toolkit
│   └── config.json       # local configuration
├── CLAUDE.md             # context-loading instructions for Claude Code (gitignored)
└── your-code/
```

---

## Quick reference

| Goal | Command |
|---|---|
| Install the toolkit | `python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit` |
| List available components | Ask the AI: "What toolkit components are available?" |
| **Day 1 engagement setup** | `/tw-client-bootstrap` |
| Day 1 health report only | `/tw-stack-health-check` |
| Generate QA Strategy document | `/tw-test-strategy-generator project_name=<name>` |
| Generate specs from a user story | `/tw-exec-spec-generator story="..."` |
| Capture behavioral baseline | `/tw-golden-master mode=capture name=<id> target="..."` |
| Compare after refactor | `/tw-golden-master mode=compare name=<id>` |
| Audit TS test coverage | `/tw-ts-test-governor` |
| Audit Python test coverage | `/tw-python-test-governor` |
| Audit Java/Spring Boot coverage | `/tw-java-test-governor` |
| Auto-fix coverage gaps | `/tw-quality-sprint` |
| Prove tests catch bugs | `/tw-mutation-audit` |
| Detect testability anti-patterns | `/tw-qa-coach source=<path>` |
| Generate integration tests from spec | `/tw-integration-discovery source=openapi/api.yaml` |
| Detect missing contract tests | `/tw-contract-coverage` |
| Generate test data factories | `/tw-test-factory source=src/entities/` |
| Test resilience (circuit breaker / retry / timeout) | `/tw-chaos-testing` |
| Generate POM from a component | `/tw-e2e-page-object source=<path>` |
| Convert feature file to E2E tests | `/tw-e2e-spec-to-test feature=<path>` |
| Audit E2E coverage and selector health | `/tw-e2e-test-governor` |
| Capture visual baseline | `/tw-visual-baseline mode=capture` |
| Run accessibility audit | `/tw-a11y-audit mode=inject` |
| OWASP security scan + CVE report | `/tw-security-audit` |
| Regulatory compliance gap report | `/tw-compliance-audit framework=GDPR` |
| Establish performance baseline | `/tw-performance-baseline mode=baseline` |
| Generate CI pipeline with quality gates | `/tw-pipeline-generator` |
| Identify flaky tests from CI results | `/tw-flakiness-analyzer source=junit-xml` |
| **GO/NO-GO release decision** | `/tw-release-readiness` |
| Publish living documentation | `/tw-living-docs output=markdown` |
| Generate quality trend dashboard | `/tw-quality-trend since=30d` |
| Onboard a new repo | `/tw-onboard-repo` in Claude Code |
| Sync context | `/tw-sync-context` in Claude Code |
| Validate a component | `/tw-lint-component <path>` in Claude Code |
| Update the toolkit | `cd ~/tw-ai-toolkit && git pull origin main && python3 .ai/toolkit/scripts/install.py --link-all` |
| Uninstall | `rm -rf .ai/ CLAUDE.md .env.toolkit.example` |
