---
name: e2e-spec-to-test
description: Converts a Gherkin feature file into runnable Cypress or Playwright E2E test files following the Page Object Model pattern. Closes the spec-first loop by turning executable specs into production-ready tests with stable selectors and proper async handling.
status: stable
version_added: v0.3.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: feature
    type: string
    required: true
    default: ""
    description: Path to the .feature file to convert. Typically produced by /tw-exec-spec-generator.
  - name: framework
    type: string
    required: false
    default: ""
    description: "Target E2E framework: 'cypress' or 'playwright'. Auto-detected from cypress.config.* or playwright.config.* if omitted."
  - name: pages
    type: string
    required: false
    default: ""
    description: Comma-separated page names to generate POM classes for (e.g. 'LoginPage,OrderPage'). If omitted, inferred from feature file scenarios.
  - name: base_url
    type: string
    required: false
    default: ""
    description: Base URL of the application under test (e.g. 'http://localhost:3000'). Read from framework config if omitted.
  - name: output_dir
    type: string
    required: false
    default: ""
    description: Directory for generated test files. Defaults to 'cypress/e2e/' for Cypress or 'tests/' for Playwright.
tags:
  - e2e
  - cypress
  - playwright
  - bdd
  - gherkin
  - page-object-model
  - qa
invocation: tw-e2e-spec-to-test
---

# e2e-spec-to-test

## Description

Converts a Gherkin `.feature` file into runnable E2E test code for Cypress or Playwright,
following the Page Object Model (POM) pattern. This skill is the bridge between the spec-first
workflow (where `/tw-exec-spec-generator` produces the feature file) and a runnable test suite.

**Output per feature file:**
- One test file (`.cy.ts` for Cypress, `.spec.ts` for Playwright) with all scenarios implemented
- One POM class per page or user-facing surface involved in the scenarios
- One fixture file with representative test data extracted from scenario examples

**SDET-first design decisions baked in:**
- Selector hierarchy enforced: `data-testid` > ARIA roles > label text > visible text > CSS
- No hardcoded waits (`cy.wait(3000)` or `page.waitForTimeout(3000)`) — only condition-based waits
- API interception over UI navigation where possible (faster, more deterministic)
- Each `Scenario` maps to one `it()` / `test()` block — one behavior per test

## When to Use

- After `/tw-exec-spec-generator` produces a `.feature` file and you want runnable E2E tests
- When converting an existing `.feature` file to a new framework (Cypress ↔ Playwright)
- When adding E2E coverage for a user flow that has Gherkin specs but no automation

Triggers: user says "convert this feature to Cypress", "write Playwright tests for this spec",
"generate E2E tests from the feature file".

## Instructions

### Step 1 — Detect Framework

Check the project root for framework config files:

```bash
ls cypress.config.ts cypress.config.js playwright.config.ts playwright.config.js 2>/dev/null
```

**Framework selection:**
- `cypress.config.*` found → `cypress`
- `playwright.config.*` found → `playwright`
- Both found → use `framework` parameter; if not set, ask the user
- Neither found → ask the user which to use and offer to scaffold the config

Read the framework config to extract:
- `baseUrl` (Cypress) or `use.baseURL` (Playwright) — use in `visit()` / `page.goto()`
- `specPattern` (Cypress) or `testDir` (Playwright) — determines output directory
- TypeScript support (check `tsconfig.json` in project root)

### Step 2 — Parse the Feature File

Read the `.feature` file specified in `feature`. Extract:

1. **Feature name** → determines output file names and POM class names
2. **Background** → becomes `beforeEach()` setup
3. **Scenarios** → each becomes one `it()` / `test()` block
4. **Scenario Outline + Examples** → becomes parameterized tests (`cy.each` / `test.each`)
5. **Tags** → map to test metadata:
   - `@smoke` → mark test for smoke suite
   - `@security` → add skip if no auth context available
   - `@contract` → note that API mock is expected
   - `@happy` → no special handling
