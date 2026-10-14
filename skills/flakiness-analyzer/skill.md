---
name: flakiness-analyzer
description: Analyzes CI test run history to identify non-deterministic (flaky) tests, classifies them by failure pattern and frequency, and produces a remediation plan. Restores developer trust in the test suite by distinguishing real failures from environmental noise.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: source
    type: string
    required: false
    default: "junit-xml"
    description: "Source of test history: 'junit-xml' (reads test-results/ directory) or 'github-actions' (reads via GitHub MCP) or 'gitlab-ci' (reads via GitLab API)."
  - name: results_dir
    type: string
    required: false
    default: "test-results"
    description: "Directory containing JUnit XML test result files from multiple CI runs. Used when source=junit-xml."
  - name: threshold
    type: number
    required: false
    default: 10
    description: "Minimum flakiness rate (%) to flag a test as flaky. Default: 10 (fails in 10% of runs with the same code)."
  - name: window
    type: string
    required: false
    default: "30d"
    description: "Time window for analysis: '7d', '30d', '90d'. Longer windows surface intermittent flakiness."
tags:
  - flakiness
  - test-reliability
  - ci-cd
  - quality
  - qa
invocation: tw-flakiness-analyzer
---

# flakiness-analyzer

## Description

Identifies tests that fail non-deterministically — same code, same environment, different results.
Flaky tests are the silent killer of engineering velocity: when developers stop trusting the
test suite, they ignore failures, rerun pipelines blindly, and merge broken code.

**Flakiness sources detected:**
- Timing and async issues (race conditions in async code, missing waits)
- Test order dependency (test A leaves state that breaks test B)
- Environment coupling (hardcoded ports, external services, clock dependencies)
- Resource contention (parallel tests writing to the same file/DB table)
- Data pollution (tests not cleaning up after themselves)

**What this skill does NOT do:** It does not run tests. It analyzes the history of past runs
to identify patterns that indicate flakiness rather than real failures.

## When to Use

- When the team is rerunning CI pipelines without understanding why tests fail
- After a test suite refactor or new test additions that introduced instability
- Before a release: verify which failures in CI are real vs noise
- Periodically (monthly) to catch accumulating flakiness before it erodes trust

Triggers: "why do these tests keep failing randomly", "how many flaky tests do we have",
"CI is unreliable", "tests pass locally but fail in CI".

## Instructions

### Step 1 — Locate Test Result History

**source=junit-xml (default):**

Look for JUnit XML result files from multiple runs:
```bash
find test-results/ -name "*.xml" -newer /dev/null | head -50
find . -path "*/test-results/*.xml" -o -path "*/reports/tests/*.xml" | head -50
```

JUnit XML files must be from multiple runs of the same codebase to detect flakiness.
A single run cannot reveal flakiness — you need at least 5 runs to detect a 20% flakiness rate.

If only 1 run is found:
```
Warning: Only 1 test result file found. Cannot detect flakiness from a single run.
Recommendation: Configure CI to archive test results as artifacts and run this skill
after accumulating at least 10 runs (use /tw-pipeline-generator to set up artifact archiving).
```

**source=github-actions:**

Use the GitHub MCP server (tw-github) to fetch recent workflow run results:
```
List recent runs of the quality workflow
For each run: fetch test result artifacts
Build multi-run result history
```

**source=gitlab-ci:**

Fetch pipeline job logs and test reports from GitLab API.

### Step 2 — Parse Test Results

For each JUnit XML file, extract:
- Run identifier (timestamp, commit SHA if available)
- Per-test result: pass / fail / skip
- Failure message (for pattern analysis)
- Duration (for timeout pattern detection)

Group results by test name across runs:
```
test: "OrderService should calculate total"
  run-001: PASS (0.23s)
  run-002: PASS (0.21s)
  run-003: FAIL (0.18s) — AssertionError: expected 150 but got 0
  run-004: PASS (0.24s)
  run-005: FAIL (0.19s) — AssertionError: expected 150 but got 0
  → flakiness rate: 40%
```

### Step 3 — Classify Flakiness Patterns

For each flaky test, analyze the failure message and timing to classify the cause:

