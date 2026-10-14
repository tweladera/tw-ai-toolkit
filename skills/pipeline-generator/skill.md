---
name: pipeline-generator
description: Generates a complete CI/CD quality pipeline (GitHub Actions or GitLab CI) that chains all tw-ai-toolkit skills as automated quality gates. Turns the toolkit from tribal knowledge into enforced infrastructure.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: platform
    type: string
    required: false
    default: ""
    description: "CI platform: 'github' or 'gitlab'. Auto-detected from .github/ or .gitlab-ci.yml presence."
  - name: stack
    type: string
    required: false
    default: ""
    description: "Project stack: 'typescript', 'python', or 'java'. Auto-detected from project files."
  - name: stages
    type: string
    required: false
    default: "lint,unit,e2e,contracts"
    description: "Comma-separated pipeline stages to include: lint, unit, e2e, contracts, mutation, performance, a11y. Default: lint,unit,e2e,contracts"
  - name: nightly
    type: boolean
    required: false
    default: "false"
    description: "When true, generates a separate nightly job for expensive checks (mutation testing, full performance baseline)."
  - name: fail_on
    type: string
    required: false
    default: "critical"
    description: "Pipeline fail threshold: 'critical' (only CRITICAL gaps block merge), 'high' (HIGH + CRITICAL), 'any' (any gap blocks merge)."
tags:
  - ci-cd
  - github-actions
  - gitlab-ci
  - pipeline
  - quality-gates
  - automation
invocation: tw-pipeline-generator
---

# pipeline-generator

## Description

Generates a production-ready CI/CD quality pipeline that runs all applicable toolkit skills
automatically on every commit, PR, or merge. Converts the toolkit from a set of manual skills
that require SDET knowledge into enforced infrastructure that runs without human intervention.

**The core insight:** A toolkit that requires manual invocation is tribal knowledge. A toolkit
wired into CI/CD is a quality gate that the whole team respects regardless of who runs the PR.

**Generated pipeline stages:**
1. **lint** — Component validation (`/tw-lint-component`) and code linting
2. **unit-governance** — Test governor for the detected stack (blocks if CRITICAL gaps)
3. **e2e-governance** — E2E test governor (reports flow coverage, blocks if CRITICAL flows untested)
4. **contracts** — Contract coverage check (reports missing Pact contracts)
5. **mutation** (nightly) — Mutation audit on tier-A modules
6. **performance** (nightly) — Performance baseline comparison
7. **a11y** (optional) — Accessibility audit on main flows

## When to Use

- When setting up a new project with the toolkit for the first time
- When the team uses skills manually but there is no automated enforcement
- After adding new skills (e2e, mutation, performance) and needing to wire them into CI

Triggers: "generate the CI pipeline", "set up GitHub Actions for quality",
"wire the toolkit into GitLab CI", "automate quality gates".

## Instructions

### Step 1 — Detect Platform and Stack

```bash
# Platform detection
ls .github/workflows/ 2>/dev/null && echo "github"
ls .gitlab-ci.yml 2>/dev/null && echo "gitlab"

# Stack detection
ls package.json tsconfig.json 2>/dev/null && echo "typescript"
ls pyproject.toml setup.py requirements.txt 2>/dev/null && echo "python"
ls pom.xml build.gradle 2>/dev/null && echo "java"

# E2E framework
ls cypress.config.ts cypress.config.js playwright.config.ts playwright.config.js 2>/dev/null
```

Read existing CI files to avoid overwriting pipeline stages already configured.

### Step 2 — Read Toolkit Config

```bash
cat .ai/config.json 2>/dev/null
```

Check which toolkit components are active in the consumer repo. Only generate stages
for skills that are installed and relevant.

### Step 3a — Generate GitHub Actions Pipeline

File: `.github/workflows/tw-quality.yml`

