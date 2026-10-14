---
name: test-strategy-generator
description: Analyzes a project's stack, team size, risk profile, and delivery model to generate a tailored QA Strategy document — the first deliverable a consultant produces for any new client. Covers test pyramid, tooling recommendations, coverage targets, CI gates, and a phased implementation roadmap.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: project_name
    type: string
    required: false
    default: ""
    description: "Project or product name. Used as the document title. Defaults to repo name."
  - name: team_size
    type: string
    required: false
    default: ""
    description: "Approximate team size: 'small' (1-5), 'medium' (6-15), 'large' (16+). Affects tooling and process recommendations."
  - name: delivery_model
    type: string
    required: false
    default: ""
    description: "Delivery model: 'agile', 'kanban', 'scaled-agile', 'waterfall'. Affects sprint cadence and gate definitions."
  - name: risk_profile
    type: string
    required: false
    default: "medium"
    description: "Application risk profile: 'critical' (financial, healthcare, safety), 'high' (customer-facing, data-intensive), 'medium' (internal tooling), 'low' (prototypes, MVPs)."
  - name: regulatory
    type: string
    required: false
    default: ""
    description: "Applicable regulations: 'gdpr', 'hipaa', 'pci-dss', 'sox', 'none'. Adds compliance layer to strategy."
  - name: output_format
    type: string
    required: false
    default: "markdown"
    description: "'markdown' for a .md document, 'confluence' for Confluence-ready wiki markup."
tags:
  - strategy
  - consulting
  - onboarding
  - qa-planning
  - test-pyramid
  - documentation
  - qa
invocation: tw-test-strategy-generator
---

# test-strategy-generator

## Description

The first thing a QA consultant delivers to a new client is a **QA Strategy document**.
Without it, testing is reactive — tests get written when someone has time, for whatever
seems important at the moment, with no shared understanding of what "done" means for quality.

This skill generates a complete, client-specific QA Strategy from project analysis alone.
It reads the existing codebase to understand what tools are in use, what's already tested,
what's missing, and the scale of the project — then produces a document that:

1. Defines the test pyramid for this specific stack and risk profile
2. Recommends concrete tooling (not generic — specific to what the project already uses or can adopt)
3. Sets measurable coverage targets per layer
4. Defines CI/CD quality gates
5. Proposes a phased implementation roadmap that fits the team's capacity

**For the consultant:** This is the document that establishes credibility on day 3 and
sets the quality conversation with client stakeholders. It replaces 2 weeks of analysis
with an AI-assisted first draft ready for team review.

## When to Use

- First week on a new engagement — before any test code is written
- When a client asks "what should our testing strategy be?"
- When a project has grown organically and testing is inconsistent
- When proposing a quality improvement initiative to management

Triggers: "create a test strategy", "QA strategy document", "testing plan",
"what should we test", "quality improvement plan", "test pyramid for our project".

## Instructions

### Step 1 — Project Analysis

```bash
# Auto-detect stack
echo "=== LANGUAGES ==="
ls *.json *.toml *.gradle *.xml *.mod *.gemspec 2>/dev/null
rg "\"main\"|main\.ts|app\.py|Application\.java|main\.go|Program\.cs" \
  --max-depth 3 -l 2>/dev/null | head -5

echo "=== FRAMEWORKS ==="
cat package.json 2>/dev/null | python3 -c "
import sys,json; d=json.load(sys.stdin)
deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
for k in ['nestjs','express','react','vue','angular','next','nuxt','fastify']:
    if any(k in dep for dep in deps):
        print(f'Found: {k}')
" 2>/dev/null

echo "=== EXISTING TESTS ==="
find . -name "*.spec.ts" -o -name "*.test.ts" -o -name "test_*.py" \
       -o -name "*Test.java" -o -name "*_test.go" 2>/dev/null | wc -l
echo "test files found"

echo "=== CI PLATFORM ==="
ls .github/workflows/ .gitlab-ci.yml azure-pipelines.yml Jenkinsfile \
   .circleci/config.yml bitbucket-pipelines.yml 2>/dev/null

echo "=== ARCHITECTURE ==="
ls docker-compose.yml docker-compose*.yml kubernetes/ k8s/ 2>/dev/null
rg "FROM " Dockerfile 2>/dev/null | head -3
```

