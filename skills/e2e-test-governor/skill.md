---
name: e2e-test-governor
description: Audits E2E test coverage by mapping user flows and feature files to existing Cypress or Playwright test files, classifies gaps by risk, detects stale or brittle tests, and produces a governance report with actionable recommendations.
status: stable
version_added: v0.3.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: framework
    type: string
    required: false
    default: ""
    description: "E2E framework to audit: 'cypress' or 'playwright'. Auto-detected from config files if omitted."
  - name: features_dir
    type: string
    required: false
    default: ""
    description: Directory containing .feature files to cross-reference. Defaults to 'specs/' or 'features/' if present.
  - name: base_ref
    type: string
    required: false
    default: ""
    description: Git ref to diff against (e.g. origin/main). When provided, focuses the report on flows touched by changed code.
  - name: strict_selectors
    type: boolean
    required: false
    default: "false"
    description: When true, flags any selector that is not data-testid or ARIA-based as a selector health risk.
tags:
  - e2e
  - cypress
  - playwright
  - governance
  - coverage
  - qa
invocation: tw-e2e-test-governor
---

# e2e-test-governor

## Description

Audits the E2E test layer of a Cypress or Playwright project. Unlike unit test coverage
(which measures line/branch coverage), E2E coverage is measured by **user flow coverage**:
which critical user journeys have automated tests and which do not.

The governor maps three dimensions:
1. **Feature coverage**: feature files (`*.feature`) → E2E test files (`*.cy.ts` / `*.spec.ts`)
2. **Flow coverage**: critical routes/pages → which have at least one E2E test touching them
3. **Test health**: existing tests with selector risks, missing waits, or stale references

**SDET perspective:** A 90% unit test coverage number says nothing about whether a user
can actually complete a purchase. This skill provides the coverage visibility that matters
for shipping confidence.

## When to Use

- Before a release: verify critical user journeys have E2E coverage
- After adding a new feature: check if the E2E layer kept up with the unit layer
- After a UI refactoring: detect stale tests before they fail in CI
- After running `/tw-exec-spec-generator`: verify which generated feature files have no E2E test yet
- When E2E tests are failing: distinguish brittle selectors from real regressions

Use this skill before `/tw-e2e-spec-to-test` — the governor tells you what to build,
the spec-to-test skill builds it.

Triggers: "check E2E coverage", "which user flows have no tests", "E2E audit",
"are our Playwright tests up to date".

## Instructions

### Step 1 — Detect Framework and Config

```bash
ls cypress.config.ts cypress.config.js playwright.config.ts playwright.config.js 2>/dev/null
```

Read the config to determine:
- Test file directories (`specPattern` for Cypress, `testDir` for Playwright)
- Base URL
- Existing test suites (smoke, regression, etc.)

### Step 2 — Inventory E2E Test Files

```bash
# Cypress
rg -l "" --glob "**/*.cy.ts" --glob "**/*.cy.js"

# Playwright
rg -l "" --glob "**/*.spec.ts" --glob "**/*.spec.js" tests/
```

For each test file, extract:
- Test suite name (`describe` block)
- Individual test names (`it` / `test` blocks)
- Tags (`@smoke`, `@regression`, custom)
- Routes visited (`cy.visit(...)`, `page.goto(...)`)
- API calls intercepted (`cy.intercept`, `page.route`)
- Selector types used (data-testid vs ARIA vs CSS)

### Step 3 — Inventory Feature Files (if features_dir or specs/ exists)

```bash
find specs/ features/ -name "*.feature" 2>/dev/null | sort
```

For each feature file, extract:
- Feature name
- Scenario names and tags
- Whether a corresponding E2E test file exists

### Step 4 — Inventory Critical User Flows

Detect routes and pages from the application source:

```bash
# React Router / Next.js routes
rg "path=|href=|to=|<Route|<Link" --type ts --type tsx -l | head -20

# NestJS controllers (for API-driven flows)
rg "@Get\(|@Post\(|@Controller\(" --type ts -l | head -20

# Angular routes
rg "RouterModule\|path:" --type ts -l | head -10
```

Also look for navigation in existing tests to infer what routes are being exercised.

Classify routes as:
- **CRITICAL** — login/auth, main purchase/transaction flow, core feature of the product
- **HIGH** — secondary features, account management, key error paths
- **MEDIUM** — supporting flows (profile edit, preferences, search)
- **LOW** — non-critical informational pages, admin-only paths

### Step 5 — Map Coverage

Build the coverage matrix:

**Feature Coverage:**
For each `.feature` file, find the corresponding test file by:
1. File name match (`order-placement.feature` → `order-placement.cy.ts` or `order-placement.spec.ts`)
2. Route match (Given step URL → `cy.visit()` / `page.goto()` in test files)
3. Scenario title match (fuzzy match on scenario name in test `it()` / `test()` names)

**Flow Coverage:**
For each critical route, check whether any test file visits or exercises it.

**Selector Health Check:**
Scan existing test files for fragile selectors:

```bash
# CSS class selectors (fragile)
rg '\.get\("\.[^"]+"\)|cy\.get\('\''\.|\$\("\.' --type ts --type js

# nth-child / nth-of-type selectors (very fragile)
rg 'nth-child|nth-of-type|:first-child|:last-child' --type ts --type js

# Hardcoded waits (reliability risk)
rg 'cy\.wait\(\d|waitForTimeout\(\d|sleep\(\d' --type ts --type js
```

