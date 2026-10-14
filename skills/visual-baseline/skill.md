---
name: visual-baseline
description: Captures visual snapshots of application pages (Golden Master for UI) and compares them pixel-by-pixel to detect unintended visual regressions — CSS changes, layout shifts, or component rendering issues — invisible to functional tests.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: mode
    type: string
    required: true
    default: ""
    description: "'capture' to record visual baseline screenshots, 'compare' to diff current screenshots against baseline."
  - name: pages
    type: string
    required: false
    default: ""
    description: "Comma-separated page paths to capture (e.g. '/login,/dashboard,/orders'). Auto-detected from E2E tests if omitted."
  - name: framework
    type: string
    required: false
    default: ""
    description: "E2E framework: 'playwright' or 'cypress'. Auto-detected."
  - name: threshold
    type: number
    required: false
    default: 0.1
    description: "Maximum acceptable pixel difference (%). Default: 0.1% — stricter than most defaults."
  - name: viewports
    type: string
    required: false
    default: "desktop"
    description: "Viewport profiles: 'desktop' (1280x720), 'mobile' (375x667), 'tablet' (768x1024), or 'all'."
tags:
  - visual-regression
  - screenshot
  - playwright
  - cypress
  - golden-master
  - qa
invocation: tw-visual-baseline
---

# visual-baseline

## Description

Extends the `golden-master` concept to the visual layer. Captures screenshots of application
pages under controlled conditions and compares them pixel-by-pixel against saved baselines
to detect visual regressions that functional tests cannot see.

**What functional tests miss:**
- A CSS `z-index` change that hides a button behind an overlay
- A `margin: auto` → `margin: 0` change that shifts an entire layout
- A font loading failure that renders placeholder text
- A truncated label that cuts off critical information
- A design system component update that changes button appearance

**Playwright built-in** (`toHaveScreenshot`): zero external dependencies, fast, native diff.
**Cypress**: uses `cypress-image-snapshot` or `@percy/cypress`.

## When to Use

- Before/after a CSS or design system upgrade
- After introducing new UI framework version (React 18 → 19, Angular updates)
- When a shared component changes — verify no consumer pages are broken visually
- As part of a release checklist for UI-heavy applications
- After dark mode / theming implementation

Triggers: "check visual regressions", "screenshot comparison", "did the UI change",
"visual baseline", "pixel diff".

## Instructions

### Step 1 — Detect Pages and Framework

Auto-detect pages from existing E2E tests if `pages` not specified:
```bash
rg "cy\.visit\(|page\.goto\(" --type ts --type js -o \
  | grep -oP "(?<=['\"])\/[^'\"]*(?=['\"])" | sort -u
```

For Playwright, check `playwright.config.ts` for `baseURL`.

### Step 2a — Capture Mode (Playwright)

Generate a visual baseline spec:

```typescript
// tests/visual/visual-baseline.spec.ts
import { test, expect } from '@playwright/test';

const PAGES = [
  { path: '/login',     name: 'Login' },
  { path: '/dashboard', name: 'Dashboard' },
  { path: '/orders',    name: 'Orders list' },
];

const VIEWPORTS = {
  desktop: { width: 1280, height: 720 },
  mobile:  { width: 375,  height: 667 },
};

for (const [viewportName, viewport] of Object.entries(VIEWPORTS)) {
  for (const { path, name } of PAGES) {
    test(`${name} — ${viewportName}`, async ({ page }) => {
      await page.setViewportSize(viewport);
      await page.goto(path);

      // Wait for page to be visually stable
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(500); // wait for animations to complete

      // Mask dynamic content (timestamps, user names) before comparison
      const dynamicSelectors = ['[data-testid="user-name"]', '[data-testid="timestamp"]'];
      for (const selector of dynamicSelectors) {
        const el = page.locator(selector);
        if (await el.count() > 0) await el.evaluate(el => el.textContent = '[MASKED]');
      }

      await expect(page).toHaveScreenshot(`${name}-${viewportName}.png`, {
        maxDiffPixelRatio: {{threshold}} / 100,
        animations: 'disabled',  // freeze CSS animations
      });
    });
  }
}
```

Run capture:
```bash
npx playwright test tests/visual/ --update-snapshots
```

Baseline screenshots are saved to `tests/visual/__snapshots__/`.

### Step 2b — Capture Mode (Cypress)