Classify project type:
- **Monolith**: single application, one database
- **Microservices**: multiple services, message queues
- **Serverless**: functions, event-driven
- **Frontend-heavy**: SPA with API backend
- **API-only**: headless service, no UI layer

### Step 2 — Current State Assessment

```bash
# Test coverage (if available)
cat coverage/coverage-summary.json 2>/dev/null | \
  python3 -c "import sys,json; d=json.load(sys.stdin); t=d.get('total',{}); \
  print(f'Lines: {t.get(\"lines\",{}).get(\"pct\",0)}%, Branches: {t.get(\"branches\",{}).get(\"pct\",0)}%')"

# Existing test frameworks
rg "jest|vitest|mocha|jasmine" package.json 2>/dev/null
rg "pytest|unittest|nose" requirements.txt setup.py pyproject.toml 2>/dev/null
rg "junit|testng|mockito" pom.xml build.gradle 2>/dev/null

# E2E setup
ls cypress.config.* playwright.config.* 2>/dev/null

# CI pipeline exists?
ls .github/workflows/*.yml .gitlab-ci.yml azure-pipelines.yml 2>/dev/null
```

### Step 3 — Generate QA Strategy Document

```markdown
# QA Strategy — {{project_name}}

**Version:** 1.0
**Date:** YYYY-MM-DD
**Author:** QA Engineering (generated by /tw-test-strategy-generator)
**Status:** Draft — for team review

---

## 1. Context and Scope

**Project:** {{project_name}}
**Stack:** [auto-detected: TypeScript / NestJS / PostgreSQL / React]
**Architecture:** [Microservices — 4 services detected]
**Team:** [Medium — 6-15 engineers]
**Delivery:** [Agile — 2-week sprints]
**Risk Profile:** HIGH — customer-facing financial application
**Regulatory:** GDPR (EU data), PCI-DSS (payment processing)

**Scope of this strategy:**
- Backend services: orders-service, payments-service, users-service, notifications-service
- Frontend: orders-dashboard (React SPA)
- Infrastructure: AWS ECS + RDS PostgreSQL + SQS

---

## 2. Test Pyramid

For this stack and risk profile, the recommended pyramid is:

```
            ┌─────────────────┐
            │   E2E Tests     │  5-10% — critical user journeys only
            │  (Playwright)   │  ~15 tests
            ├─────────────────┤
            │  Integration    │  20-30% — API contracts + data flows
            │  (Supertest)    │  ~80 tests
            ├─────────────────┤
            │   Unit Tests    │  60-70% — business logic, algorithms
            │  (Jest/JUnit)   │  ~400 tests
            └─────────────────┘
