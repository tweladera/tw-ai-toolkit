# CI and PR Gating Rules

Guidelines for implementing test coverage and quality gates in CI/CD pipelines for TypeScript/NestJS projects.

---

## Layered Gating Strategy

Implement checks at multiple stages to catch issues early:

1. **Pre-commit hooks** (local, fast via husky + lint-staged)
2. **PR validation** (comprehensive)
3. **Main branch protection** (strict)
4. **Nightly analysis** (deep)

---

## Layer 1: Pre-commit Hooks

### Fast Local Validation with Husky

The project already has husky configured (`"prepare": "husky install"` in `package.json`).

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
```

```json
// package.json - lint-staged configuration
{
  "lint-staged": {
    "src/**/*.ts": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
```

### Optional: Run specs for changed files

```bash
# .husky/pre-commit (extended)
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged

# Run specs only for changed *.ts files (fast check)
CHANGED=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ts$' | grep -v '\.spec\.ts$' | head -10)
if [ -n "$CHANGED" ]; then
  npx jest --findRelatedTests $CHANGED --passWithNoTests --bail
fi
```

---

## Layer 2: PR Validation

### GitLab CI Example

```yaml
# .gitlab-ci.yml
stages:
  - test
  - analysis

test:unit:
  stage: test
  image: node:20-alpine
  cache:
    paths:
      - node_modules/
  before_script:
    - npm ci
  script:
    - npm run test:cov -- --coverage-reporters=text --coverage-reporters=json-summary --forceExit
  coverage: '/Lines\s*:\s*([\d.]+)%/'
  artifacts:
    reports:
      junit: test-results/junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/
    expire_in: 1 week
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

analysis:governance:
  stage: analysis
  image: node:20-alpine
  before_script:
    - apk add --no-cache bash ripgrep git
    - npm ci
  script:
    - npm run test:cov -- --coverage-reporters=json-summary --forceExit || true
    - bash .claude/skills/ts-unit-test-governor/scripts/repo_test_inventory.sh
        --base-ref origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
        --coverage-summary coverage/coverage-summary.json
  artifacts:
    paths:
      - TEST_GOVERNANCE_REPORT_*.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

### GitHub Actions Example

```yaml
# .github/workflows/pr-tests.yml
name: PR Test Validation

on:
  pull_request:
    branches: [ master, main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for diff analysis

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm run test:cov -- --coverage-reporters=text --coverage-reporters=json-summary --forceExit

      - name: Check coverage thresholds
        run: |
          LINES=$(node -e "const s=require('./coverage/coverage-summary.json');console.log(s.total.lines.pct)")
          echo "Line coverage: $LINES%"
          node -e "const s=require('./coverage/coverage-summary.json');if(s.total.lines.pct<95)process.exit(1)"

      - name: Generate governance report
        run: |
          bash .claude/skills/ts-unit-test-governor/scripts/repo_test_inventory.sh \
            --base-ref origin/${{ github.base_ref }} \
            --coverage-summary coverage/coverage-summary.json
```

---

## Coverage Thresholds

### Project-Level (already in package.json)

```json
"jest": {
  "coverageThreshold": {
    "global": {
      "lines": 95,
      "functions": 95,
      "branches": 90,
      "statements": 95
    }
  }
}
```

### Per-Directory Thresholds (optional)

```json
"jest": {
  "coverageThreshold": {
    "global": {
      "lines": 95
    },
    "./src/app/": {
      "lines": 95,
      "functions": 95
    },
    "./src/infra/rest/": {
      "lines": 80
    }
  }
}
```

### Run coverage check locally

```bash
# Full suite with coverage and threshold enforcement
npm run test:cov

# Coverage for specific file only
npx jest src/app/supply/inventory/inventory.service.spec.ts \
  --coverage \
  --collectCoverageFrom="src/app/supply/inventory/inventory.service.ts" \
  --coverageDirectory=coverage-check
```

---

## Differential Coverage

Check coverage only on changed lines in a PR:

```bash
#!/usr/bin/env bash
# scripts/check-diff-coverage.sh

BASE_REF="${1:-origin/master}"

# Get changed TypeScript source files (not specs)
CHANGED=$(git diff "$BASE_REF"...HEAD --name-only -- '*.ts' | grep -v '\.spec\.ts$' | grep -v '\.module\.ts$' || true)

if [ -z "$CHANGED" ]; then
  echo "No TypeScript source changes detected."
  exit 0
fi

echo "Changed source files:"
echo "$CHANGED"

# Run jest only for related specs
npx jest --findRelatedTests $CHANGED \
  --coverage \
  --coverageReporters=text \
  --passWithNoTests \
  --forceExit
```

---

## Test Quality Gates

### Beyond Coverage: Quality Checks

```yaml
# Additional quality checks in CI
- name: TypeScript compile check
  run: npx tsc --noEmit

- name: ESLint check
  run: npm run lint

- name: Check for skipped tests
  run: |
    if grep -r "\.skip\|xdescribe\|xit\b" src/ --include="*.spec.ts"; then
      echo "Skipped tests found - review before merging"
      exit 1
    fi

- name: Check for focused tests
  run: |
    if grep -r "\.only\|fdescribe\|fit\b" src/ --include="*.spec.ts"; then
      echo "Focused tests found (.only) - must be removed before merge"
      exit 1
    fi
```

### Detect Tests Without Assertions

```bash
#!/usr/bin/env bash
# Check for spec functions that have no expect() calls
if grep -rn "it\('.*', " src/ --include="*.spec.ts" -l | xargs grep -L "expect(" 2>/dev/null; then
  echo "Warning: Spec files found without expect() calls"
fi
```

---

## Decision Matrix for PR Gating

| Condition | Action |
|-----------|--------|
| Any test fails | Block merge |
| Coverage < global threshold (lines: 95%) | Block merge |
| `it.only` or `describe.only` found | Block merge |
| Changed lines not covered by specs | Warning (require approval) |
| No spec for new service/use-case module | Warning (require explanation) |
| Specs with no `expect()` calls | Block merge |
| TypeScript compile errors | Block merge |
| All checks pass | Allow merge |

---

## Nightly Deep Analysis

```yaml
# .github/workflows/nightly-analysis.yml
name: Nightly Test Analysis

on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  deep-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: npm ci

      - name: Run full test suite with coverage
        run: npm run test:cov -- --coverage-reporters=json-summary --forceExit

      - name: Generate governance report
        run: |
          bash .claude/skills/ts-unit-test-governor/scripts/repo_test_inventory.sh \
            --coverage-summary coverage/coverage-summary.json

      - name: Upload reports
        uses: actions/upload-artifact@v4
        with:
          name: nightly-reports
          path: |
            coverage/
            TEST_GOVERNANCE_REPORT_*.md
```

---

## Best Practices

1. **Start with achievable thresholds** — Project already has 95% as target; maintain it
2. **Focus on differential coverage** — All new code must have specs
3. **Critical paths need high coverage** — Use case / service layer ≥ 95%
4. **Fast feedback** — Pre-commit catches issues in seconds via `--findRelatedTests`
5. **Clear exemption policy** — Document when/why coverage can be skipped with `/* istanbul ignore next */`
6. **Trend tracking** — Monitor coverage trends across branches
7. **Quality over quantity** — Tests must have meaningful assertions, not just coverage lines
8. **Make it easy to comply** — Provide spec templates and examples

---

## Coverage Exemptions

Mark code that doesn't need coverage:

```typescript
/* istanbul ignore next */
function debugOnlyHelper() {
  // Development only
}

// Or for a single line
const result = condition ? valueA : /* istanbul ignore next */ valueB;
```

Or configure in `package.json`:
```json
"jest": {
  "coveragePathIgnorePatterns": [
    "/node_modules/",
    "/dist/",
    "main.ts",
    ".module.ts",
    ".enum.ts",
    ".type.ts"
  ]
}
```
