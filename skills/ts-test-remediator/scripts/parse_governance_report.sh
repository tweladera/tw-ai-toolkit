#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash .ai/toolkit/skills/ts-test-remediator/scripts/parse_governance_report.sh <report-file>" >&2
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

# Parse missing-unit-test actions (from PRIORITY GAPS section)
rg '^missing-unit-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  module_file="$(printf '%s\n' "$line" | awk '{print $2}')"

  # Colocated spec pattern: src/foo/bar.service.ts → src/foo/bar.service.spec.ts
  spec_file="${module_file%.ts}.spec.ts"

  printf "create-test\t%s\t%s\n" "$module_file" "$spec_file"
done || true

# Parse update-test actions (from CHANGE DECISIONS or FAILING TESTS section)
rg '^update-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  # Format: update-test <test_output_file_or_spec> <reason>
  spec_or_output="$(printf '%s\n' "$line" | awk '{print $2}')"
  reason="$(printf '%s\n' "$line" | awk '{print $3}')"

  # Derive production module from spec file
  # src/foo/bar.service.spec.ts → src/foo/bar.service.ts
  if [[ "$spec_or_output" =~ \.spec\.ts$ ]]; then
    prod_file="${spec_or_output%.spec.ts}.ts"
    spec_file="$spec_or_output"
  else
    # It's a test results XML — try to find related spec
    prod_file="-"
    spec_file="-"
  fi

  printf "update-test\t%s\t%s\t%s\n" "$spec_file" "$prod_file" "$reason"
done || true

# Parse update actions from CHANGE DECISIONS section
rg '^update[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  changed_file="$(printf '%s\n' "$line" | awk '{print $2}')"
  reason="$(printf '%s\n' "$line" | awk '{print $3}')"
  spec_file="$(printf '%s\n' "$line" | awk '{print $4}')"

  if [[ "$spec_file" == "-" || -z "$spec_file" ]]; then
    spec_file="${changed_file%.ts}.spec.ts"
  fi

  printf "update-test\t%s\t%s\t%s\n" "$spec_file" "$changed_file" "$reason"
done || true

# Parse create actions from CHANGE DECISIONS section
rg '^create[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  changed_file="$(printf '%s\n' "$line" | awk '{print $2}')"
  reason="$(printf '%s\n' "$line" | awk '{print $3}')"

  spec_file="${changed_file%.ts}.spec.ts"

  printf "create-test\t%s\t%s\t%s\n" "$changed_file" "$spec_file" "$reason"
done || true

# Parse review-test actions
rg '^review-test[[:space:]]+' "$REPORT_FILE" | while read -r line; do
  spec_or_output="$(printf '%s\n' "$line" | awk '{print $2}')"
  reason="$(printf '%s\n' "$line" | awk '{print $3}')"
  printf "review-test\t%s\t%s\n" "$spec_or_output" "$reason"
done || true