```typescript
// cypress/e2e/visual/visual-baseline.cy.ts
import { addMatchImageSnapshotCommand } from '@sinonjs/fake-timers';

const PAGES = ['/login', '/dashboard', '/orders'];

PAGES.forEach((pagePath) => {
  describe(`Visual baseline — ${pagePath}`, () => {
    it('matches visual snapshot', () => {
      cy.visit(pagePath);
      cy.waitForNetworkIdle(500);

      // Mask dynamic elements
      cy.get('[data-testid="timestamp"]').invoke('text', '[MASKED]');
      cy.get('[data-testid="user-name"]').invoke('text', '[MASKED]');

      cy.matchImageSnapshot(`${pagePath.replace(/\//g, '-')}`, {
        failureThreshold: {{threshold}} / 100,
        failureThresholdType: 'percent',
        customSnapshotsDir: 'cypress/snapshots',
      });
    });
  });
});
```

Run capture:
```bash
npx cypress run --spec "cypress/e2e/visual/**" --env updateSnapshots=true
```

### Step 3 — Compare Mode

```bash
# Playwright — runs tests without --update-snapshots flag
npx playwright test tests/visual/ 2>&1 | tee visual-results.txt

# Cypress
npx cypress run --spec "cypress/e2e/visual/**"
```

Parse failures and generate diff report.

### Step 4 — Generate Visual Regression Report

```markdown
# Visual Regression Report

**Mode:** compare
**Baseline:** captured 2026-10-01 (sha: abc1234)
**Current:** 2026-10-14 (sha: def5678)
**Threshold:** {{threshold}}%
**Pages checked:** N
**Viewports:** [desktop|mobile|all]

## Results

| Page | Viewport | Pixel diff | Status |
|---|---|---|---|
| Login | Desktop | 0.02% | ✅ Pass |
| Login | Mobile | 0.00% | ✅ Pass |
| Dashboard | Desktop | 0.18% | 🔥 FAIL (threshold: {{threshold}}%) |
| Orders | Desktop | 0.04% | ✅ Pass |

## Failures — Dashboard (Desktop)

**Pixel difference: 0.18% (above {{threshold}}% threshold)**
**Diff image:** `tests/visual/__snapshots__/Dashboard-desktop-diff.png`

Likely change area: top navigation bar (compare baseline vs current diff image)

**Next steps:**
1. Open diff image to see highlighted changes
2. If change is intentional: update baseline with `npx playwright test tests/visual/ --update-snapshots`
3. If change is unexpected: investigate recent CSS/component changes in dashboard navigation
```

### Step 5 — Mask Dynamic Content

Always mask before capturing to prevent false positives:

```typescript
// Dynamic content that changes between runs — must be masked
const DYNAMIC_SELECTORS = [
  '[data-testid="timestamp"]',     // dates and times
  '[data-testid="user-name"]',     // user-specific data
  '[data-testid="random-quote"]',  // any dynamic/randomized content
  '.chart-canvas',                  // charts with live data
  'video',                         // video elements
  'iframe',                        // external content
];
```

## Examples

### Example 1 — Capture baseline before a CSS refactor

```
/tw-visual-baseline mode=capture pages=/login,/dashboard,/orders viewports=desktop
```

### Example 2 — Compare after the CSS refactor

```
/tw-visual-baseline mode=compare
```

### Example 3 — Full viewport coverage for responsive design

```
/tw-visual-baseline mode=capture viewports=all pages=/login,/checkout
```

## Dependencies

- **Playwright:** built-in `toHaveScreenshot` — no additional packages needed
- **Cypress:** `cypress-image-snapshot` installable (`npm install -D cypress-image-snapshot`)
- Running application instance
- Stable, controlled environment (same OS, browser engine, fonts for consistent baselines)

## Notes

- Visual baselines are OS and browser engine dependent — always capture and compare on the same
  CI runner OS (Linux in CI, not macOS locally)
- Animations must be disabled during capture (`animations: 'disabled'`) to avoid flakiness
- Dynamic content (timestamps, user names, charts) must be masked before comparison
- Threshold of 0.1% is strict — start with 0.2-0.5% if there are many dynamic elements
- Commit baseline screenshots to git — they are the source of truth for visual contracts
- Update baselines intentionally when UI changes are approved — never auto-update in CI
