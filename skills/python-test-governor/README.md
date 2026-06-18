# python-test-governor

**Invocation:** `/tw-python-test-governor`

Audits unit test coverage in a Python repository. Maps every production module to its test
status, classifies gaps by severity, and produces a structured governance report with
prioritized remediation actions.

## What it produces

- Inventory of all test files (unit / integration / support)
- Module-to-test map showing covered and unmapped production modules
- Structured findings table with severity (CRITICAL / HIGH / MEDIUM / LOW)
- Impacted modules table with decision per module (create-test / update-test / no-change / no-test-needed)
- Prioritized recommendations with exact commands
- Optional root cause analysis when systemic test failures are detected
- Saved Markdown report in the project root

## When to use it

- Before a release to assess test coverage health
- When reviewing a PR with significant code changes
- To establish a coverage baseline for a new project
- To generate a test governance report for the team

## Companion skill

After running this skill, use `/tw-python-test-remediator` to turn the governance report
into actual test code.

## Supporting files

| File | Purpose |
|---|---|
| `references/analysis-guide.md` | Severity and decision classification rules |
| `references/output-template.md` | Mandatory report structure (7 sections) |
| `references/test-generation-standards.md` | pytest/unittest generation conventions |
| `references/ci-gating-rules.md` | GitHub Actions / GitLab CI gating configurations |
| `scripts/repo_test_inventory.sh` | Bash script that scans the repo and produces structured inventory |

## Prerequisites

- Python 3.x in PATH
- `ripgrep` (`rg`) installed — required by the inventory script
- `pytest` and `pytest-cov` in the project's dependencies