6. **Given steps** → preconditions (navigation, auth, state setup)
7. **When steps** → user actions (click, fill, select, submit)
8. **Then steps** → assertions (visible, URL, text, API response)

Identify the pages involved: look for navigation verbs in `Given` steps
("the user is on the X page", "the user navigates to X").

### Step 3 — Scan Codebase for Existing Selectors

Before generating any selector, scan the codebase for `data-testid` attributes
and ARIA patterns in the existing components:

```bash
# Find existing data-testid attributes
rg 'data-testid="[^"]*"' --type ts --type tsx --type html -o | sort -u

# Find existing ARIA labels
rg 'aria-label="[^"]*"' --type ts --type tsx --type html -o | sort -u

# Find existing form labels
rg '<label[^>]*for="[^"]*"' --type html --type tsx -o | sort -u
```

**Use found selectors directly.** Do not invent `data-testid` values — they must exist
in the component source or be explicitly added.

If a required `data-testid` does not exist, generate the test with a `TODO` comment:
```typescript
// TODO: add data-testid="submit-order" to the submit button in OrderForm.tsx
const submitButton = page.getByTestId('submit-order'); // MISSING — add to component
```

### Step 4 — Generate POM Classes

Apply the selector hierarchy from `references/selector-strategy.md`.

**Playwright POM template:**
```typescript
import { type Page, type Locator } from '@playwright/test';

export class [PageName]Page {
  readonly page: Page;

  // Locators — ordered by selector strategy (data-testid first)
  readonly [elementName]: Locator;

  constructor(page: Page) {
    this.page = page;
    this.submitButton = page.getByTestId('[data-testid-value]');
    this.amountInput  = page.getByLabel('[label-text]');
    this.errorMessage = page.getByRole('alert');
  }

  async navigate() {
    await this.page.goto('/[path]');
  }

  async [actionName]([params]) {
    await this.[element].[action]([params]);
    // Wait for observable outcome, not arbitrary time
    await this.page.waitForURL('**/[expected-path]/**');
  }

  async expect[StateName]() {
    await expect(this.[element]).toBeVisible();
  }
}
```

**Cypress POM template (object-based, compatible with cy.*):**
```typescript
export const [PageName]Page = {
  visit: () => cy.visit('/[path]'),

  // Getters — each returns a Cypress chainable
  getSubmitButton: () => cy.getByTestId('[data-testid-value]'),
  getAmountInput:  () => cy.findByLabelText('[label-text]'),
  getErrorMessage: () => cy.findByRole('alert'),

  // Actions
  [actionName]: ([params]: [types]) => {
    [PageName]Page.get[Element]().[action]([params]);
  },
};
```

Save each POM to:
- Playwright: `tests/pages/[PageName].page.ts`
- Cypress: `cypress/pages/[PageName].page.ts`

### Step 5 — Generate Test File

Map each scenario to a test block.

**Playwright test structure:**
```typescript
import { test, expect } from '@playwright/test';
import { [PageName]Page } from '../pages/[PageName].page';

test.describe('[Feature name]', () => {

  test.beforeEach(async ({ page }) => {
    // Background steps
    await page.goto('/');
  });

  test('[Scenario title] @[tag]', async ({ page }) => {
    const orderPage = new OrderPage(page);

    // Given
    await orderPage.navigate();

    // When
    await orderPage.[action]([fixture.value]);

    // Then
    await orderPage.expect[State]();
    await expect(page).toHaveURL(/\/[expected-path]/);
  });

  // Scenario Outline → test.each
  const cases = [
    { amount: 100, expected: 'confirmed' },
    { amount: 0,   expected: 'rejected'  },
  ] satisfies Array<{ amount: number; expected: string }>;

  for (const { amount, expected } of cases) {
    test(`handles amount ${amount} expecting ${expected}`, async ({ page }) => {
      // ...
    });
  }
});
```

