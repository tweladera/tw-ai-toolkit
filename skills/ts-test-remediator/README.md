# ts-test-remediator

**Invocation:** `/tw-ts-test-remediator`

Turns a TypeScript/NestJS test governance report into code. Reads `create-test` and `update-test`
decisions from a `/tw-ts-test-governor` report, assigns Istanbul coverage tiers per module,
generates or repairs `*.spec.ts` files, and produces a coverage summary table per module.

## Prerequisites

Run `/tw-ts-test-governor` first. This skill requires a governance report as input.

## What it produces

- New `*.spec.ts` files for modules marked `create-test` (colocated with production module)
- Repaired spec files for modules marked `update-test`
- Coverage summary table: module | tier | line % | meets target?
- List of modules that require manual review

## Coverage tiers

| Tier | Module type | Target |
|------|-------------|--------|
| A | Business logic, services, use cases, validators, mappers | ≥ 90% |
| B | Adapters, parsers, retry logic, error handling | ≥ 80% |
| C | Thin helpers, simple controllers | ≥ 70% |

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `report_file` | No | Path to governance report. Defaults to most recent `TEST_GOVERNANCE_REPORT_*.md` |
| `base_ref` | No | Git ref to regenerate the report if none exists |

## Full flow

```bash
# 1. Audit
/tw-ts-test-governor base_ref=origin/master coverage_summary=coverage/coverage-summary.json

# 2. Remediate
/tw-ts-test-remediator
```

## Supporting files

| File | Purpose |
|------|---------|
| `scripts/parse_governance_report.sh` | Parses governance report into actionable targets |
| `references/coverage-targets.md` | Tier definitions and verification commands |
| `references/remediation-rules.md` | Rules per action type (create / update / review) |
| `references/test-generation-template.md` | Jest/NestJS spec code templates |
