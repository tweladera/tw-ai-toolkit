# E2E Test Governor — Analysis Guide

Reference for classifying E2E coverage gaps and test health issues.

---

## Flow Priority Classification

### CRITICAL

A user flow is CRITICAL when ANY of these are true:
- It is the primary path through which the product delivers value (purchase, signup, core action)
- It involves authentication or session state
- Failure produces immediate user-visible impact (cannot use the product)
- It is mentioned in SLAs, incident playbooks, or on-call runbooks
- It has caused a production incident in the last 6 months

Examples: Login, checkout, password reset, core CRUD of the main entity, payment processing.

### HIGH

A user flow is HIGH when:
- It is a secondary feature used by most users regularly
- It is an error or edge-case path of a CRITICAL flow
- It involves data loss risk (delete, bulk update, export)
- It integrates with an external service that can fail

Examples: Account settings, order cancellation, file upload, search with filters.

### MEDIUM

A user flow is MEDIUM when:
- It is used by a subset of users or in infrequent conditions
- It is a supporting or informational flow
- Failure degrades UX but does not block core functionality

Examples: Profile editing, notification preferences, onboarding tour, reports/exports.

### LOW

A user flow is LOW when:
- It is admin-only or internal tooling
- It is a static or read-only page
- It duplicates coverage already provided by a CRITICAL or HIGH test

---

## Coverage Status Definitions

| Status | Definition | Action |
|---|---|---|
| COVERED | Every scenario in the feature file has a corresponding test block AND the test passes | No action needed |
| PARTIAL | Feature file has tests but ≥1 scenario is missing (usually error paths, edge cases) | update-test |
| MISSING | No test file exists for this feature or flow | create-test |
| STALE | Test file exists but routes, selectors, or API paths no longer exist in the codebase | review-test |
| UNKNOWN | Cannot determine coverage without running the test suite | run tests first |

---

## Selector Health Severity

| Selector Type | Severity | Reason |
|---|---|---|
| `data-testid` | None | Stable — only changes on deliberate QA decision |
| ARIA role + name (`getByRole`, `findByRole`) | None | Stable + validates accessibility |
| Label text (`getByLabel`, `findByLabelText`) | Low | Changes with copy updates, but intentional |
| Visible text (`getByText`, `contains`) | Low-Medium | Changes with copy updates or i18n |
| Attribute selector (`[type="submit"]`, `[name="email"]`) | Medium | Acceptable when no better option |
| ID selector (`#submit-btn`) | Medium | OK if IDs are deterministic and non-generated |
| CSS class (`.btn-primary`, `.order-form__submit`) | HIGH | Breaks with UI redesigns — replace |
| Structural (`div:nth-child(3)`, `table tr:last-child`) | CRITICAL | Breaks with any DOM change — replace immediately |
| Generated ID (`#ember123`, `#react-select-5`) | CRITICAL | Non-deterministic — never stable |

---

## Test Health Issue Patterns

### Hardcoded waits

```typescript
cy.wait(3000)              // Cypress — replace with cy.intercept alias
await page.waitForTimeout(3000)  // Playwright — replace with waitForURL or expect().toBeVisible()
```

**Fix:** Intercept the API call and wait for the response, or wait for a visible element.

### Missing API interception

When a scenario's `When` step triggers a network call and no `cy.intercept` / `page.route`
exists, the test is non-deterministic (depends on backend response time and state).

**Fix:** Add API interception for any network call triggered in a `When` step.

### Missing assertions on API response

A test that clicks "Submit" and only checks the URL is not asserting the API call succeeded.

**Fix:** Assert `response.statusCode` when intercepting API calls.

### Test-data coupling

When tests use hardcoded IDs, emails, or data that must exist in a specific database state,
they are environment-dependent and fragile.

**Fix:** Use fixture files + API mocking to isolate tests from backend state.

### Missing cleanup

Tests that create data (create order, create user) without cleanup can cause other tests to fail.

**Fix:** Use `afterEach` / `test.afterEach` to delete test data, or scope tests with unique IDs per run.

---

## Decision Matrix

| Condition | Decision |
|---|---|
| CRITICAL flow with MISSING coverage | HALT — block release until test exists |
| HIGH flow with MISSING coverage | CREATE TESTS — priority for current sprint |
| MEDIUM flow with MISSING coverage | CREATE TESTS — plan for next sprint |
| CRITICAL/HIGH test with STALE status | FIX TESTS FIRST — stale test is worse than no test |
| Tests with CRITICAL selector health | FIX SELECTORS — before the next UI deploy |
| All CRITICAL and HIGH flows covered, no stale tests | NO ACTION NEEDED |
