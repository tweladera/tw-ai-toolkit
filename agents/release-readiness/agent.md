---
name: release-readiness
description: Autonomous agent that orchestrates all quality gates — unit coverage, mutation score, flakiness, performance, accessibility, security, visual regression, and contract tests — and produces a single GO / NO-GO decision with a full evidence matrix. The consolidated release quality checkpoint.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: stack
    type: string
    required: false
    default: ""
    description: "Tech stack: 'typescript', 'python', 'java', 'multi'. Auto-detected."
  - name: gates
    type: string
    required: false
    default: "all"
    description: "Comma-separated quality gates to check: coverage, mutation, flakiness, performance, a11y, security, visual, contracts. Default: all."
  - name: coverage_threshold
    type: number
    required: false
    default: 70
    description: "Minimum line coverage % for Tier-A modules. Default: 70%."
  - name: mutation_threshold
    type: number
    required: false
    default: 70
    description: "Minimum mutation score % for Tier-A modules. Default: 70%."
  - name: environment
    type: string
    required: false
    default: "staging"
    description: "Environment to validate against: 'local', 'staging', 'production'. Affects which gates are run."
tags:
  - release
  - quality-gate
  - autonomous
  - go-no-go
  - governance
  - qa
invocation: tw-release-readiness
---

# release-readiness

## Description

Before any deployment, someone must answer: **"Is this safe to release?"**

Without a systematic approach, this question gets answered by gut feel, meeting discussion,
or the absence of loud objections. With `release-readiness`, it gets answered by evidence.

This agent orchestrates every quality gate the toolkit provides, runs the checks that are
possible given the current state of the project, collects the results, and produces a
**GO / NO-GO decision** backed by a complete evidence matrix.

**What it checks (configurable):**

| Gate | Tool used | Blocks release if |
|---|---|---|
| Unit coverage | governor (TS/Python/Java) | Tier-A < threshold |
| Mutation score | mutation-audit | Score < 70% |
| Flaky tests | flakiness-analyzer | Any CRITICAL flaky test |
| Performance | performance-baseline | Any P95 regression > 20% |
| Accessibility | a11y-audit | Any WCAG AA critical violation |
| Security | security-audit | Any CVSS ≥ 7.0 finding |
| Visual regression | visual-baseline | Any diff > threshold |
| Contract tests | contract-coverage | Any missing critical contract |

**For the consultant:** Run this before every release demo with the client. Walk through
the evidence matrix together. This is how you teach the team what "quality" means
in measurable terms.

## When to Use

- Before any deployment to staging or production
- During a sprint demo — run first to show the quality evidence
- When the client asks "can we release today?" — this is the answer
- As the final step in any CI/CD pipeline before deployment approval

Triggers: "can we release?", "is this ready to deploy", "release check",
"quality gate", "go/no-go", "pre-release validation".

## Agent Instructions

### Phase 1 — Inventory and Stack Detection

Before running any gates, inventory what is available:

```bash
# Coverage reports
ls coverage/coverage-summary.json coverage.xml target/site/jacoco/jacoco.xml 2>/dev/null

# Performance baselines
ls .performance/baseline-summary.json 2>/dev/null

# Visual baselines
ls tests/visual/__snapshots__/ 2>/dev/null | wc -l

# Test results (for flakiness)
ls test-results/*.xml junit*.xml 2>/dev/null

# Security findings from previous scan
ls SECURITY_AUDIT_*.md 2>/dev/null | sort -r | head -1
```

For each gate, determine:
- **RUNNABLE** — required data/tools are available → run the check
- **SKIPPABLE** — no baseline or prior data exists → report as "NOT ESTABLISHED" (not a block)
- **BLOCKED** — prerequisite missing and gate is mandatory → flag immediately

### Phase 2 — Run Quality Gates

Run gates in order of speed (fast gates first to fail early):

#### Gate 1 — Unit Coverage

```bash
# TypeScript
cat coverage/coverage-summary.json | python3 -c "
import sys,json
d=json.load(sys.stdin)
t=d.get('total',{})
pct=t.get('lines',{}).get('pct',0)
print(f'Coverage: {pct}%')
print('PASS' if pct >= {{coverage_threshold}} else 'FAIL')
"

# Python
# Parse coverage.xml for line-rate
# Java
# Parse jacoco.xml for LINE counter
```

Decision: **PASS** if Tier-A modules meet threshold. **FAIL** if any Tier-A module is below.

#### Gate 2 — Mutation Score

