#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash .ai/toolkit/skills/python-test-remediator/scripts/parse_governance_report.sh <report-file>" >&2
  exit 1
fi

REPORT_FILE="$1"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "Report file not found: $REPORT_FILE" >&2
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "This script requires rg (ripgrep)." >&2
  exit 1
fi

echo "== REMEDIATION TARGETS =="

# Parse missing-unit-test actions
rg '^missing-unit-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  module_file="$(printf '%s\n' "$line" | awk '{print $2}')"

  # Convert module path to test path
  # src/module.py -> tests/test_module.py
  # src/services/processor.py -> tests/test_processor.py
  module_name="$(basename "${module_file%.py}")"
  test_file="tests/test_${module_name}.py"

  # Check if project uses tests/unit/ structure
  if [[ -d "tests/unit" ]]; then
    test_file="tests/unit/test_${module_name}.py"
  fi

  printf "create-test\t%s\t%s\n" "$module_file" "$test_file"
done || true

# Parse update-test actions
rg '^update-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  test_module="$(printf '%s\n' "$line" | awk '{print $2}')"
  prod_file="$(printf '%s\n' "$line" | awk '{print $3}')"
  reason="$(printf '%s\n' "$line" | awk '{print $4}')"

  if [[ "$prod_file" != "-" ]]; then
    module_name="$(basename "${prod_file%.py}")"
    test_file="tests/test_${module_name}.py"

    # Check if project uses tests/unit/ structure
    if [[ -d "tests/unit" ]]; then
      test_file="tests/unit/test_${module_name}.py"
    fi
  else
    test_file="-"
  fi

  printf "update-test\t%s\t%s\t%s\t%s\n" "$test_module" "$prod_file" "$test_file" "$reason"
done || true

# Parse review-test actions
rg '^review-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  test_module="$(printf '%s\n' "$line" | awk '{print $2}')"
  prod_file="$(printf '%s\n' "$line" | awk '{print $3}')"
  reason="$(printf '%s\n' "$line" | awk '{print $4}')"
  printf "review-test\t%s\t%s\t%s\n" "$test_module" "$prod_file" "$reason"
done || true
