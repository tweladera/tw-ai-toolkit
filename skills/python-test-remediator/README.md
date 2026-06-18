# python-test-remediator

**Invocation:** `/tw-python-test-remediator`

Turns a Python test governance report into code. Reads `create-test` and `update-test`
decisions from a `/tw-python-test-governor` report, assigns coverage tiers, generates or
repairs test files, and produces a coverage summary table per module.

## Prerequisites

Run `/tw-python-test-governor` first. This skill requires a governance report as input.

## What it produces

- New `test_*.py` files for modules marked `create-test`
- Repaired test files for modules marked `update-test`
- Coverage summary table: module | tier | line % | meets target?
- List of modules that require manual review

## Coverage tiers

| Tier | Module type | Target |
|------|-------------|--------|
| A | Business logic, services, validators, processors | ≥ 90% |
| B | Adapters, parsers, retry logic, error handling | ≥ 80% |
| C | Thin helpers, simple facades | ≥ 70% |

## Full flow

```bash
# 1. Audit
/tw-python-test-governor base_ref=origin/main coverage_xml=coverage.xml

# 2. Remediate
/tw-python-test-remediator
```

## Supporting files

| File | Purpose |
|---|---|
| `references/coverage-targets.md` | Tier definitions and verification commands |
| `references/remediation-rules.md` | Rules per action type (create / update / review) |
| `references/test-generation-template.md` | pytest and unittest code templates |
| `scripts/parse_governance_report.sh` | Parses governance report into actionable targets |
