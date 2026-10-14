---
name: golden-master
description: Captures behavioral snapshots of a system (Golden Master) and compares future runs against them to detect regressions, unintended behavior changes, or legacy-to-new equivalence during migrations.
status: stable
version_added: v0.2.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: mode
    type: string
    required: true
    default: ""
    description: "Operation mode: 'capture' to record a new Golden Master, 'compare' to diff current output against the saved master."
  - name: name
    type: string
    required: true
    default: ""
    description: Identifier for this Golden Master set (e.g. 'order-placement', 'pricing-engine'). Used as directory name under .golden/.
  - name: target
    type: string
    required: false
    default: ""
    description: Command, script, or function path to execute for capture/compare. Required for 'capture'. For 'compare', defaults to same target used during capture (stored in manifest).
  - name: inputs
    type: string
    required: false
    default: ""
    description: Path to a JSON file containing an array of test input objects. If omitted in capture mode, Claude will prompt for or infer representative inputs.
  - name: tolerance
    type: string
    required: false
    default: "normalized"
    description: "Comparison mode: 'strict' (exact byte match) or 'normalized' (masks UUIDs, timestamps, auto-increment IDs before diffing). Default: normalized."
  - name: version
    type: string
    required: false
    default: ""
    description: Version tag for the captured master (e.g. 'v1.2.0', 'pre-refactor'). Defaults to current git short SHA.
tags:
  - golden-master
  - regression
  - migration
  - equivalence
  - snapshot
  - qa
invocation: tw-golden-master
---

# golden-master

## Description

Implements the Golden Master testing pattern for behavioral equivalence verification.

In **capture mode**, runs a defined set of inputs through the current system and saves the
outputs as a normalized snapshot. In **compare mode**, runs the same inputs through the
current (possibly refactored or migrated) system and diffs the outputs against the saved
master — detecting regressions, silent behavioral changes, or proving legacy equivalence.

**Primary use cases for an SDET team:**
- Refactoring safety: prove the refactored module produces identical outputs
- Legacy migration: verify the new system is black-box equivalent to the old one
- Regression baseline: detect unintended behavioral changes before release

**Critical limitation (acknowledged):** A Golden Master is only as good as its inputs.
If the original system had bugs, the master captures those bugs as expected behavior.
Always review captured outputs before committing them as the reference.

## When to Use

- Before refactoring a module with no tests: `mode=capture` first, refactor, then `mode=compare`
- During a legacy-to-new system migration: capture legacy outputs, compare new system outputs
- Before a release: compare production-equivalent output against the last known-good master
- When a test suite passes but you suspect silent behavioral changes

## Instructions

### Step 1 — Validate Mode and Inputs

**For `capture` mode:**
- `name` must be provided
- `target` must be provided (command or path)
- If `inputs` is not provided, pause and ask the user for representative test inputs.
  Do not invent inputs without explicit confirmation — inputs define the scope of the master.
- Warn the user: *"The Golden Master will capture current behavior including any bugs present.
  Review the captured outputs before committing them as the reference."*

**For `compare` mode:**
- `name` must match an existing directory under `.golden/`
- If `.golden/{{name}}/manifest.json` does not exist, stop and report: "No Golden Master found
  for '{{name}}'. Run with mode=capture first."
- Load `target` from `manifest.json` if not explicitly provided

### Step 2 — Resolve Version Tag

```bash
# If no version provided, use git short SHA
git rev-parse --short HEAD 2>/dev/null || echo "no-git"
```

For `capture`: use this as the version tag.
For `compare`: load `baseline_version` from `manifest.json`.

### Step 3a — CAPTURE: Execute and Serialize Outputs

For each input in the inputs array:

```bash
mkdir -p .golden/{{name}}/{{version}}/
```

Execute `target` with the input. Capture stdout, stderr, and exit code.

**Apply normalization before saving** (see `references/masking-guide.md`):
- Replace UUIDs (v4 format) with `<UUID>`
- Replace ISO 8601 timestamps with `<TIMESTAMP>`
- Replace auto-increment integer IDs matching pattern `"id": <integer>` with `"id": <ID>`
- Replace values in fields named: `password`, `token`, `secret`, `key`, `authorization`
  with `<REDACTED>`
- Do NOT normalize: business data, amounts, status codes, error messages, counts, booleans

Save each output to:
```
.golden/{{name}}/{{version}}/input-{N}.json
```