### Step 6 — Generate Governance Report

```markdown
# E2E Test Governance Report

**Generated:** YYYY-MM-DD HH:MM:SS
**Skill:** /tw-e2e-test-governor | v0.3.0
**Framework:** [cypress|playwright]
**Project:** [path]

## Executive Summary

- **E2E test files:** N
- **Scenarios covered:** N
- **Critical flows with coverage:** X/Y (Z%)
- **Feature files without E2E tests:** N
- **Overall decision:** [CREATE TESTS | UPDATE TESTS | FIX SELECTORS | NO ACTION NEEDED]
- **Primary risk:** [one sentence]

## Feature Coverage Matrix

| Feature File | E2E Test File | Scenarios in Spec | Scenarios with Tests | Status |
|---|---|---|---|---|
| order-placement.feature | order-placement.cy.ts | 8 | 5 | PARTIAL |
| login.feature | login.spec.ts | 4 | 4 | COVERED |
| refund-flow.feature | — | 6 | 0 | MISSING |

Status values:
- COVERED — all scenarios have a corresponding test block
- PARTIAL — some scenarios are missing test coverage
- MISSING — no test file found for this feature
- STALE — test file exists but references routes/selectors not found in codebase

## Flow Coverage Matrix

| User Flow | Route | Priority | Test Coverage | Status | Action |
|---|---|---|---|---|---|
| User login | /login | CRITICAL | login.spec.ts | COVERED | — |
| Place order | /orders/new | CRITICAL | — | MISSING | create-test |
| Cancel order | /orders/:id/cancel | HIGH | cancel.cy.ts | COVERED | — |
| View profile | /profile | MEDIUM | — | MISSING | create-test |

## Test Health Report

| File | Issue | Type | Risk | Recommendation |
|---|---|---|---|---|
| checkout.cy.ts:34 | `cy.wait(3000)` | Hardcoded wait | HIGH | Replace with `cy.intercept` alias |
| orders.spec.ts:67 | `.get('.submit-btn')` | CSS class selector | HIGH | Add data-testid, use getByTestId() |
| login.cy.ts:12 | `div:nth-child(2)` | Structural selector | HIGH | Use getByRole() or data-testid |

## Gaps by Priority

### CRITICAL — Must fix before release
[List of critical flows with no coverage]

### HIGH — Fix in current sprint
[List of high-priority flows with no coverage]

### MEDIUM — Plan for next sprint
[List of medium-priority flows or partial coverage]

## Recommendations

**Priority 1 (CRITICAL):**
[Action items with specific skills to invoke]

**Priority 2 (HIGH):**
[Action items]

**Priority 3 (MEDIUM — selector health):**
[Selector replacement items]

Would you like me to: 1) generate tests for CRITICAL gaps with /tw-e2e-spec-to-test,
2) fix brittle selectors in the health report, 3) generate POMs for missing pages with /tw-e2e-page-object?
```

### Step 7 — Save Report

```bash
filename="E2E_GOVERNANCE_REPORT_$(date +%Y-%m-%d_%H-%M-%S).md"
```

Save to project root using the Write tool.

### Classification Rules

**Flow is CRITICAL when:**
- It is the primary monetization or core-value flow (checkout, signup, key feature)
- Authentication / session management is involved
- The flow is explicitly called out in product SLAs or acceptance criteria
- Failure of this flow results in immediate user impact or revenue loss

**Flow is HIGH when:**
- It is a secondary feature that users rely on regularly
- Error/edge-case path of a CRITICAL flow
- It has been a source of production incidents in the past

**Test is STALE when:**
- `cy.visit(route)` or `page.goto(route)` points to a route not found in the router config
- `data-testid` or ARIA label targeted by the test does not exist in current component files
- The test `describe` / `it` name references a feature that has been renamed or removed

## Examples

### Example 1 — Full audit of a Playwright project

```
/tw-e2e-test-governor
```

### Example 2 — Audit with feature file cross-reference

```
/tw-e2e-test-governor features_dir=specs/ framework=playwright
```

### Example 3 — Diff-focused audit for a PR

```
/tw-e2e-test-governor base_ref=origin/main
```

### Example 4 — Strict selector audit

```
/tw-e2e-test-governor strict_selectors=true
```

Flags every selector that is not `data-testid` or ARIA-based as a health risk,
even if it is currently working.

## Dependencies

- Cypress (`cypress.config.*`) or Playwright (`playwright.config.*`) in the project
- `ripgrep` (`rg`) for scanning test and source files
- `.feature` files in `specs/` or `features/` for feature coverage matrix (optional but recommended)
- Reference files at `references/analysis-guide.md`

## Notes

- E2E coverage is NOT the same as code coverage — a test hitting a page does not mean
  every line in that page's controller/service is exercised
- Stale tests are worse than no tests — they pass locally but fail in CI with no clear reason
- The selector health report is the most actionable output for teams with existing E2E suites
- Use this skill AFTER `/tw-ts-test-governor` or `/tw-python-test-governor`, not instead of them
