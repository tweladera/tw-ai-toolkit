---
name: ts-test-remediator
description: Consumes a TypeScript/NestJS test governance report, assigns Istanbul coverage tiers per module, then generates or updates maintainable Jest spec files to meet tiered line-coverage targets.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: report_file
    type: string
    required: false
    default: ""
    description: Path to the governance report produced by /tw-ts-test-governor. If omitted, Claude looks for the most recent TEST_GOVERNANCE_REPORT_*.md in the project root.
  - name: base_ref
    type: string
    required: false
    default: ""
    description: Git ref used by /tw-ts-test-governor (e.g. origin/master). Passed to the inventory script to regenerate the report when no report file is provided.
tags:
  - typescript
  - nestjs
  - jest
  - testing
  - coverage
  - qa
  - remediation
---

# ts-test-remediator

## Description

Turns a TypeScript/NestJS test governance report into code. Reads the output of
`/tw-ts-test-governor`, assigns an Istanbul coverage tier (A / B / C) to each module,
then generates new spec files (`create-test`) or repairs broken ones (`update-test`).
Runs the targeted tests after each change and produces a coverage summary table confirming
whether each module meets its tier target.

This skill is for remediation only — not for discovery. Run `/tw-ts-test-governor` first.

**Scope:** Only Jest unit tests (`*.spec.ts` colocated with production modules or under `__tests__/`).
Do not create or edit integration tests, shared fixtures, or test helpers unless explicitly requested.

## When to Use

Invoke this skill when:

- The governance report from `/tw-ts-test-governor` contains `create-test` or `update-test` decisions
- You want to turn a gap analysis into actual Jest spec code without doing it manually
- You need to repair broken specs caused by signature changes, new injected dependencies, or changed mock shapes
- You want an Istanbul coverage summary table per module after fixing tests

Do not invoke this skill before running `/tw-ts-test-governor`.

## Instructions

Follow these steps **in order**. Do not skip steps.

### Step 1 — Locate and Parse the Governance Report

If a `report_file` parameter is provided, read that file.
Otherwise, find the most recent `TEST_GOVERNANCE_REPORT_*.md` in the project root.

Then parse the actionable targets using the script:

```bash
bash .ai/toolkit/skills/ts-test-remediator/scripts/parse_governance_report.sh \
  TEST_GOVERNANCE_REPORT_YYYY-MM-DD_HH-MM-SS.md
```

The script outputs three action types:
- `create-test <production_module> <spec_file>` — new spec file needed
- `update-test <spec_file> <production_module> <spec_file> <reason>` — existing spec needs repair
- `review-test <spec_file> <production_module> <reason>` — ambiguous; requires manual analysis

If no governance report exists, regenerate it first:

```bash
npm run test:cov -- --coverage-reporters=json-summary || true
bash .ai/toolkit/skills/ts-test-governor/scripts/repo_test_inventory.sh \
  --base-ref origin/master \
  --coverage-summary coverage/coverage-summary.json \
  --test-results-dir test-results
```

### Step 2 — Assign Coverage Tiers

Before writing any test, assign a tier to each module. Use `references/coverage-targets.md`:

| Tier | Module type | Line coverage target |
|------|-------------|----------------------|
| **A** | Business logic, services, use cases, validators, mappers with branching | ≥ 90% |
| **B** | Adapters with transformation, parsing, retries, error handling, repository adapters | ≥ 80% |
| **C** | Thin helpers, simple controllers, low branching | ≥ 70% |

Do not apply tier targets to modules marked `no-test-needed` by the governor.

### Step 3 — Inspect Source Before Writing

For each module to remediate:

1. Read the production module — understand its public interface, branching logic, injected dependencies
2. Read the existing spec file (if any) — understand current patterns and what is broken
3. Read `package.json` and `jest.config.ts` — match framework and conventions

Do not generate tests based on file names alone.

### Step 4 — Apply Remediation Rules

Follow the rules in `references/remediation-rules.md` per action type.

#### For `create-test`

- Create `module-name.spec.ts` colocated with the production module (or under `__tests__/` if project uses that)
- Cover: happy path, branch/fallback path, error path (`expect(...).rejects.toThrow()`, `expect(() => ...).toThrow()`)
- Test public methods first; only test private logic if it has complex isolated behavior
- Use `it.each` for cases that share the same arrange/act shape
- Mock all injected dependencies with `jest.fn()` in `beforeEach`

#### For `update-test`

- Read the failing spec and the production module side by side
- Identify the mismatch: new injected dependency, changed method signature, new exception type, changed return shape
- Repair `beforeEach` mock setup before changing individual test assertions
- When all failures share one broken mock, fix that in `beforeEach` first
- Do not create a new spec file to mask a broken existing one

#### For `review-test`

- Explain the ambiguity — what evidence is missing
- Do not generate speculative code
- Mark in the output summary as `manual-review-needed`

### Step 5 — Apply Generation Standards

Use `references/test-generation-template.md` and `references/test-generation-standards.md` from
`.ai/toolkit/skills/ts-test-governor/`:

- Jest with `@nestjs/testing` (match project conventions)
- Arrange / Act / Assert pattern
- One behavior per test
- Descriptive names: `it('should [behavior] when [condition]')`
- Mock injected dependencies with `jest.fn()` in `beforeEach` — not the code under test
- Deterministic test data — no `Date.now()`, no `Math.random()`, no live network calls
- Specific assertions — not `expect(result).toBeTruthy()` but `expect(result.id).toBe(expected)`

### Step 6 — Verify After Each Module

After creating or updating a spec, run it:

```bash
npx jest src/module-name/module-name.spec.ts --verbose
```

If tests pass, run full coverage:

```bash
npm run test:cov
```

Record the Istanbul line coverage percentage vs the assigned tier target.
If jest --coverage cannot be run, mark as `not verified` and state the reason.

### Step 7 — Produce Remediation Summary

1. **Action summary** — count of `create-test`, `update-test`, `review-test` processed
2. **Targets selected** — list of modules with assigned tier
3. **Files created or updated** — exact file paths
4. **Verification** — test commands run and pass/fail result
5. **Coverage summary table**:

```markdown
| Module | Tier | Line coverage (after) | Meets target? | Notes |
|--------|------|----------------------|---------------|-------|
| `src/orders/orders.service.ts` | A | 93% | ✅ Yes | All branches covered |
| `src/payment/payment.mapper.ts` | B | 78% | ⚠️ No (80%) | HTTP error path needs integration test |
```

6. **Remaining manual reviews** — modules marked `review-test` with explanation

## Examples

### Example 1 — Remediate from latest governance report

```
/tw-ts-test-remediator
```

### Example 2 — Remediate from a specific report file

```
/tw-ts-test-remediator report_file=TEST_GOVERNANCE_REPORT_2026-06-18_10-30-00.md
```

### Example 3 — Full governance + remediation flow

```
# Step 1: audit
/tw-ts-test-governor base_ref=origin/master coverage_summary=coverage/coverage-summary.json

# Step 2: remediate
/tw-ts-test-remediator
```

## Dependencies

- Output from `/tw-ts-test-governor` (governance report file)
- Node.js and npm in PATH
- `ripgrep` (`rg`) installed — required by the parse script
- `jest` and `@nestjs/testing` in project dependencies
- Script at `.ai/toolkit/skills/ts-test-remediator/scripts/parse_governance_report.sh`
- Reference files at `.ai/toolkit/skills/ts-test-remediator/references/`
- Shared standards at `.ai/toolkit/skills/ts-test-governor/references/test-generation-standards.md`
