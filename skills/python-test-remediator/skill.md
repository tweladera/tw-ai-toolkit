---
name: python-test-remediator
description: Consumes a Python test governance report, assigns coverage tiers per module, then generates or updates maintainable pytest and unittest tests to meet tiered line-coverage targets.
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
    description: Path to the governance report file produced by /tw-python-test-governor. If omitted, Claude will look for the most recent TEST_GOVERNANCE_REPORT_*.md in the project root.
  - name: base_ref
    type: string
    required: false
    default: ""
    description: Git ref used by /tw-python-test-governor (e.g. origin/main). Passed to the inventory script to regenerate the report when no report file is provided.
tags:
  - python
  - testing
  - coverage
  - qa
  - remediation
---

# python-test-remediator

## Description

Turns a Python test governance report into code. Reads the output of `/tw-python-test-governor`,
assigns a coverage tier (A / B / C) to each module, then generates new test files (`create-test`)
or repairs broken ones (`update-test`). Runs the targeted tests after each change and produces
a coverage summary table confirming whether each module meets its tier target.

This skill is for remediation only — not for discovery. Run `/tw-python-test-governor` first.

## When to Use

Invoke this skill when:

- The governance report from `/tw-python-test-governor` contains `create-test` or `update-test` decisions
- You want to turn a gap analysis into actual test code without doing it manually
- You need to repair broken tests caused by signature changes, new dependencies, or changed exception flows
- You want a coverage summary table per module after fixing tests

Do not invoke this skill before running `/tw-python-test-governor` — the remediator requires
a structured governance report as input.

## Instructions

Follow these steps **in order**. Do not skip steps.

### Step 1 — Locate and Parse the Governance Report

If a `report_file` parameter is provided, read that file.
Otherwise, find the most recent `TEST_GOVERNANCE_REPORT_*.md` in the project root.

Then parse the actionable targets using the script:

```bash
bash .ai/toolkit/skills/python-test-remediator/scripts/parse_governance_report.sh \
  TEST_GOVERNANCE_REPORT_YYYY-MM-DD_HH-MM-SS.md
```

The script outputs three action types:
- `create-test <production_module> <test_file>` — new test file needed
- `update-test <test_module> <production_module> <test_file> <reason>` — existing test needs repair
- `review-test <test_module> <production_module> <reason>` — ambiguous; requires manual analysis

If no governance report exists, regenerate it first:

```bash
pytest --cov=. --cov-report=xml || true
bash .ai/toolkit/skills/python-test-governor/scripts/repo_test_inventory.sh \
  --base-ref origin/main \
  --coverage-xml coverage.xml \
  --test-results-dir test-results
```

Then re-run the parse script on that output.

### Step 2 — Assign Coverage Tiers

Before writing any test, assign a tier to each production module being remediated.
Use the rules in `references/coverage-targets.md`:

| Tier | Module type | Line coverage target |
|------|-------------|----------------------|
| **A** | Business logic, services, processors, validators, transformers with branching | ≥ 90% |
| **B** | Adapters with transformation, parsing, retries, query building, error handling | ≥ 80% |
| **C** | Thin facades, simple helpers, delegation with little branching | ≥ 70% |

Do not apply tier targets to modules marked `no-test-needed` by the governor.

### Step 3 — Inspect Source Before Writing

For each module to remediate:

1. Read the production module — understand its public interface, branching logic, dependencies
2. Read the existing test module (if any) — understand current patterns and what is broken
3. Read the project's `pytest.ini` or `pyproject.toml` — match framework and conventions

Do not generate tests based on module names alone.

### Step 4 — Apply Remediation Rules

Follow the rules in `references/remediation-rules.md` per action type.

#### For `create-test`

- Create `test_module_name.py` under `tests/` (or `tests/unit/` if the project uses that structure)
- Cover: happy path, branch/fallback path, error path (exceptions, validation failures)
- Test public functions first; only test private functions if they have complex isolated logic
- Use parameterized tests for cases that share the same arrange/act shape

#### For `update-test`