```yaml
name: Quality Gates — tw-ai-toolkit

on:
  pull_request:
    branches: [main, master, develop]
  push:
    branches: [main, master]

env:
  NODE_VERSION: '20'   # adjust per project
  PYTHON_VERSION: '3.11'
  FAIL_ON: '{{fail_on}}'

jobs:
  # ─────────────────────────────────────────
  # STAGE 1 — Lint & Schema Validation
  # ─────────────────────────────────────────
  lint:
    name: Lint & Validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Node / Python / Java   # adjust per stack
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      - name: Install dependencies
        run: npm ci   # or pip install -r requirements.txt
      - name: Run linter
        run: npm run lint   # or flake8 / ruff / checkstyle
      - name: Validate toolkit components
        run: python3 .ai/toolkit/scripts/validate.py --strict

  # ─────────────────────────────────────────
  # STAGE 2 — Unit Test Governance
  # ─────────────────────────────────────────
  unit-governance:
    name: Unit Test Governance
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Set up environment
        uses: actions/setup-node@v4
        with: { node-version: '${{ env.NODE_VERSION }}' }
      - name: Install dependencies
        run: npm ci
      - name: Run tests with coverage
        run: npm run test:cov -- --coverage-reporters=json-summary || true
        # Python: pytest --cov=. --cov-report=xml || true
      - name: Run inventory script
        run: |
          bash .ai/toolkit/skills/ts-test-governor/scripts/repo_test_inventory.sh \
            --base-ref ${{ github.base_ref && format('origin/{0}', github.base_ref) || '' }} \
            --coverage-summary coverage/coverage-summary.json || true
      - name: Upload governance artifacts
        uses: actions/upload-artifact@v4
        with:
          name: unit-governance-report
          path: TEST_GOVERNANCE_REPORT_*.md
      - name: Fail on critical gaps
        run: |
          report=$(ls TEST_GOVERNANCE_REPORT_*.md 2>/dev/null | tail -1)
          if [ -n "$report" ] && grep -q "HALT\|Overall decision.*HALT" "$report"; then
            echo "::error::Unit governance: HALT decision — critical test blockers detected"
            exit 1
          fi

  # ─────────────────────────────────────────
  # STAGE 3 — E2E Test Governance
  # ─────────────────────────────────────────
  e2e-governance:
    name: E2E Coverage Audit
    runs-on: ubuntu-latest
    needs: unit-governance
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm ci
      - name: Scan E2E coverage
        run: |
          rg -l "" --glob "**/*.cy.ts" --glob "**/*.spec.ts" tests/ cypress/ 2>/dev/null \
            | wc -l | xargs -I{} echo "E2E test files found: {}"
      - name: Upload E2E governance report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-governance-report
          path: E2E_GOVERNANCE_REPORT_*.md

  # ─────────────────────────────────────────
  # STAGE 4 — Contract Coverage
  # ─────────────────────────────────────────
  contracts:
    name: Contract Coverage
    runs-on: ubuntu-latest
    needs: unit-governance
    steps:
      - uses: actions/checkout@v4
      - name: Scan for missing contract tests
        run: |
          rg -l "axios|fetch|HttpService" --type ts 2>/dev/null | head -20
          rg -l "\.pact\." --type ts --type js 2>/dev/null | head -20
      - name: Upload contract report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: contract-coverage-report
          path: CONTRACT_COVERAGE_REPORT_*.md

  # ─────────────────────────────────────────
  # STAGE 5 (nightly) — Mutation Audit
  # ─────────────────────────────────────────
  mutation-audit:
    name: Mutation Testing
    runs-on: ubuntu-latest
    if: github.event_name == 'schedule' || inputs.run_mutation == 'true'
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm ci
      - name: Run Stryker mutation testing
        run: npx stryker run --reporters json,clear-text || true
      - name: Upload mutation report
        uses: actions/upload-artifact@v4
        with:
          name: mutation-report
          path: reports/mutation/

  # ─────────────────────────────────────────
  # STAGE 6 (nightly) — Performance Baseline
  # ─────────────────────────────────────────
  performance-baseline:
    name: Performance Baseline
    runs-on: ubuntu-latest
    if: github.event_name == 'schedule'
    steps:
      - uses: actions/checkout@v4
      - name: Install k6
        run: |
          sudo gpg -k
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
            | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6
      - name: Run performance baseline
        run: k6 run .ai/toolkit/performance/baseline.js --out json=performance-results.json || true
      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: performance-results
          path: performance-results.json

# Nightly schedule
# Add this to trigger nightly jobs:
# on:
#   schedule:
#     - cron: '0 2 * * *'   # 2 AM UTC daily
```

### Step 3b — Generate GitLab CI Pipeline

File: `.gitlab-ci.yml` (appended as `tw-quality` stages if file exists)