Read the most recent `MUTATION_REPORT_*.md`:
```bash
ls MUTATION_REPORT_*.md 2>/dev/null | sort -r | head -1 | xargs grep "Overall score" 2>/dev/null
```

Decision: **PASS** if overall score ≥ {{mutation_threshold}}%. **NOT ESTABLISHED** if no report.

#### Gate 3 — Flakiness

Read the most recent `FLAKINESS_REPORT_*.md`:
```bash
ls FLAKINESS_REPORT_*.md 2>/dev/null | sort -r | head -1 | xargs grep "CRITICAL" 2>/dev/null
```

Decision: **PASS** if no CRITICAL flaky tests. **WARN** if HIGH flaky tests exist. **NOT ESTABLISHED** if no report.

#### Gate 4 — Performance Regression

```bash
# Compare current vs baseline
ls .performance/baseline-summary.json .performance/current-summary.json 2>/dev/null
python3 -c "
import json
with open('.performance/baseline-summary.json') as f: baseline = json.load(f)
with open('.performance/current-summary.json') as f: current = json.load(f)
for endpoint in baseline.get('endpoints', {}):
    base_p95 = baseline['endpoints'][endpoint]['p95_ms']
    curr_p95 = current['endpoints'].get(endpoint, {}).get('p95_ms', 0)
    delta = ((curr_p95 - base_p95) / base_p95 * 100) if base_p95 > 0 else 0
    status = 'REGRESSION' if delta > 20 else 'OK'
    print(f'{status}: {endpoint} — baseline {base_p95}ms, current {curr_p95}ms ({delta:+.0f}%)')
" 2>/dev/null
```

Decision: **PASS** if no endpoint has P95 > 20% above baseline. **NOT ESTABLISHED** if no baseline.

#### Gate 5 — Accessibility

Read the most recent `A11Y_AUDIT_REPORT_*.md`:
```bash
ls A11Y_AUDIT_REPORT_*.md 2>/dev/null | sort -r | head -1 | \
  xargs grep "Critical.*[1-9]" 2>/dev/null
```

Decision: **PASS** if 0 critical violations. **FAIL** if any critical violations found.

#### Gate 6 — Security

Read the most recent `SECURITY_AUDIT_*.md`:
```bash
ls SECURITY_AUDIT_*.md 2>/dev/null | sort -r | head -1 | \
  xargs grep "CRITICAL\|HIGH.*CVE\|CVSS.*[7-9]\|CVSS.*10" 2>/dev/null
```

Decision: **PASS** if no CRITICAL or HIGH unresolved findings. **FAIL** if any exist.

#### Gate 7 — Visual Regression

```bash
ls tests/visual/__snapshots__/ 2>/dev/null | wc -l
ls tests/visual/*-diff.png 2>/dev/null | wc -l  # diff images = failures
```

Decision: **PASS** if 0 diff images. **NOT ESTABLISHED** if no baseline snapshots.

#### Gate 8 — Contract Tests

Read the most recent `CONTRACT_COVERAGE_REPORT_*.md`:
```bash
ls CONTRACT_COVERAGE_REPORT_*.md 2>/dev/null | sort -r | head -1 | \
  xargs grep "CRITICAL.*missing\|HIGH.*missing" 2>/dev/null
```

Decision: **PASS** if no CRITICAL/HIGH missing contracts. **NOT ESTABLISHED** if no report.

### Phase 3 — Generate GO / NO-GO Report