- Read the failing test and the production module side by side
- Identify the mismatch: new parameter, changed dependency, new exception type, changed return type
- Repair fixture setup before changing assertions
- When all failures share one broken mock or patch, fix that in shared setup first
- Do not create a new test file to mask a broken existing one

#### For `review-test`

- Explain the ambiguity — what evidence is missing
- Do not generate speculative code
- Mark in the output summary as `manual-review-needed`

### Step 5 — Apply Generation Standards

Use the template in `references/test-generation-template.md` and the standards in
`.ai/toolkit/skills/python-test-governor/references/test-generation-standards.md`:

- Match the project's framework (pytest or unittest)
- Arrange / Act / Assert pattern
- One behavior per test function
- Descriptive test names: `test_<what>_when_<condition>_returns_<expected>`
- Mock external dependencies (API calls, DB, file I/O, `datetime.now()`) — not the code under test
- Deterministic test data — no `datetime.now()`, no `random`, no live network calls
- Specific assertions — not `assert result` but `assert result["key"] == expected_value`

### Step 6 — Verify After Each Module

After creating or updating tests for a module, run the narrowest test target first:

```bash
pytest tests/test_<module_name>.py -v
```

If tests pass, run full coverage:

```bash
pytest --cov=. --cov-report=xml --cov-report=html --cov-report=term-missing
```

Record the line coverage percentage for the module vs the assigned tier target.
If coverage.py cannot be run (environment, CI context, user skipped), mark as `not verified`.

### Step 7 — Produce Remediation Summary

After all modules are processed, output a structured summary:

1. **Action summary** — how many `create-test`, `update-test`, `review-test` were processed
2. **Targets selected** — list of modules with assigned tier
3. **Files created or updated** — exact file paths
4. **Verification** — test commands run and pass/fail result
5. **Coverage summary table**:

```markdown
| Module | Tier | Line coverage (after) | Meets target? | Notes |
|--------|------|----------------------|---------------|-------|
| `src/services/processor.py` | A | 93% | ✅ Yes | All branches covered |
| `src/adapters/csv_parser.py` | B | 76% | ⚠️ No (target 80%) | Network error path requires integration test |
```

6. **Remaining manual reviews** — modules marked `review-test` with explanation

## Examples

### Example 1 — Remediate from latest governance report

```
/tw-python-test-remediator
```

Claude finds the most recent `TEST_GOVERNANCE_REPORT_*.md`, parses all `create-test` and
`update-test` decisions, generates the missing tests, runs coverage, and outputs the
coverage summary table.

### Example 2 — Remediate from a specific report file

```
/tw-python-test-remediator report_file=TEST_GOVERNANCE_REPORT_2026-06-18_10-30-00.md
```

### Example 3 — Full governance + remediation flow

```
# Step 1: audit
/tw-python-test-governor base_ref=origin/main coverage_xml=coverage.xml

# Step 2: remediate
/tw-python-test-remediator
```

### Example coverage summary output

```markdown
## Coverage Summary

| Module | Tier | Line coverage (after) | Meets target? | Notes |
|--------|------|----------------------|---------------|-------|
| `src/services/data_processor.py` | A | 92% | ✅ Yes | All branches covered |
| `src/adapters/csv_parser.py` | B | 85% | ✅ Yes | Exception paths tested |
| `src/utils/string_helpers.py` | C | 74% | ✅ Yes | Edge cases covered |
| `src/adapters/api_client.py` | B | 76% | ⚠️ No (80%) | Network error path needs integration test |

**Files created:** `tests/test_data_processor.py`, `tests/test_string_helpers.py`
**Files updated:** `tests/test_csv_parser.py`, `tests/test_api_client.py`
**Manual reviews needed:** 0
```

## Dependencies

- Output from `/tw-python-test-governor` (governance report file)
- Python 3.x in PATH
- `ripgrep` (`rg`) installed — required by the parse script
- `pytest` and `pytest-cov` in the project's dependencies
- Script at `.ai/toolkit/skills/python-test-remediator/scripts/parse_governance_report.sh`
- Reference files at `.ai/toolkit/skills/python-test-remediator/references/`
- Shared standards at `.ai/toolkit/skills/python-test-governor/references/test-generation-standards.md`
