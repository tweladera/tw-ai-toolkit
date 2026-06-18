#!/usr/bin/env bash
set -euo pipefail

BASE_REF=""
COVERAGE_XML=""
TEST_RESULTS_DIR=""
REPO_ROOT="${PWD}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-ref)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --coverage-xml)
      COVERAGE_XML="${2:-}"
      shift 2
      ;;
    --test-results-dir)
      TEST_RESULTS_DIR="${2:-}"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

if ! command -v rg >/dev/null 2>&1; then
  echo "This script requires rg (ripgrep)." >&2
  exit 1
fi

classify_test() {
  local file="$1"

  # Support files: conftest.py, fixtures, helpers
  if [[ "$file" =~ conftest\.py$ ]] || [[ "$file" =~ fixtures/ ]] || [[ "$file" =~ test_helpers/ ]]; then
    echo "support"
  # Not a test file
  elif [[ ! "$file" =~ test_.*\.py$ ]] && [[ ! "$file" =~ .*_test\.py$ ]]; then
    echo "support"
  # Integration tests: DB, HTTP, filesystem, containers
  elif rg -q 'import pytest|import unittest' "$file" && \
       rg -q '@pytest.mark.integration|TestCase.*Integration|sqlalchemy|requests\.|httpx\.|docker|testcontainers' "$file"; then
    echo "integration"
  else
    echo "unit"
  fi
}

production_modules() {
  # Find all .py files excluding tests, __pycache__, venv, etc.
  rg --files -g '*.py' \
    | grep -v '^tests/' \
    | grep -v '^test_' \
    | grep -v '_test\.py$' \
    | grep -v '__pycache__' \
    | grep -v '\.venv/' \
    | grep -v 'venv/' \
    | grep -v 'site-packages/' \
    | sort
}

test_modules() {
  # Find test files
  rg --files -g 'test_*.py' -g '*_test.py' \
    | sort
}

matching_test_for() {
  local prod_file="$1"
  local base="${prod_file%.py}"

  # Try common test naming patterns
  local candidates=(
    "tests/test_${base##*/}.py"
    "tests/${base}_test.py"
    "test_${base##*/}.py"
    "${base}_test.py"
    "tests/unit/test_${base##*/}.py"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
}

logic_heavy_module() {
  local file="$1"

  # Skip simple files
  if [[ "$file" =~ __init__\.py$ ]] || [[ "$file" =~ setup\.py$ ]]; then
    return 1
  fi

  # Skip data models (simple dataclasses, TypedDict)
  if rg -q '@dataclass|class.*\(TypedDict\)|NamedTuple' "$file" && \
     ! rg -q 'def [^_]|if |for |while |try:|raise ' "$file"; then
    return 1
  fi

  # Has logic: conditionals, loops, error handling, functions
  if rg -q 'def [^_]|if |for |while |try:|raise |lambda ' "$file"; then
    return 0
  fi

  return 1
}

coverage_line() {
  local prod_file="$1"
  local module_path="${prod_file%.py}"
  module_path="${module_path//\//.}"

  [[ -n "$COVERAGE_XML" && -f "$COVERAGE_XML" ]] || return 0

  # Parse coverage.xml for module coverage
  awk -v mod="$module_path" '
    $0 ~ "<class.*filename=\""FILENAME"\"" {
      if (match($0, /line-rate="([^"]+)"/, arr)) {
        coverage = arr[1] * 100
        printf "%.1f%% coverage\n", coverage
      }
    }
  ' FILENAME="$prod_file" "$COVERAGE_XML" | head -n 1
}

production_from_test() {
  local test_file="$1"
  local base="${test_file##*/}"

  # Remove test_ prefix or _test suffix
  base="${base#test_}"
  base="${base%_test.py}.py"

  # Search for production file
  rg --files -g "$base" | grep -v '^tests/' | head -n 1
}

failing_test_files() {
  [[ -n "$TEST_RESULTS_DIR" && -d "$TEST_RESULTS_DIR" ]] || return 0

  # Look for pytest or unittest output files
  if [[ -f "$TEST_RESULTS_DIR/pytest.xml" ]]; then
    echo "$TEST_RESULTS_DIR/pytest.xml"
  fi

  rg --files "$TEST_RESULTS_DIR" -g '*.xml' 2>/dev/null || true
}

failure_cause_for_output() {
  local output_file="$1"

  if rg -q 'AssertionError' "$output_file"; then
    echo "assertion-failure"
  elif rg -q 'AttributeError|TypeError|NameError' "$output_file"; then
    echo "broken-test-fixture"
  elif rg -q 'ModuleNotFoundError|ImportError' "$output_file"; then
    echo "missing-dependency"
  elif rg -q 'FAILED.*test_' "$output_file"; then
    echo "test-failure"
  else
    echo "unknown-failure"
  fi
}

