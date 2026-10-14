---
name: mutation-audit
description: Runs mutation testing (Stryker for TypeScript/JavaScript, mutmut for Python) on tier-A modules identified by the test governor, and produces a mutation score report revealing tests that pass but don't actually catch bugs.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: modules
    type: string
    required: false
    default: ""
    description: "Comma-separated paths to modules to mutate. If omitted, reads tier-A modules from the latest TEST_GOVERNANCE_REPORT_*.md."
  - name: framework
    type: string
    required: false
    default: ""
    description: "Mutation framework: 'stryker' (TypeScript/JS) or 'mutmut' (Python). Auto-detected from project."
  - name: timeout
    type: number
    required: false
    default: 300
    description: "Timeout in seconds per module. Mutation testing is slow — default 5 minutes per module."
  - name: threshold
    type: number
    required: false
    default: 70
    description: "Minimum acceptable mutation score (%). Below this threshold the report flags a quality debt warning."
tags:
  - mutation-testing
  - stryker
  - mutmut
  - test-quality
  - qa
invocation: tw-mutation-audit
---

# mutation-audit

## Description

Proves whether your tests actually catch bugs by introducing deliberate code mutations
(changing `>` to `>=`, removing a condition, replacing a return value) and verifying that
at least one test fails for each mutation. Tests that let mutations survive are tests that
would also let real bugs through.

**Why this matters:** Coverage % tells you which lines were executed. Mutation score tells
you which lines are actually verified by assertions. An 80% coverage project can have a 30%
mutation score — meaning 70% of the code could have bugs that no test would catch.

**Scope:** Mutation testing is computationally expensive. This skill focuses on **tier-A modules**
(business logic, services, validators, domain entities) — not thin controllers or config files.
Running mutation testing on everything is impractical; running it on what matters is essential.

## When to Use

- After `quality-sprint` completes and coverage targets are met — verify the tests are real
- Before a major release: prove the test suite can actually catch the bugs you care about
- When a bug slips to production despite high test coverage — root cause is test quality
- Monthly as part of a quality trend review

Triggers: "check if our tests are meaningful", "mutation testing", "test quality audit",
"our coverage is high but bugs keep reaching production".

## Instructions

### Step 1 — Identify Target Modules

If `modules` parameter is provided, use those paths.

Otherwise, read the latest governance report:
```bash
ls TEST_GOVERNANCE_REPORT_*.md | tail -1
```

Extract tier-A modules (marked in the remediator coverage targets):
- Business logic services
- Domain entities with complex logic
- Validators, transformers, mappers with branching
- Use cases / application services

**Cap at 10 modules per run** — mutation testing is slow. Priority order:
1. Modules with the most recent changes (git diff)
2. Modules that previously had failing tests
3. Modules with the highest complexity (cyclomatic complexity if detectable)

### Step 2 — Configure and Run Stryker (TypeScript)

Check for existing Stryker config:
```bash
ls stryker.config.* .strykerrc.* 2>/dev/null
```

If no config exists, generate a minimal one targeting only the selected modules:

```javascript
// stryker.config.mjs (generated)
/** @type {import('@stryker-mutator/api/core').PartialStrykerOptions} */
export default {
  testRunner: 'jest',
  coverageAnalysis: 'perTest',
  mutate: [
    // Tier-A modules from governance report
    'src/orders/orders.service.ts',
    'src/pricing/pricing.engine.ts',
    // Add more here
  ],
  jest: {
    projectType: 'custom',
    configFile: 'jest.config.ts',
  },
  thresholds: {
    high: {{threshold}},
    low: 60,
    break: 0,   // don't fail the build — report only
  },
  reporters: ['html', 'json', 'clear-text'],
  htmlReporter: { fileName: 'reports/mutation/index.html' },
  jsonReporter: { fileName: 'reports/mutation/report.json' },
  timeoutMS: {{timeout}} * 1000,
  timeoutFactor: 1.5,
  disableBail: true,
};
```

Run:
```bash
npx stryker run stryker.config.mjs 2>&1 | tee mutation-output.txt
```

### Step 3 — Configure and Run mutmut (Python)

```bash
mutmut run \
  --paths-to-mutate $(echo {{modules}} | tr ',' ' ') \
  --runner "python -m pytest --timeout=30 -x -q" \
  --dict-synonyms \
  2>&1 | tee mutation-output.txt

mutmut results > mutation-results.txt
mutmut junitxml > reports/mutation/results.xml
```

### Step 4 — Parse and Classify Mutants

For each module, classify surviving mutants:

**Killed mutant** — at least one test detected the change → the test is meaningful for this line.