Format:
```json
{
  "input_index": 0,
  "input": { ... },
  "output": {
    "stdout": "...",
    "stderr": "",
    "exit_code": 0,
    "normalized": true
  }
}
```

Write `.golden/{{name}}/manifest.json`:
```json
{
  "name": "{{name}}",
  "baseline_version": "{{version}}",
  "target": "{{target}}",
  "tolerance": "{{tolerance}}",
  "captured_at": "<ISO_TIMESTAMP>",
  "input_count": N,
  "normalization": ["uuid", "timestamp", "auto-id", "secrets"]
}
```

Symlink `.golden/{{name}}/latest` → `.golden/{{name}}/{{version}}/` for easy comparison.

Confirm:
```
Golden Master captured
Name: {{name}} | Version: {{version}}
Inputs: N | Target: {{target}}
Location: .golden/{{name}}/{{version}}/
IMPORTANT: Review captured outputs before committing as reference.
```

### Step 3b — COMPARE: Diff Against Master

Load inputs from `.golden/{{name}}/manifest.json` (same inputs used during capture).

Execute `target` with each input. Apply **identical normalization** as during capture.

For each input, diff current output vs Golden Master output:

**Diff algorithm:**
- Parse both as JSON (if JSON) or line-by-line (if plain text)
- Compare field by field
- Classify each difference:
  - `IDENTICAL` — exact match after normalization
  - `EQUIVALENT` — only normalized tokens differ (UUID, timestamp) → expected
  - `DIVERGENT` — actual content difference → potential regression

### Step 4 — COMPARE: Generate Equivalence Report

```markdown
## Golden Master Comparison Report
**Name:** {{name}}
**Baseline version:** {{baseline_version}} (captured: {{captured_at}})
**Current run:** {{current_version}} ({{current_timestamp}})
**Tolerance:** {{tolerance}}
**Overall result:** IDENTICAL | EQUIVALENT | DIVERGENT

### Results per Input

| Input | Result | Differences |
|-------|--------|-------------|
| input-0 | IDENTICAL | — |
| input-1 | EQUIVALENT | 2 normalized tokens (UUID, timestamp) |
| input-2 | DIVERGENT | See details below |

### Divergence Details

For each DIVERGENT input, show the exact diff:
\`\`\`diff
- "status": "PENDING"
+ "status": "PROCESSING"
\`\`\`
**Classification:** Intentional change / Unknown regression / Confirmed bug fix
**Action required:** Confirm if intentional → update Golden Master. If unknown → investigate.
```

### Step 5 — COMPARE: Recommend Action

```
If IDENTICAL or EQUIVALENT only:
  "No behavioral regressions detected. Safe to proceed."

If any DIVERGENT:
  "N divergences detected. Review each before releasing."
  "To accept changes as new baseline: /tw-golden-master mode=capture name={{name}} version=<new-tag>"
  "To investigate: check items marked DIVERGENT in the report above."
```

## Examples

### Example 1 — Capture before a refactor

```
/tw-golden-master mode=capture name=pricing-engine target="python scripts/run_pricing.py" inputs=tests/golden/pricing-inputs.json
```

### Example 2 — Compare after refactor

```
/tw-golden-master mode=compare name=pricing-engine
```

### Example 3 — Migration equivalence verification

```
# Capture legacy system outputs
/tw-golden-master mode=capture name=order-flow-legacy target="./legacy-app/run_order.sh" inputs=tests/golden/order-inputs.json version=legacy

# After migration, compare new system
/tw-golden-master mode=compare name=order-flow-legacy target="./new-app/run_order.sh"
```

### Example 4 — Strict mode (no normalization)

```
/tw-golden-master mode=compare name=report-generator tolerance=strict
```

## Dependencies

- `target` must be a runnable command or script in the working environment
- Git must be available for automatic version tagging (optional)
- `.golden/` directory will be created automatically — add to `.gitignore` or commit selectively
- See `references/masking-guide.md` for normalization rules and how to add custom masks

## Notes

- Never commit Golden Masters containing PII, secrets, or sensitive business data
- A Golden Master captures bugs as expected behavior — always review before committing
- `tolerance=normalized` is the default and recommended setting for most use cases
- `tolerance=strict` is only appropriate for deterministic systems with no random IDs or timestamps
- The `.golden/` directory should be excluded from standard test runs — it is a QA artifact, not a test suite