failure_summary_for_output() {
  local output_file="$1"
  rg 'FAILED|ERROR|AssertionError' "$output_file" | head -n 3 | cut -c1-180
}

diff_changed_modules() {
  [[ -n "$BASE_REF" ]] || return 0
  git diff --name-only "$BASE_REF"...HEAD -- '*.py' 2>/dev/null | \
    grep -v '^tests/' | \
    grep -v '^test_' | \
    grep -v '_test\.py$' | \
    sort || true
}

file_contains_behavioral_diff() {
  local file="$1"
  [[ -n "$BASE_REF" ]] || return 1

  git diff --unified=0 "$BASE_REF"...HEAD -- "$file" 2>/dev/null | \
    rg -q '^[+-].*def |^[+-].*if |^[+-].*for |^[+-].*while |^[+-].*try:|^[+-].*raise |^[+-].*return |^[+-].*assert '
}

echo "== TEST INVENTORY =="
test_modules | while read -r test_file; do
  [[ -n "$test_file" ]] || continue
  printf "%s\t%s\n" "$(classify_test "$test_file")" "$test_file"
done

echo
echo "== MODULE TO TEST MAP =="
production_modules | while read -r prod_file; do
  [[ -n "$prod_file" ]] || continue
  test_file="$(matching_test_for "$prod_file" || true)"
  if [[ -n "$test_file" ]]; then
    printf "covered\t%s\t%s\n" "$prod_file" "$test_file"
  else
    printf "unmapped\t%s\t-\n" "$prod_file"
  fi
done

echo
echo "== PRIORITY GAPS =="
production_modules | while read -r prod_file; do
  [[ -n "$prod_file" ]] || continue
  test_file="$(matching_test_for "$prod_file" || true)"
  if [[ -z "$test_file" ]] && logic_heavy_module "$prod_file"; then
    printf "missing-unit-test\t%s\n" "$prod_file"
  fi
done

if [[ -n "$COVERAGE_XML" && -f "$COVERAGE_XML" ]]; then
  echo
  echo "== COVERAGE SIGNALS =="
  production_modules | while read -r prod_file; do
    [[ -n "$prod_file" ]] || continue
    line="$(coverage_line "$prod_file" || true)"
    if [[ -n "$line" ]]; then
      printf "%s\t%s\n" "$prod_file" "$line"
    fi
  done
fi

if [[ -n "$BASE_REF" ]]; then
  echo
  echo "== CHANGED MODULES =="
  diff_changed_modules

  echo
  echo "== CHANGE DECISIONS =="
  diff_changed_modules | while read -r changed_file; do
    [[ -n "$changed_file" ]] || continue
    test_file="$(matching_test_for "$changed_file" || true)"
    if [[ -z "$test_file" ]] && logic_heavy_module "$changed_file"; then
      printf "create\t%s\tmissing-test-for-changed-logic\n" "$changed_file"
    elif [[ -n "$test_file" ]] && file_contains_behavioral_diff "$changed_file"; then
      printf "update\t%s\tbehavioral-diff\t%s\n" "$changed_file" "$test_file"
    else
      printf "no-change\t%s\tno-strong-test-signal\t%s\n" "$changed_file" "${test_file:--}"
    fi
  done
fi

if [[ -n "$TEST_RESULTS_DIR" && -d "$TEST_RESULTS_DIR" ]]; then
  echo
  echo "== FAILING TESTS =="
  failing_test_files | while read -r output_file; do
    [[ -n "$output_file" ]] || continue
    if ! rg -q 'FAILED|ERROR' "$output_file"; then
      continue
    fi

    cause="$(failure_cause_for_output "$output_file")"
    summary="$(failure_summary_for_output "$output_file")"

    printf "failing-test\t%s\t%s\t%s\n" "$output_file" "$cause" "$summary"
  done

  echo
  echo "== TEST MAINTENANCE DECISIONS =="
  failing_test_files | while read -r output_file; do
    [[ -n "$output_file" ]] || continue
    if ! rg -q 'FAILED|ERROR' "$output_file"; then
      continue
    fi

    cause="$(failure_cause_for_output "$output_file")"

    if [[ "$cause" == "broken-test-fixture" || "$cause" == "missing-dependency" ]]; then
      printf "update-test\t%s\tfix-test-fixture\n" "$output_file"
    elif [[ "$cause" == "assertion-failure" ]]; then
      printf "update-test\t%s\treview-behavioral-regression\n" "$output_file"
    else
      printf "review-test\t%s\tmanual-analysis-needed\n" "$output_file"
    fi
  done
fi
