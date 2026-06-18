# CI and PR Gating Rules

Guidelines for implementing test coverage and quality gates in CI/CD pipelines for Python projects.

---

## Layered Gating Strategy

Implement checks at multiple stages to catch issues early:

1. **Pre-commit hooks** (local, fast)
2. **PR validation** (comprehensive)
3. **Main branch protection** (strict)
4. **Nightly analysis** (deep)

---

## Layer 1: Pre-commit Hooks

### Fast Local Validation

Use `pre-commit` framework for local checks before commits:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: pytest-quick
        name: Run quick unit tests
        entry: pytest -m "not slow" --tb=short
        language: system
        pass_filenames: false
        always_run: true

      - id: check-test-files
        name: Ensure test files exist for changed modules
        entry: python scripts/check_tests.py
        language: system
        pass_filenames: false
        always_run: true
```

### Check Script Example

```python
#!/usr/bin/env python3
"""Check that changed Python files have corresponding tests"""
import subprocess
import sys
from pathlib import Path

def get_changed_files():
    """Get list of changed .py files"""
    result = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', '--diff-filter=ACM', '*.py'],
        capture_output=True,
        text=True
    )
    return [f for f in result.stdout.splitlines() if not f.startswith('tests/')]

def find_test_file(module_path):
    """Find corresponding test file for a module"""
    path = Path(module_path)
    test_patterns = [
        Path('tests') / f'test_{path.name}',
        Path('tests') / path.parent / f'test_{path.name}',
        path.parent / f'test_{path.name}',
    ]
    return any(p.exists() for p in test_patterns)

def main():
    changed = get_changed_files()
    missing_tests = [f for f in changed if not find_test_file(f)]

    if missing_tests:
        print("⚠️  Warning: The following files lack test coverage:")
        for f in missing_tests:
            print(f"  - {f}")
        print("\nConsider adding tests before committing.")
        # Warning only, don't block
        return 0
    return 0

if __name__ == '__main__':
    sys.exit(main())
```

---

## Layer 2: PR Validation

### GitHub Actions Example

```yaml
# .github/workflows/pr-tests.yml
name: PR Test Validation

on:
  pull_request:
    branches: [ main, master, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for diff analysis

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run tests with coverage
        run: |
          pytest --cov=. --cov-report=xml --cov-report=term-missing

      - name: Check coverage threshold
        run: |
          coverage report --fail-under=80

      - name: Generate test governance report
        run: |
          bash .cursor/skills/python-unit-test-governor/scripts/repo_test_inventory.sh \
            --base-ref origin/${{ github.base_ref }} \
            --coverage-xml coverage.xml \
            --test-results-dir test-results

      - name: Comment PR with coverage report
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const coverage = fs.readFileSync('coverage.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Test Coverage Report\n\n\`\`\`\n${coverage}\n\`\`\``
            });
```

### GitLab CI Example

```yaml
# .gitlab-ci.yml
stages:
  - test
  - analysis

test:unit:
  stage: test
  image: python:3.11
  before_script:
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
  script:
    - pytest --cov=. --cov-report=xml --cov-report=term-missing --junitxml=report.xml
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

analysis:governance:
  stage: analysis
  image: python:3.11
  before_script:
    - apt-get update && apt-get install -y ripgrep
  script:
    - bash .cursor/skills/python-unit-test-governor/scripts/repo_test_inventory.sh \
        --base-ref origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME \
        --coverage-xml coverage.xml
  artifacts:
    paths:
      - TEST_GOVERNANCE_REPORT_*.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

---

## Coverage Thresholds

### Global Minimum Coverage

Set a baseline for overall project coverage:

```ini
# pytest.ini or pyproject.toml
[tool:pytest]
addopts = --cov=. --cov-report=term-missing --cov-fail-under=80

# Or in pyproject.toml
[tool.coverage.report]
fail_under = 80
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
```

### Differential Coverage

Only check coverage on changed lines:

```python
#!/usr/bin/env python3
"""Check that changed lines are covered by tests"""
import subprocess
import sys
import xml.etree.ElementTree as ET

def get_changed_lines():
    """Get dict of file -> set of changed line numbers"""
    result = subprocess.run(
        ['git', 'diff', 'origin/main...HEAD', '--unified=0'],
        capture_output=True,
        text=True
    )

    changes = {}
    current_file = None

    for line in result.stdout.splitlines():
        if line.startswith('+++'):
            current_file = line[6:]  # Remove '+++ b/'
            changes[current_file] = set()
        elif line.startswith('@@'):
            # Parse hunk header: @@ -old_start,old_count +new_start,new_count @@
            parts = line.split('+')[1].split('@@')[0].strip().split(',')
            start = int(parts[0])
            count = int(parts[1]) if len(parts) > 1 else 1
            changes[current_file].update(range(start, start + count))

    return changes

def get_covered_lines(coverage_xml='coverage.xml'):
    """Get dict of file -> set of covered line numbers"""
    tree = ET.parse(coverage_xml)
    root = tree.getroot()

    coverage = {}
    for package in root.findall('.//package'):
        for cls in package.findall('class'):
            filename = cls.get('filename')
            covered = set()
            for line in cls.findall('.//line'):
                if int(line.get('hits', 0)) > 0:
                    covered.add(int(line.get('number')))
            coverage[filename] = covered

    return coverage

def main():
    changed_lines = get_changed_lines()
    covered_lines = get_covered_lines()

    uncovered_changes = {}
    for file, lines in changed_lines.items():
        if file.endswith('.py') and file in covered_lines:
            uncovered = lines - covered_lines[file]
            if uncovered:
                uncovered_changes[file] = uncovered

    if uncovered_changes:
        print("❌ Uncovered lines in changed code:")
        for file, lines in uncovered_changes.items():
            print(f"\n{file}:")
            for line in sorted(lines):
                print(f"  Line {line}")
        return 1

    print("✅ All changed lines are covered by tests")
    return 0

if __name__ == '__main__':
    sys.exit(main())
```

---

## Module-Specific Thresholds

### Critical Modules Require Higher Coverage

```python
# conftest.py or separate script
COVERAGE_THRESHOLDS = {
    'src/core/': 95,           # Core business logic
    'src/services/': 90,       # Service layer
    'src/utils/': 85,          # Utilities
    'src/adapters/': 80,       # Adapters
    'src/models/': 70,         # Data models
}

def check_module_coverage():
    """Verify each module meets its threshold"""
    import coverage
    cov = coverage.Coverage()
    cov.load()

    for module_path, threshold in COVERAGE_THRESHOLDS.items():
        # Get coverage for modules matching path
        analysis = cov.analysis(module_path)
        percent = (len(analysis.executed) / len(analysis.statements)) * 100

        if percent < threshold:
            print(f"❌ {module_path}: {percent:.1f}% < {threshold}%")
            return False

    return True
```

---

## Test Quality Gates

### Beyond Coverage: Quality Metrics

```yaml
# Additional quality checks in CI
- name: Check test quality
  run: |
    # No skipped tests in PR
    pytest --strict-markers -v 2>&1 | grep -q "skipped" && exit 1 || true

    # No tests with only pass statement
    grep -r "def test_.*:.*pass$" tests/ && exit 1 || true

    # Detect tests without assertions
    python scripts/check_test_quality.py
```

### Test Quality Checker

