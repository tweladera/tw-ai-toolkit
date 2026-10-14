---
name: a11y-audit
description: Injects axe-core accessibility checks into existing Playwright or Cypress tests, or runs standalone WCAG 2.1 audits on specified pages, and produces a violation report classified by impact level and WCAG criterion.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: framework
    type: string
    required: false
    default: ""
    description: "E2E framework: 'playwright' or 'cypress'. Auto-detected."
  - name: pages
    type: string
    required: false
    default: ""
    description: "Comma-separated page URLs or paths to audit (e.g. '/login,/orders,/dashboard'). If omitted, detects pages from existing E2E tests."
  - name: wcag_level
    type: string
    required: false
    default: "AA"
    description: "WCAG conformance level: 'A', 'AA', or 'AAA'. Default: AA (most common regulatory requirement)."
  - name: mode
    type: string
    required: false
    default: "inject"
    description: "'inject' to add axe-core checks to existing tests. 'standalone' to run a dedicated accessibility scan. 'report-only' to audit without modifying test files."
tags:
  - accessibility
  - a11y
  - wcag
  - axe-core
  - playwright
  - cypress
  - compliance
  - qa
invocation: tw-a11y-audit
---

# a11y-audit

## Description

Integrates axe-core accessibility testing into the E2E test layer and produces WCAG 2.1
violation reports. In enterprise applications, accessibility compliance (WCAG 2.1 AA) is
frequently a contractual or regulatory requirement — failing it is a legal risk, not just
a UX issue.

**Two modes:**
- `inject`: Adds `checkA11y()` calls to existing Playwright/Cypress tests — zero-cost
  accessibility coverage using tests that are already running
- `standalone`: Generates dedicated accessibility spec files that visit each page and
  check the full WCAG 2.1 AA ruleset

**axe-core** is the industry standard for automated accessibility testing (used by
Google Lighthouse, Deque, IBM Equal Access). It catches ~30-40% of WCAG violations
automatically — the rest require manual review.

## When to Use

- Before a release where accessibility compliance is a requirement
- After major UI changes that could have broken ARIA markup
- When auditing an existing application for the first time
- When the `e2e-test-governor` flags pages with no accessibility coverage

Triggers: "check accessibility", "WCAG compliance", "a11y audit", "accessibility violations",
"is the app accessible".

## Instructions

### Step 1 — Detect Pages to Audit

If `pages` parameter is provided, use those paths.

Otherwise, scan existing E2E tests for visited routes:
```bash
rg "cy\.visit\(|page\.goto\(" --type ts --type js -o | grep -oP "(?<=['\"])\/[^'\"]*(?=['\"])" | sort -u
```

Also detect main application routes:
```bash
# React Router / Next.js
rg "path=|href=|<Route\s" --type tsx --type ts | grep -oP "(?<=['\"])\/[^'\"]*(?=['\"])" | sort -u | head -20

# Spring MVC
rg "@RequestMapping|@GetMapping" src/main/ | grep -oP "(?<=['\"])\/[^'\"]*(?=['\"])" | sort -u
```

### Step 2 — Install axe-core Dependencies

**Playwright:**
```bash
npm install --save-dev @axe-core/playwright
# or: yarn add -D @axe-core/playwright
```

**Cypress:**
```bash
npm install --save-dev cypress-axe axe-core
```

Add to `cypress/support/commands.ts`:
```typescript
import 'cypress-axe';
```

### Step 3a — Inject into Existing Tests (mode=inject)

For each existing test file, add `checkA11y()` after navigation:

**Playwright — inject after page.goto():**
```typescript
// Before (existing test)
test('should display order list', async ({ page }) => {
  await page.goto('/orders');
  await expect(page.getByTestId('list-orders')).toBeVisible();
});

// After (with a11y injection)
import { checkA11y, injectAxe } from '@axe-core/playwright';

test('should display order list', async ({ page }) => {
  await page.goto('/orders');
  await injectAxe(page);
  await checkA11y(page, undefined, {
    axeOptions: { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] } },
    detailedReport: true,
    detailedReportOptions: { html: true },
  });
  await expect(page.getByTestId('list-orders')).toBeVisible();
});
```

**Cypress — inject after cy.visit():**
```typescript
// Before
it('should display order list', () => {
  cy.visit('/orders');
  cy.getByTestId('list-orders').should('be.visible');
});

// After
it('should display order list', () => {
  cy.visit('/orders');
  cy.injectAxe();
  cy.checkA11y(undefined, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] },
  }, (violations) => {
    violations.forEach(v => cy.log(`[a11y] ${v.impact}: ${v.description}`));
  });
  cy.getByTestId('list-orders').should('be.visible');
});
```