```markdown
# Release Readiness Report

**Project:** {{project_name}}
**Date:** YYYY-MM-DD HH:MM
**Environment:** staging
**Agent:** /tw-release-readiness | v0.5.0

---

## DECISION: ❌ NO-GO

**2 blocking issues found.** Release must not proceed until resolved.

---

## Evidence Matrix

| Gate | Status | Detail |
|---|---|---|
| Unit Coverage (Tier-A) | ❌ FAIL | OrderService: 54% (threshold: 70%) |
| Mutation Score | ✅ PASS | 74% — above 70% threshold |
| Flaky Tests | ⚠️ WARN | 2 HIGH flaky tests (non-blocking, but address soon) |
| Performance | ✅ PASS | All endpoints within 20% of baseline |
| Accessibility | ✅ PASS | 0 WCAG 2.1 AA critical violations |
| Security | ❌ FAIL | CVE-2021-23337 (CVSS 7.2) — lodash unpatched |
| Visual Regression | ✅ PASS | 0 pixel diff failures |
| Contract Tests | ⚪ NOT ESTABLISHED | No baseline — run /tw-contract-coverage first |

---

## Blocking Issues — Must Resolve Before Release

### 1. Unit Coverage — OrderService Below Threshold

**Current:** 54% line coverage
**Required:** 70% (Tier-A threshold)
**Gap:** 16 percentage points

**Fastest fix:**
```
/tw-ts-test-remediator  # or /tw-quality-sprint for autonomous fix
```

### 2. Security — Unpatched Vulnerability (CVSS 7.2)

**Package:** lodash 4.17.15
**CVE:** CVE-2021-23337 — Prototype Pollution
**Fix:**
```bash
npm install lodash@4.17.21
npm audit  # verify resolved
```

---

## Warnings — Not Blocking, But Address Soon

### Flaky Tests (2 HIGH severity)

- `OrderService > should process order within timeout` — fails 23% of runs
- `AuthService > should handle concurrent logins` — fails 18% of runs

**Fix:** `/tw-flakiness-analyzer source=junit-xml` for detailed remediation

### Contract Tests Not Established

No contract coverage baseline exists. Once established, missing critical contracts
will become a blocking gate.

**Fix:** `/tw-contract-coverage mode=generate`

---

## Gates Not Yet Established

These gates will be added to future release checks once baselines are created:

- Contract Tests — run `/tw-contract-coverage` to establish
- (All other gates: ✅ established and passing)

---

## When This Becomes GO

1. Fix lodash CVE: `npm install lodash@4.17.21`
2. Increase OrderService coverage to 70%: `/tw-quality-sprint`
3. Re-run this check: `/tw-release-readiness`

**Estimated resolution time:** 2-4 hours (lodash: 15 min, coverage: 2-3h)

---

## What Was Checked

| Gate | Data source | Last updated |
|---|---|---|
| Coverage | coverage/coverage-summary.json | 2026-10-14 14:32 |
| Mutation | MUTATION_REPORT_2026-10-01.md | 2026-10-01 |
| Flakiness | FLAKINESS_REPORT_2026-10-10.md | 2026-10-10 |
| Performance | .performance/current-summary.json | 2026-10-14 09:15 |
| Accessibility | A11Y_AUDIT_REPORT_2026-10-12.md | 2026-10-12 |
| Security | SECURITY_AUDIT_2026-10-13.md | 2026-10-13 |
| Visual | tests/visual/__snapshots__/ | 2026-10-14 14:30 |
```

---

**GO output (all gates pass):**

```markdown
# Release Readiness Report

## DECISION: ✅ GO

All quality gates pass. This build is ready for deployment to staging.

## Evidence Matrix

| Gate | Status | Detail |
|---|---|---|
| Unit Coverage | ✅ PASS | OrderService: 82%, all Tier-A ≥ 70% |
| Mutation Score | ✅ PASS | 76% — above threshold |
| Flaky Tests | ✅ PASS | 0 CRITICAL, 0 HIGH flaky tests |
| Performance | ✅ PASS | All endpoints within baseline |
| Accessibility | ✅ PASS | 0 critical violations |
| Security | ✅ PASS | No CVSS ≥ 7.0 findings |
| Visual Regression | ✅ PASS | 0 pixel diff failures |
| Contract Tests | ✅ PASS | All critical contracts covered |

**Deployment approved:** YYYY-MM-DD HH:MM by /tw-release-readiness v0.5.0
```

## Examples

### Example 1 — Full release check before staging deployment

```
/tw-release-readiness
```

### Example 2 — Coverage and security only (fast check)

```
/tw-release-readiness gates=coverage,security
```

### Example 3 — Strict thresholds for critical system

```
/tw-release-readiness coverage_threshold=85 mutation_threshold=80
```

### Example 4 — Local environment check (skip performance and visual)

```
/tw-release-readiness environment=local gates=coverage,mutation,security
```

## Dependencies

- Existing report files from other toolkit skills (coverage, mutation, flakiness, etc.)
- For gates marked NOT ESTABLISHED: run the relevant skill first to create the baseline
- Security gate requires at least one `/tw-security-audit` run within the last 7 days

## Notes

- NOT ESTABLISHED is not a failure — it means no baseline exists yet; run the corresponding skill first
- The first time this agent runs on a new project, most gates will be NOT ESTABLISHED — that's expected
- WARN status does not block release but should be tracked and resolved within 1-2 sprints
- This agent reads existing reports — it does not re-run all tests (too slow for pre-release)
- For a fresh evidence basis, run all relevant skills the day before the release check
- Pair with `/tw-quality-trend` to see whether the quality posture is improving over time