```

**Rationale for this ratio:**
- Unit tests are fast (< 10ms each), deterministic, and catch regressions immediately
- Integration tests verify service boundaries — critical for microservices
- E2E tests are expensive to maintain; limit to the 10-15 most critical user journeys

**Anti-pattern to avoid:** Inverted pyramid (many E2E, few unit tests) — common in
legacy projects, results in slow, flaky CI and long feedback cycles.

---

## 3. Test Layers — Tooling and Targets

### 3.1 Unit Tests

| Attribute | Recommendation |
|---|---|
| Framework | Jest (TypeScript), JUnit 5 (Java) |
| Mocking | jest.mock() / Mockito |
| Coverage tool | Istanbul / Jacoco |
| **Coverage target** | **Tier A (business logic): 80% line coverage** |
| | **Tier B (controllers): 60% line coverage** |
| | **Tier C (config/infra): 40% line coverage** |
| Run frequency | On every PR (< 2 min total) |

**Modules classified as Tier A** (must reach 80%):
- OrderService, PaymentService, UserService
- Domain entities and value objects
- Business rule validators

**Skill:** `/tw-ts-test-governor` → `/tw-ts-test-remediator` (TS), `/tw-java-test-governor` (Java)

### 3.2 Integration Tests

| Attribute | Recommendation |
|---|---|
| Framework | Supertest + @nestjs/testing (TS), REST Assured (Java) |
| Test data | Fishery factories + transaction rollback cleanup |
| Scope | API contracts: all HTTP methods × happy + error + auth paths |
| **Coverage target** | **100% of documented API endpoints** |
| Run frequency | On every PR (< 5 min total) |

**Autodiscovery:** `/tw-integration-discovery source=openapi/api.yaml`

### 3.3 Contract Tests

| Attribute | Recommendation |
|---|---|
| Framework | Pact (Consumer-Driven Contracts) |
| Scope | All inter-service HTTP calls and message consumers |
| Run frequency | On every PR for consumer; nightly for provider verification |

**Skill:** `/tw-contract-coverage`

### 3.4 E2E Tests

| Attribute | Recommendation |
|---|---|
| Framework | Playwright (TypeScript) |
| Pattern | Page Object Model — data-testid selectors |
| Scope | 10-15 critical user journeys (see Section 5) |
| Run frequency | On every PR (smoke: 3 tests), nightly (full suite) |
| Visual regression | Playwright toHaveScreenshot — on every E2E run |
| Accessibility | axe-core inject mode — on every E2E run (zero cost) |

**Skills:** `/tw-e2e-spec-to-test`, `/tw-e2e-test-governor`, `/tw-visual-baseline`, `/tw-a11y-audit`

### 3.5 Performance Tests

| Attribute | Recommendation |
|---|---|
| Framework | k6 (TypeScript project) |
| Scope | All tier-A endpoints |
| **Threshold** | **P95 < 500ms, error rate < 1%** |
| Run frequency | Nightly (baseline mode), on release (compare mode) |

**Skill:** `/tw-performance-baseline`

### 3.6 Security Tests

| Attribute | Recommendation |
|---|---|
| SAST | Automated scan on every PR |
| SCA | Dependency scan on every PR — block on CVSS ≥ 7.0 |
| DAST | Weekly against staging |
| Penetration test | Annually (external firm) |

**Skill:** `/tw-security-audit`, `/tw-compliance-audit framework=gdpr,pci-dss`

---

## 4. CI/CD Quality Gates

### Pull Request Gate (must pass to merge)

```
✅ Unit tests pass (100% of existing tests)
✅ Unit coverage ≥ targets per tier (no regression allowed)
✅ Integration tests pass
✅ Contract tests pass
✅ Dependency vulnerability scan (no CVSS ≥ 7.0)
✅ SAST scan (no critical/high new findings)
✅ E2E smoke tests pass (3 critical paths)
```

### Nightly Gate (blocks next-day release)

```
✅ Full E2E suite
✅ Visual baseline comparison
✅ Performance baseline comparison
✅ Mutation score ≥ 70%
✅ Full DAST scan against staging
```

### Release Gate (GO/NO-GO)

```
✅ All PR gates green
✅ All nightly gates green
✅ No CRITICAL/HIGH security findings unresolved
✅ No performance regressions > 20% P95
✅ Accessibility: no WCAG 2.1 AA critical violations
✅ Quality trend: not declining (last 7 days)
```

**Skill:** `/tw-pipeline-generator` (generates the actual CI YAML)
**Skill:** `/tw-release-readiness` (validates all gates before deployment)

---

## 5. Critical User Journeys (E2E Priority)

| Priority | Journey | Risk |
|---|---|---|
| P0 | User registration and email verification | Auth foundation |
| P0 | Login and session management | Auth foundation |
| P0 | Place an order — happy path | Core revenue flow |
| P0 | Payment processing — success | Core revenue flow |
| P1 | Order cancellation | Customer trust |
| P1 | Payment failure and retry | Revenue recovery |
| P1 | Password reset | Auth recovery |
| P2 | Order history and status | Customer experience |
| P2 | Profile update | Data management |

---

## 6. Implementation Roadmap

### Phase 1 — Foundation (Sprint 1-2)
**Goal:** Stop the bleeding. No new code without tests.

- [ ] Install toolkit: `/tw-install-toolkit`
- [ ] Run first governance report: `/tw-ts-test-governor`
- [ ] Fix Tier-A modules: `/tw-quality-sprint`
- [ ] Add CI pipeline: `/tw-pipeline-generator`
- [ ] Security baseline: `/tw-security-audit mode=scan`

**Expected coverage after Phase 1:** Tier-A 50% → 70%

### Phase 2 — Integration and E2E (Sprint 3-4)
**Goal:** Test the boundaries, not just the internals.

- [ ] Generate integration tests: `/tw-integration-discovery`
- [ ] Generate contract tests: `/tw-contract-coverage mode=generate`
- [ ] Set up E2E infrastructure: `/tw-e2e-page-object`
- [ ] Cover P0 journeys: `/tw-e2e-spec-to-test`
- [ ] Establish performance baseline: `/tw-performance-baseline mode=baseline`

**Expected coverage after Phase 2:** All API endpoints covered, P0 journeys automated

### Phase 3 — Quality Hardening (Sprint 5-6)
**Goal:** Prove the tests work, not just that they exist.

- [ ] Mutation audit: `/tw-mutation-audit`
- [ ] Flakiness cleanup: `/tw-flakiness-analyzer`
- [ ] Visual regression baseline: `/tw-visual-baseline mode=capture`
- [ ] Accessibility integration: `/tw-a11y-audit mode=inject`
- [ ] Compliance assessment: `/tw-compliance-audit`

**Expected quality after Phase 3:** Mutation score ≥ 70%, zero flaky tests, WCAG 2.1 AA compliant

### Phase 4 — Continuous Quality (ongoing)
**Goal:** Make quality visible and self-sustaining.

- [ ] Monthly quality dashboard: `/tw-quality-trend since=30d`
- [ ] Release readiness checks: `/tw-release-readiness`
- [ ] Living documentation: `/tw-living-docs`
- [ ] Quarterly strategy review (update this document)

---

## 7. Roles and Responsibilities

| Activity | Owner | Frequency |
|---|---|---|
| Run governance report | QA Lead | Every sprint |
| Review test quality | Senior Dev + QA | Every PR |
| Update baselines (visual, perf) | QA Lead | On approved UI changes |
| Security scan review | Tech Lead | Every release |
| Compliance review | QA Lead + Legal | Quarterly |
| Strategy document update | QA Lead | Quarterly |

---

## 8. Definition of Done — QA Perspective

A user story is **Done** when:

1. Unit tests cover all new business logic (Tier-A target)
2. Integration tests cover all new API endpoints
3. E2E tests cover any new critical user journey (if applicable)
4. No new security findings above medium severity
5. CI pipeline passes all PR gates
6. Testability reviewed by QA (no new anti-patterns added)

---

## Appendix — Toolkit Quick Reference

| Goal | Command |
|---|---|
| Audit TS coverage | `/tw-ts-test-governor` |
| Auto-fix coverage gaps | `/tw-quality-sprint` |
| Generate integration tests | `/tw-integration-discovery source=openapi/api.yaml` |
| Generate CI pipeline | `/tw-pipeline-generator` |
| Security scan | `/tw-security-audit` |
| Check release readiness | `/tw-release-readiness` |
| Quality trend dashboard | `/tw-quality-trend since=30d` |
```

## Examples

### Example 1 — First day on a new TypeScript client

```
/tw-test-strategy-generator project_name="OrderFlow Platform" risk_profile=high
```

### Example 2 — Healthcare SaaS with HIPAA requirement

```
/tw-test-strategy-generator industry=healthcare regulatory=hipaa risk_profile=critical
```

### Example 3 — Fintech startup, small team

```
/tw-test-strategy-generator team_size=small risk_profile=high regulatory=gdpr,pci-dss
```

### Example 4 — Export for Confluence

```
/tw-test-strategy-generator output_format=confluence
```

## Dependencies

- Source code accessible in working directory for stack auto-detection
- No additional tools required — analysis is based on existing project files

## Notes

- This document is a first draft — always review with the client team before sharing with stakeholders
- Coverage targets are starting points — adjust based on the project's actual risk tolerance
- The phased roadmap assumes a 2-week sprint cadence — adjust for kanban/other delivery models
- For very small teams (1-3 engineers), simplify: unit + integration only, skip mutation and visual regression initially
- Pair with `/tw-stack-health-check` for the technical assessment to accompany the strategy document