### Step 3b — Generate Standalone Tests (mode=standalone)

**Playwright:**
```typescript
// tests/a11y/accessibility.spec.ts
import { test } from '@playwright/test';
import { checkA11y, injectAxe } from '@axe-core/playwright';

const PAGES_TO_AUDIT = [
  { path: '/login',     name: 'Login page' },
  { path: '/orders',    name: 'Orders list' },
  { path: '/dashboard', name: 'Dashboard' },
  // Add more pages here
];

for (const { path, name } of PAGES_TO_AUDIT) {
  test(`WCAG 2.1 AA — ${name}`, async ({ page }) => {
    await page.goto(path);
    await injectAxe(page);
    await checkA11y(page, undefined, {
      axeOptions: {
        runOnly: {
          type: 'tag',
          values: ['wcag2a', 'wcag2aa'],
        },
      },
      detailedReport: true,
    });
  });
}
```

**Cypress:**
```typescript
// cypress/e2e/a11y/accessibility.cy.ts
const PAGES = ['/login', '/orders', '/dashboard'];

PAGES.forEach((page) => {
  describe(`WCAG 2.1 AA — ${page}`, () => {
    beforeEach(() => {
      cy.visit(page);
      cy.injectAxe();
    });

    it('should have no WCAG 2.1 AA violations', () => {
      cy.checkA11y(undefined, {
        runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] },
      });
    });
  });
});
```

### Step 4 — Run and Parse Results

```bash
# Playwright
npx playwright test tests/a11y/ --reporter=json | tee a11y-results.json

# Cypress
npx cypress run --spec "cypress/e2e/a11y/**" --reporter json | tee a11y-results.json
```

Parse axe-core violation output and classify:

| Impact | WCAG level | Action |
|---|---|---|
| critical | A/AA | Block release — legal/regulatory risk |
| serious | AA | Fix before release |
| moderate | AA | Fix in current sprint |
| minor | AA/AAA | Backlog |

### Step 5 — Generate Accessibility Report

```markdown
# Accessibility Audit Report

**Generated:** YYYY-MM-DD
**WCAG Level:** AA
**Pages audited:** N
**Framework:** [playwright|cypress]

## Summary

| Impact | Count | Action |
|---|---|---|
| Critical | 2 | Block release |
| Serious | 5 | Fix before release |
| Moderate | 8 | Fix this sprint |
| Minor | 12 | Backlog |

**Pages with violations:**
- /login — 3 violations (1 critical, 2 serious)
- /orders — 7 violations (0 critical, 3 serious, 4 moderate)

## Critical Violations — Fix Immediately

### /login — Image without alt text
- **WCAG Criterion:** 1.1.1 Non-text Content (Level A)
- **Element:** `<img src="company-logo.png">` at `/login` header
- **Impact:** Screen readers cannot identify the logo
- **Fix:** Add `alt="Company Logo"` or `alt=""` if decorative
- **axe rule:** image-alt

### /orders — Form label missing
- **WCAG Criterion:** 1.3.1 Info and Relationships (Level A)
- **Element:** `<input type="text" placeholder="Search orders">`
- **Impact:** Input has no programmatic label — assistive technology cannot describe it
- **Fix:** Add `<label for="search-input">Search orders</label>` or `aria-label`
- **axe rule:** label

## Serious Violations
[...]

## Automated vs Manual Coverage

Note: axe-core detects approximately 30-40% of WCAG violations automatically.
The following require manual review:
- Focus order and keyboard navigation
- Reading order (visual vs DOM order)
- Color contrast in dynamic states (hover, focus, disabled)
- Timeout warnings and session management
- Complex widgets (date pickers, multi-select) with keyboard support
```

## Examples

### Example 1 — Inject into existing tests (no new files)

```
/tw-a11y-audit mode=inject framework=playwright
```

### Example 2 — Standalone audit of key pages

```
/tw-a11y-audit mode=standalone pages=/login,/orders,/dashboard,/profile wcag_level=AA
```

### Example 3 — Report only (no file changes)

```
/tw-a11y-audit mode=report-only pages=/login,/checkout
```

## Dependencies

- Playwright or Cypress installed in the project
- `@axe-core/playwright` (Playwright) or `cypress-axe` + `axe-core` (Cypress)
- Running application instance for standalone mode
- Node.js in PATH

## Notes

- axe-core catches ~30-40% of WCAG violations — manual testing is still required
- The `inject` mode is zero-cost: it adds accessibility checks to tests already running
- Critical violations (WCAG Level A) are usually quick to fix — prioritize them
- Color contrast must be checked manually or with a specialized tool (Colour Contrast Analyser)
- Dynamic content (modals, toasts, accordions) requires testing in the open/active state
