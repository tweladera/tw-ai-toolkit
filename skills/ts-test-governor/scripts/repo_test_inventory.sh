#!/usr/bin/env bash
set -euo pipefail

BASE_REF=""
COVERAGE_SUMMARY=""
TEST_RESULTS_DIR=""
REPO_ROOT="${PWD}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-ref)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --coverage-summary)
      COVERAGE_SUMMARY="${2:-}"
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

# ─── Helpers ─────────────────────────────────────────────────────────────────

classify_test() {
  local file="$1"

  # Support files: shared fixtures, test helpers, test factories
  if [[ "$file" =~ \.factory\.ts$ ]] || \
     [[ "$file" =~ test-helpers/ ]] || \
     [[ "$file" =~ /__fixtures__/ ]]; then
    echo "support"
    return
  fi

  # Not a spec file
  if [[ ! "$file" =~ \.spec\.ts$ ]]; then
    echo "support"
    return
  fi

  # Integration tests: real DB, real HTTP, Kafka, Docker
  if rg -q 'TypeOrmModule\.forRoot|DataSource.*new |supertest|testcontainers|KafkaClient|createConnection' "$file" 2>/dev/null; then
    echo "integration"
    return
  fi

  echo "unit"
}

production_modules() {
  # Find all *.ts files excluding specs, modules, barrel files, generated code, etc.
  rg --files -g '*.ts' \
    | grep -v '\.spec\.ts$' \
    | grep -v '\.module\.ts$' \
    | grep -v '/node_modules/' \
    | grep -v '/dist/' \
    | grep -v '/coverage/' \
    | grep -v '^src/main\.ts$' \
    | grep -v '/index\.ts$' \
    | grep -v '\.enum\.ts$' \
    | grep -v '\.type\.ts$' \
    | grep -v '\.command\.ts$' \
    | grep -v '\.dto\.ts$' \
    | sort
}

spec_modules() {
  rg --files -g '*.spec.ts' \
    | grep -v '/node_modules/' \
    | grep -v '/dist/' \
    | sort
}

matching_spec_for() {
  local prod_file="$1"
  # Colocated pattern: src/foo/bar.service.ts → src/foo/bar.service.spec.ts
  local spec_file="${prod_file%.ts}.spec.ts"
  if [[ -f "$spec_file" ]]; then
    echo "$spec_file"
    return
  fi

  # Fallback: search by basename in test/ or __tests__/ directories
  local base="${prod_file##*/}"
  local base_no_ext="${base%.ts}"
  local alt
  alt=$(rg --files -g "${base_no_ext}.spec.ts" 2>/dev/null | grep -v '/node_modules/' | head -n 1 || true)
  if [[ -n "$alt" ]]; then
    echo "$alt"
  fi
}

logic_heavy_module() {
  local file="$1"

  # Skip TypeORM entity files with only decorators (no methods)
  if [[ "$file" =~ \.entity\. ]]; then
    if ! rg -q 'public |async |function |if |for |while |throw |return [^;{]' "$file" 2>/dev/null; then
      return 1
    fi
  fi

  # Has logic: conditionals, loops, error handling, async functions, class methods
  if rg -q 'if |for |while |try \{|throw |async |=> |return [^;{]' "$file" 2>/dev/null; then
    return 0
  fi

  return 1
}

coverage_line() {
  local prod_file="$1"

  [[ -n "$COVERAGE_SUMMARY" && -f "$COVERAGE_SUMMARY" ]] || return 0

  # Parse coverage/coverage-summary.json
  # Format: { "total": {...}, "src/foo/bar.ts": { "lines": { "pct": 95.2 } } }
  local key
  # Normalize path: ensure it starts without leading ./
  key="${prod_file#./}"

  node -e "
    try {
      const s = require('./${COVERAGE_SUMMARY}');
      const entry = s['${key}'] || s['./${key}'];
      if (entry && entry.lines) {
        process.stdout.write(entry.lines.pct.toFixed(1) + '% lines covered\n');
      }
    } catch(e) {}
  " 2>/dev/null || true
}

production_from_spec() {
  local spec_file="$1"
  local prod_file="${spec_file%.spec.ts}.ts"
  if [[ -f "$prod_file" ]]; then
    echo "$prod_file"
  fi
}

failing_spec_files() {
  [[ -n "$TEST_RESULTS_DIR" && -d "$TEST_RESULTS_DIR" ]] || return 0

  rg --files "$TEST_RESULTS_DIR" -g '*.xml' 2>/dev/null || true
}