**Cypress test structure:**
```typescript
import { [PageName]Page } from '../../pages/[PageName].page';
import fixture from '../../fixtures/[feature-name].json';

describe('[Feature name]', () => {

  beforeEach(() => {
    // Background steps
    cy.visit('/');
  });

  it('[Scenario title]', () => {
    // Given
    [PageName]Page.visit();

    // When
    [PageName]Page.[action](fixture.[value]);

    // Then
    [PageName]Page.get[Element]().should('be.visible');
    cy.url().should('include', '/[expected-path]');
  });
});
```

**API interception rules (apply when `@contract` or When step involves a network call):**

```typescript
// Playwright
await page.route('**/api/orders', async route => {
  await route.fulfill({ json: fixture.orderResponse });
});

// Cypress
cy.intercept('POST', '/api/orders', { fixture: '[feature-name]/order-response' }).as('placeOrder');
// ... actions ...
cy.wait('@placeOrder').its('response.statusCode').should('eq', 201);
```

### Step 6 — Generate Fixture File

Extract test data from `Scenario Outline` example tables and inline values:

```json
{
  "_comment": "Test data for [feature-name] — do not use production data",
  "validOrder": {
    "amount": 150.00,
    "currency": "USD",
    "itemId": "test-item-001"
  },
  "invalidOrder": {
    "amount": -1,
    "currency": "USD",
    "itemId": "test-item-001"
  },
  "orderResponse": {
    "id": "test-order-id",
    "status": "CONFIRMED"
  }
}
```

Save to:
- Playwright: `tests/fixtures/[feature-name].json`
- Cypress: `cypress/fixtures/[feature-name].json`

### Step 7 — Validate and Summarize

Check that generated files compile (if TypeScript):

```bash
# Playwright
npx tsc --noEmit --project tsconfig.json 2>&1 | head -20 || true

# Cypress
npx tsc --noEmit --project cypress/tsconfig.json 2>&1 | head -20 || true
```

Output summary:
```
E2E test generation complete
Framework: [cypress|playwright]
Feature:   [feature-name]

Files generated:
  [output_dir]/[feature-name].[cy|spec].ts   — N scenarios
  [output_dir]/pages/[Page]Page.ts            — M locators, K actions
  [output_dir]/fixtures/[feature-name].json   — J test data objects

Selector warnings:
  - [N] TODOs: data-testid attributes not found in codebase → add before running

Next steps:
  1. Add missing data-testid attributes to components (see TODOs in generated files)
  2. Run: [npx playwright test | npx cypress run] to verify
  3. Run /tw-e2e-test-governor to check overall E2E coverage
```

## Examples

### Example 1 — Convert a feature file to Playwright

```
/tw-e2e-spec-to-test feature=specs/order-placement-2026-10-14.feature framework=playwright
```

### Example 2 — Auto-detect framework and convert

```
/tw-e2e-spec-to-test feature=specs/login-2026-10-14.feature
```

Claude detects `playwright.config.ts` in the root and generates Playwright tests.

### Example 3 — Full spec-first E2E flow

```
# Step 1: Generate spec
/tw-exec-spec-generator story="As a buyer I want to place an order..."

# Step 2: Convert spec to runnable tests
/tw-e2e-spec-to-test feature=specs/order-placement-2026-10-14.feature

# Step 3: Verify overall E2E coverage
/tw-e2e-test-governor
```

## Dependencies

- Gherkin `.feature` file (produced by `/tw-exec-spec-generator` or written manually)
- Cypress (`cypress.config.ts`) or Playwright (`playwright.config.ts`) installed in the project
- `ripgrep` (`rg`) for scanning existing selectors
- TypeScript recommended (skill generates `.ts` files)
- Reference files at `references/selector-strategy.md`

## Notes

- This skill does NOT run the tests — it generates them. Run them manually or in CI.
- If `data-testid` attributes are missing from components, add them before running generated tests
- Selector TODOs in generated files must be resolved before the tests can pass
- Generated fixtures use test data, never production data — verify before committing
- For apps without a component source (legacy, third-party), use `/tw-e2e-page-object` first
  to build POMs from URL inspection or HTML analysis