| Pattern | Symptoms | Root cause category |
|---|---|---|
| **Timing / async** | Fails with timeout, "element not found", or assertion fails on intermittent race | Missing await, race condition, hardcoded wait too short |
| **Order dependency** | Fails in parallel runs but passes alone, or always after specific test | Test leaves shared state (DB, file, global variable) |
| **Environment** | Fails only in CI, always passes locally | Hardcoded localhost, port conflicts, missing env vars |
| **Resource contention** | Fails when parallel workers > 1, error involves file/DB lock | Tests writing to shared resources concurrently |
| **Data pollution** | Failure references stale data from previous run | Missing teardown / cleanup after test |
| **Non-deterministic input** | Uses `Date.now()`, `Math.random()`, UUIDs in assertions | Test data not controlled |
| **External dependency** | Fails when external service is slow or unavailable | Real network call inside unit test |

### Step 4 — Score and Rank

For each test, compute:
- **Flakiness rate**: `failures / total_runs × 100`
- **Impact score**: `flakiness_rate × criticality` where criticality = 3 (unit/critical path), 2 (integration), 1 (E2E)
- **Pattern confidence**: HIGH (clear symptom), MEDIUM (partial), LOW (unknown)

Only report tests above `threshold` flakiness rate.

### Step 5 — Generate Flakiness Report

```markdown
# Test Flakiness Analysis Report

**Generated:** YYYY-MM-DD
**Skill:** /tw-flakiness-analyzer | v0.4.0
**Runs analyzed:** N (window: {{window}})
**Threshold:** {{threshold}}% failure rate
**Total flaky tests identified:** X

## Summary

| Severity | Count | Pattern |
|---|---|---|
| CRITICAL (>50% flaky) | 2 | Timing/async (1), Order dependency (1) |
| HIGH (20–50% flaky) | 5 | Data pollution (3), Environment (2) |
| MEDIUM (10–20% flaky) | 8 | Non-deterministic input (5), External dep (3) |

**Estimated CI reliability without flaky tests:** 94% → with fix: 99.2%

## Flaky Tests — Ranked by Impact

### CRITICAL

#### `OrderService should calculate discount`
- **Flakiness rate:** 67% (8/12 runs failed)
- **Pattern:** Order dependency — fails when run after `PaymentService` tests
- **Evidence:** Always fails in parallel mode, never in isolation
- **Root cause:** `PaymentService` test modifies shared `discountConfig` singleton
- **Fix:** Add `afterEach` to reset `discountConfig` in `PaymentService.spec.ts`

#### `[test name]`
[same structure]

### HIGH
[...]

## Remediation Plan

| Priority | Test | Pattern | Fix effort | Recommended action |
|---|---|---|---|---|
| 1 | OrderService.discount | Order dependency | Low | Add afterEach cleanup in PaymentService.spec.ts |
| 2 | LoginFlow.e2e | Timing/async | Medium | Replace cy.wait(2000) with cy.intercept alias |
| 3 | PricingEngine.calc | Non-deterministic | Low | Replace Date.now() with fixed date in test |

## Tests Incorrectly Assumed Flaky

The following tests failed consistently (>80% failure rate) — these are likely REAL failures,
not flakiness. Do not rerun — investigate the root cause:

| Test | Failure rate | Consistent error |
|---|---|---|
| `CheckoutService.process` | 100% | TypeError: Cannot read properties of undefined |
```

### Step 6 — Save Report

```bash
filename="FLAKINESS_REPORT_$(date +%Y-%m-%d_%H-%M-%S).md"
```

## Examples

### Example 1 — Analyze local JUnit XML history

```
/tw-flakiness-analyzer source=junit-xml results_dir=test-results/
```

### Example 2 — GitHub Actions history (last 30 days)

```
/tw-flakiness-analyzer source=github-actions window=30d threshold=15
```

### Example 3 — Pre-release flakiness audit

```
/tw-flakiness-analyzer window=7d threshold=5
```

Stricter threshold (5%) to catch even low-frequency flakiness before release.

## Dependencies

- JUnit XML test result files from multiple CI runs OR GitHub MCP server (tw-github)
- Minimum 5 test runs to detect meaningful flakiness
- `ripgrep` for scanning result files

## Notes

- A test with 100% failure rate is NOT flaky — it is broken. Investigate separately.
- Flakiness analysis requires historical data — start archiving test results in CI immediately
- The most impactful fix is usually order dependency — a shared mutable singleton in tests
- E2E tests are inherently more flaky than unit tests — apply a higher threshold (15-20%) for E2E