failure_cause_for_output() {
  local output_file="$1"

  if rg -q "Nest can't resolve dependencies" "$output_file" 2>/dev/null; then
    echo "missing-di-provider"
  elif rg -q 'Cannot read properties of undefined\|Cannot read property' "$output_file" 2>/dev/null; then
    echo "broken-mock"
  elif rg -q 'expect(received).toBe\|Expected.*Received' "$output_file" 2>/dev/null; then
    echo "assertion-failure"
  elif rg -q 'Cannot find module\|MODULE_NOT_FOUND' "$output_file" 2>/dev/null; then
    echo "missing-dependency"
  elif rg -q 'FAILED\|● ' "$output_file" 2>/dev/null; then
    echo "test-failure"
  else
    echo "unknown-failure"
  fi
}

failure_summary_for_output() {
  local output_file="$1"
  rg 'FAILED|●|Cannot read|resolve dependencies' "$output_file" 2>/dev/null | head -n 3 | cut -c1-180
}

diff_changed_modules() {
  [[ -n "$BASE_REF" ]] || return 0
  git diff --name-only "$BASE_REF"...HEAD -- '*.ts' 2>/dev/null | \
    grep -v '\.spec\.ts$' | \
    grep -v '\.module\.ts$' | \
    grep -v '/node_modules/' | \
    grep -v 'main\.ts$' | \
    sort || true
}

file_contains_behavioral_diff() {
  local file="$1"
  [[ -n "$BASE_REF" ]] || return 1

  git diff --unified=0 "$BASE_REF"...HEAD -- "$file" 2>/dev/null | \
    rg -q '^[+-].*(async |function |=>\s*\{|if \(|for \(|while \(|throw |return [^;{]|class |implements |export (class|function|const))'
}

# ─── Output ──────────────────────────────────────────────────────────────────

echo "== TEST INVENTORY =="
spec_modules | while read -r spec_file; do
  [[ -n "$spec_file" ]] || continue
  printf "%s\t%s\n" "$(classify_test "$spec_file")" "$spec_file"
done

echo
echo "== MODULE TO TEST MAP =="
production_modules | while read -r prod_file; do
  [[ -n "$prod_file" ]] || continue
  spec_file="$(matching_spec_for "$prod_file" || true)"
  if [[ -n "$spec_file" ]]; then
    printf "covered\t%s\t%s\n" "$prod_file" "$spec_file"
  else
    printf "unmapped\t%s\t-\n" "$prod_file"
  fi
done

echo
echo "== PRIORITY GAPS =="
production_modules | while read -r prod_file; do
  [[ -n "$prod_file" ]] || continue
  spec_file="$(matching_spec_for "$prod_file" || true)"
  if [[ -z "$spec_file" ]] && logic_heavy_module "$prod_file"; then
    printf "missing-unit-test\t%s\n" "$prod_file"
  fi
done

if [[ -n "$COVERAGE_SUMMARY" && -f "$COVERAGE_SUMMARY" ]]; then
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
    spec_file="$(matching_spec_for "$changed_file" || true)"
    if [[ -z "$spec_file" ]] && logic_heavy_module "$changed_file"; then
      printf "create\t%s\tmissing-spec-for-changed-logic\n" "$changed_file"
    elif [[ -n "$spec_file" ]] && file_contains_behavioral_diff "$changed_file"; then
      printf "update\t%s\tbehavioral-diff\t%s\n" "$changed_file" "$spec_file"
    else
      printf "no-change\t%s\tno-strong-test-signal\t%s\n" "$changed_file" "${spec_file:--}"
    fi
  done
fi

if [[ -n "$TEST_RESULTS_DIR" && -d "$TEST_RESULTS_DIR" ]]; then
  echo
  echo "== FAILING TESTS =="
  failing_spec_files | while read -r output_file; do
    [[ -n "$output_file" ]] || continue
    if ! rg -q 'FAILED|failures="[^0]' "$output_file" 2>/dev/null; then
      continue
    fi

    cause="$(failure_cause_for_output "$output_file")"
    summary="$(failure_summary_for_output "$output_file")"

    printf "failing-test\t%s\t%s\t%s\n" "$output_file" "$cause" "$summary"
  done

  echo
  echo "== TEST MAINTENANCE DECISIONS =="
  failing_spec_files | while read -r output_file; do
    [[ -n "$output_file" ]] || continue
    if ! rg -q 'FAILED|failures="[^0]' "$output_file" 2>/dev/null; then
      continue
    fi

    cause="$(failure_cause_for_output "$output_file")"

    if [[ "$cause" == "broken-mock" || "$cause" == "missing-di-provider" || "$cause" == "missing-dependency" ]]; then
      printf "update-test\t%s\tfix-mock-or-provider\n" "$output_file"
    elif [[ "$cause" == "assertion-failure" ]]; then
      printf "update-test\t%s\treview-behavioral-regression\n" "$output_file"
    else
      printf "review-test\t%s\tmanual-analysis-needed\n" "$output_file"
    fi
  done
fi