```yaml
# tw-ai-toolkit quality stages
# Generated by /tw-pipeline-generator — do not edit manually

stages:
  - tw-lint
  - tw-unit-governance
  - tw-e2e-governance
  - tw-contracts
  - tw-mutation       # nightly only
  - tw-performance    # nightly only

variables:
  TW_FAIL_ON: "critical"

tw-lint:
  stage: tw-lint
  script:
    - npm ci
    - npm run lint
    - python3 .ai/toolkit/scripts/validate.py --strict
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

tw-unit-governance:
  stage: tw-unit-governance
  needs: [tw-lint]
  script:
    - npm ci
    - npm run test:cov -- --coverage-reporters=json-summary || true
    - bash .ai/toolkit/skills/ts-test-governor/scripts/repo_test_inventory.sh
        --base-ref origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
        --coverage-summary coverage/coverage-summary.json || true
  artifacts:
    paths:
      - TEST_GOVERNANCE_REPORT_*.md
    expire_in: 7 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

tw-e2e-governance:
  stage: tw-e2e-governance
  needs: [tw-unit-governance]
  script:
    - rg -l "" --glob "**/*.cy.ts" --glob "**/*.spec.ts" 2>/dev/null | wc -l
  artifacts:
    paths:
      - E2E_GOVERNANCE_REPORT_*.md
    expire_in: 7 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

tw-contracts:
  stage: tw-contracts
  needs: [tw-unit-governance]
  script:
    - rg -l "axios|fetch|HttpService" --type ts 2>/dev/null | head -20
  allow_failure: true   # warn, don't block
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

tw-mutation:
  stage: tw-mutation
  script:
    - npx stryker run --reporters json || true
  artifacts:
    paths:
      - reports/mutation/
    expire_in: 30 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'

tw-performance:
  stage: tw-performance
  script:
    - k6 run .ai/toolkit/performance/baseline.js --out json=performance-results.json || true
  artifacts:
    paths:
      - performance-results.json
    expire_in: 30 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
```

### Step 4 — Add Nightly Schedule (if nightly=true)

**GitHub Actions** — append to the `on:` block:
```yaml
on:
  schedule:
    - cron: '0 2 * * *'   # 2:00 AM UTC daily
  workflow_dispatch:        # manual trigger
    inputs:
      run_mutation:
        description: 'Run mutation testing'
        type: boolean
        default: false
```

**GitLab** — create a pipeline schedule in the GitLab UI:
```
Settings → CI/CD → Pipeline schedules
Interval: 0 2 * * *
Variables: TW_NIGHTLY=true
```

### Step 5 — Confirm and Document

Output:
```
Pipeline generated
Platform: [github|gitlab]
Stack: [typescript|python|java]
Stages: [list]
File: [.github/workflows/tw-quality.yml | .gitlab-ci.yml]

Quality gates configured:
  lint          → blocks on linter errors or schema violations
  unit          → blocks on HALT decision from governor
  e2e           → warns on missing CRITICAL flows (configurable to block)
  contracts     → warns on missing contract tests
  mutation      → nightly — reports mutation score trend
  performance   → nightly — compares against baseline thresholds

Next steps:
  1. Review generated pipeline file and adjust Node/Python version
  2. Set required secrets in repo settings (e.g. SONAR_TOKEN if applicable)
  3. Push to trigger first run
  4. Set up nightly schedule for mutation and performance stages
```

## Examples

### Example 1 — GitHub Actions for a TypeScript project

```
/tw-pipeline-generator platform=github stack=typescript stages=lint,unit,e2e,contracts
```

### Example 2 — GitLab CI with all stages including nightly

```
/tw-pipeline-generator platform=gitlab stack=java stages=lint,unit,contracts,mutation,performance nightly=true
```

### Example 3 — Minimal pipeline (fast CI, low friction)

```
/tw-pipeline-generator stages=lint,unit fail_on=critical
```

## Dependencies

- `.ai/toolkit` installed in consumer repo
- Stack-specific test commands available (`npm run test:cov`, `pytest --cov`, `mvn test`)
- `ripgrep` (`rg`) available in CI runner
- For mutation stage: `stryker` (TS) or `mutmut` (Python) installable
- For performance stage: `k6` installable in CI runner

## Notes

- Generated pipeline appends `tw-quality` stages — it does not replace existing CI config
- All stages default to `allow_failure: true` except `lint` and `unit-governance` (HALT only)
- Adjust `fail_on` per team maturity: start with `critical`, tighten to `high` over time
- Nightly jobs are expensive — do not add to PR pipelines unless the team has fast runners