```python
#!/usr/bin/env python3
"""Detect low-quality test patterns"""
import ast
import sys
from pathlib import Path

class TestQualityChecker(ast.NodeVisitor):
    def __init__(self):
        self.issues = []
        self.current_test = None

    def visit_FunctionDef(self, node):
        if node.name.startswith('test_'):
            self.current_test = node.name
            has_assertion = any(
                isinstance(n, ast.Assert) or
                (isinstance(n, ast.Expr) and
                 isinstance(n.value, ast.Call) and
                 getattr(n.value.func, 'attr', '').startswith('assert'))
                for n in ast.walk(node)
            )

            if not has_assertion:
                self.issues.append(f"{self.current_test}: No assertions found")

        self.generic_visit(node)

def main():
    checker = TestQualityChecker()
    test_files = Path('tests').rglob('test_*.py')

    for test_file in test_files:
        with open(test_file) as f:
            tree = ast.parse(f.read())
            checker.visit(tree)

    if checker.issues:
        print("❌ Test quality issues found:")
        for issue in checker.issues:
            print(f"  {issue}")
        return 1

    print("✅ All tests have assertions")
    return 0

if __name__ == '__main__':
    sys.exit(main())
```

---

## Decision Matrix for PR Gating

| Condition | Action |
|-----------|--------|
| Any test fails | ❌ Block merge |
| Coverage < global threshold | ❌ Block merge |
| Critical module coverage < threshold | ❌ Block merge |
| Changed lines not covered | ⚠️ Warning (require approval) |
| No tests for new modules | ⚠️ Warning (require explanation) |
| Tests with no assertions | ❌ Block merge |
| All checks pass | ✅ Allow merge |

---

## Nightly Deep Analysis

### Comprehensive Check Beyond PR Scope

```yaml
# .github/workflows/nightly-analysis.yml
name: Nightly Test Analysis

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:

jobs:
  deep-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run full test suite
        run: pytest --cov=. --cov-report=html --cov-report=xml -v

      - name: Generate governance report
        run: |
          bash .cursor/skills/python-unit-test-governor/scripts/repo_test_inventory.sh \
            --coverage-xml coverage.xml \
            --test-results-dir test-results

      - name: Check for stale tests
        run: python scripts/detect_stale_tests.py

      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: nightly-reports
          path: |
            htmlcov/
            TEST_GOVERNANCE_REPORT_*.md
```

---

## Exemptions and Overrides

### When to Allow Exceptions

Document legitimate reasons to bypass coverage requirements:

```python
# Mark code that doesn't need coverage
def debug_only_function():  # pragma: no cover
    """Only used in development"""
    pass

# Type checking only
if TYPE_CHECKING:  # pragma: no cover
    from typing import SomeType
```

### PR Exemption Process

```yaml
# Require maintainer approval if coverage drops
- name: Check coverage change
  run: |
    current=$(coverage report --format=total)
    baseline=$(curl -s https://api.example.com/coverage/main)

    if (( $(echo "$current < $baseline" | bc -l) )); then
      echo "Coverage decreased: $baseline% -> $current%"
      echo "Requires maintainer approval"
      exit 1
    fi
```

---

## Best Practices

1. **Start with achievable thresholds** - 70% initially, increase gradually
2. **Focus on differential coverage** - All new code must be tested
3. **Critical paths need high coverage** - Core business logic ≥ 90%
4. **Fast feedback** - Pre-commit catches issues in seconds
5. **Clear exemption policy** - Document when/why coverage can be skipped
6. **Trend tracking** - Monitor coverage over time
7. **Quality over quantity** - Tests must have meaningful assertions
8. **Make it easy to comply** - Provide test templates and examples

---

## Monitoring and Metrics

### Track Coverage Trends

```python
# scripts/track_coverage.py
import json
from datetime import datetime

def log_coverage(coverage_percent, commit_sha):
    """Log coverage to historical record"""
    record = {
        'timestamp': datetime.now().isoformat(),
        'commit': commit_sha,
        'coverage': coverage_percent
    }

    with open('coverage_history.json', 'a') as f:
        json.dump(record, f)
        f.write('\n')
```

### Dashboard Example

- Current coverage: 85.3%
- Trend (30 days): ↑ 2.1%
- Modules below threshold: 3
- Tests without assertions: 0
- Average test execution time: 12.3s
