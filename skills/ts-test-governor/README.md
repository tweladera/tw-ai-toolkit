# ts-test-governor

**Invocation:** `/tw-ts-test-governor`

Audits Jest unit test coverage in a TypeScript/NestJS repository. Maps every production module to
its spec file status, classifies gaps by severity (CRITICAL / HIGH / MEDIUM / LOW), determines the
correct action per module (`create-test` / `update-test` / `no-change` / `no-test-needed`), and
outputs a structured governance report with prioritized recommendations.

## Prerequisites

- Node.js and npm in PATH
- `ripgrep` (`rg`) installed
- `jest` and `@nestjs/testing` in project dependencies

## What it produces

- `TEST_GOVERNANCE_REPORT_YYYY-MM-DD_HH-MM-SS.md` — structured governance report in project root
- Findings table with severity and action per module
- Impacted modules table with test status and decision
- Coverage summary per module (when `--coverage-reporters=json-summary` is used)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `base_ref` | No | Git ref to diff against (e.g. `origin/master`) |
| `coverage_summary` | No | Path to `coverage/coverage-summary.json` |
| `test_results_dir` | No | Directory with Jest JUnit XML output |

## Full flow

```bash
# Full audit
/tw-ts-test-governor

# Diff-focused audit on a PR branch
/tw-ts-test-governor base_ref=origin/master coverage_summary=coverage/coverage-summary.json
```

## Supporting files

| File | Purpose |
|------|---------|
| `scripts/repo_test_inventory.sh` | Generates test inventory and module map |
| `references/analysis-guide.md` | Severity and decision classification rules |
| `references/output-template.md` | Report template with 7 required sections |
| `references/test-generation-standards.md` | Jest/NestJS test generation standards |
| `references/ci-gating-rules.md` | CI integration and PR gating guidance |
| `references/example-report.md` | Complete example governance report |