**Survived mutant** — no test failed → this change would reach production undetected.
Classify surviving mutants by type:
- **Boundary mutation** (e.g. `>` → `>=`): off-by-one bugs — highest risk
- **Conditional removal** (e.g. `if (isValid)` → `if (true)`): logic bypass — critical risk
- **Return value** (e.g. `return result` → `return undefined`): silent failure — high risk
- **Arithmetic** (e.g. `a + b` → `a - b`): calculation bugs — high risk
- **String literal** (e.g. `"ERROR"` → `""`): cosmetic — low risk

**Timeout mutant** — mutation caused an infinite loop. Usually indicates a missing guard clause.

### Step 5 — Generate Mutation Score Report

```markdown
# Mutation Audit Report

**Generated:** YYYY-MM-DD
**Skill:** /tw-mutation-audit | v0.4.0
**Framework:** [stryker|mutmut]
**Threshold:** {{threshold}}%

## Summary

| Module | Coverage % | Mutation Score | Status | Survived | Killed | Timeout |
|---|---|---|---|---|---|---|
| orders.service.ts | 92% | 78% | ⚠️ Below threshold | 4 | 14 | 1 |
| pricing.engine.ts | 88% | 91% | ✅ Healthy | 1 | 11 | 0 |
| payment.mapper.ts | 95% | 45% | 🔥 Critical gap | 9 | 7 | 2 |

**Overall mutation score:** 71%
**Status:** ⚠️ Below threshold ({{threshold}}%)

## Critical Surviving Mutants — Fix These First

### payment.mapper.ts — Score: 45% (CRITICAL)

The following mutations survived — meaning your tests would NOT catch these real bugs:

| Line | Original | Mutation | Type | Risk |
|---|---|---|---|---|
| 34 | `amount > 0` | `amount >= 0` | Boundary | CRITICAL — zero amount would pass |
| 47 | `if (currency)` | `if (true)` | Conditional removal | HIGH — empty currency silently accepted |
| 62 | `return mapped` | `return undefined` | Return value | HIGH — silent null propagation |
| 71 | `status === 'ACTIVE'` | `status === ''` | String comparison | MEDIUM |

**What this means:** A payment with `amount = 0` would be accepted by your validation.
A test that calls `validatePayment({ amount: 0 })` and asserts it is rejected would kill this mutant.

## Mutation Score Trend

| Date | Score | Delta |
|---|---|---|
| (previous) | 68% | — |
| Today | 71% | +3% ↑ |

## Recommended Actions

**Immediate (CRITICAL surviving mutants):**
For each critical surviving mutant, add a specific test case:

\`\`\`typescript
// Add to payment.mapper.spec.ts
it('should reject payment with zero amount', () => {
  const invalidPayment = { amount: 0, currency: 'USD' };
  expect(() => mapPayment(invalidPayment)).toThrow('Amount must be positive');
});

it('should reject payment with missing currency', () => {
  const invalidPayment = { amount: 100, currency: '' };
  expect(() => mapPayment(invalidPayment)).toThrow('Currency is required');
});
\`\`\`

**Medium term:**
- Run mutation audit monthly on tier-A modules
- Set mutation score gate in CI at {{threshold}}% (see /tw-pipeline-generator)
- Target: reach 80% mutation score across all tier-A modules within 2 sprints
```

### Step 6 — Save Report

```bash
filename="MUTATION_REPORT_$(date +%Y-%m-%d_%H-%M-%S).md"
```

## Examples

### Example 1 — Audit tier-A modules from latest governance report

```
/tw-mutation-audit
```

### Example 2 — Target specific modules

```
/tw-mutation-audit modules=src/orders/orders.service.ts,src/pricing/pricing.engine.ts framework=stryker
```

### Example 3 — Strict pre-release audit

```
/tw-mutation-audit threshold=80 timeout=600
```

## Dependencies

- Latest `TEST_GOVERNANCE_REPORT_*.md` (from `/tw-ts-test-governor` or `/tw-python-test-governor`)
- **TypeScript:** `@stryker-mutator/core` and `@stryker-mutator/jest-runner` installable
- **Python:** `mutmut` installable (`pip install mutmut`)
- Existing test suite that can be run by Jest or pytest
- CI runners with sufficient CPU (mutation testing is 10-50x slower than normal test runs)

## Notes

- Never run mutation testing on the full codebase in PR pipelines — it is too slow
- Reserve mutation testing for nightly jobs or on-demand for critical modules
- A mutation score below 50% on a tier-A module means the tests are essentially decorative
- Surviving string literal mutations are usually acceptable — focus on logic and boundary mutations
- Timeout mutants are not always bad — investigate if the timeout indicates a real issue
