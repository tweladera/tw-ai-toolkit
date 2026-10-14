---
name: quality-sprint
description: Autonomous bounded loop that chains test governance and remediation until coverage targets are met or a human checkpoint is reached. Max 3 iterations with mandatory review at iteration 2.
status: stable
version_added: v0.2.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
tags:
  - testing
  - coverage
  - autonomous
  - governance
  - remediation
  - qa
---

# quality-sprint

## Description

Orchestrates a bounded, autonomous quality improvement loop. Chains `/tw-ts-test-governor`
(or `/tw-python-test-governor`) with the matching remediator, runs the test suite to verify,
and iterates until the coverage decision reaches the target state or the maximum iterations
are exhausted.

**Why bounded:** Unbounded loops generate tests that pass but don't test real behavior.
This agent stops at iteration 2 to let the SDET review quality before continuing.
The goal is not to reach a coverage number — it is to improve real test quality.

**Stack auto-detection:** The agent detects whether the repo is TypeScript/NestJS or Python
and selects the correct governor and remediator pair automatically.

## Trigger

When the user says:
- "Run a quality sprint"
- "Improve test coverage automatically"
- "Chain governor and remediator until coverage is good"
- `/tw-quality-sprint`

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `stack` | no | auto | `typescript` or `python`. Auto-detected if omitted. |
| `base_ref` | no | — | Git ref for diff-focused analysis (e.g. `origin/main`) |
| `max_iterations` | no | 3 | Maximum loop iterations. Must be between 1 and 5. |
| `exit_decision` | no | `NO ACTION NEEDED` | Governor overall decision value that triggers successful exit |

## Skills Used

- `/tw-ts-test-governor` — TypeScript stack governance
- `/tw-python-test-governor` — Python stack governance
- `/tw-ts-test-remediator` — TypeScript stack remediation
- `/tw-python-test-remediator` — Python stack remediation

## Flow

```
Step 1 — Detect stack and validate inputs
  Action: Check for package.json + tsconfig.json (TS) or pyproject.toml/setup.py (Python).
          If both or neither detected, ask the user to specify stack explicitly.
          Validate max_iterations is between 1 and 5. Cap at 5 if higher.
          Confirm: "Starting quality sprint | Stack: [stack] | Max iterations: [N] | Exit on: [decision]"

Step 2 — Iteration loop (repeat until exit condition)

  --- ITERATION START ---

  Step 2.1 — Run governor
    Action: Invoke the appropriate governor skill.
            If base_ref provided, pass it.
            If a coverage report exists from a previous iteration, pass its path.
    Output: Governance report with overall decision.

  Step 2.2 — Evaluate exit conditions
    Action: Read the "Overall decision" from the governance report.

    IF overall decision == exit_decision:
      → EXIT LOOP: SUCCESS
      Output: "Quality sprint complete in [N] iteration(s). Coverage target met."
              Show final coverage summary table.

    IF current_iteration >= max_iterations:
      → EXIT LOOP: MAX REACHED
      Output: "Quality sprint reached max iterations ([N]). Manual review required."
              Show current state and pending gaps.

    IF current_iteration == 2:
      → HUMAN CHECKPOINT (mandatory — do not skip)
      Present:
        "Quality Sprint — Checkpoint at Iteration 2
        Current state: [overall decision]
        Modules fixed so far: [count]
        Remaining gaps: [count]
        Generated tests pass: [Y/N]

        Review the tests created in iteration 1 before continuing.
        Warning: Generated tests should assert real behavior, not just reach coverage %.
        Look for: assertions with toBeTruthy() only, tests with no meaningful When/Then.

        Continue? (yes / stop / skip-remediator)"

      If user says stop → EXIT LOOP: CHECKPOINT STOP
      If user says skip-remediator → go to Step 2.1 (next iteration, no remediation)
      If user says yes → continue to Step 2.3

  Step 2.3 — Run remediator
    Action: Invoke the appropriate remediator skill.
            Pass the governance report from Step 2.1.
    Output: Files created or updated, per-module coverage table.

  Step 2.4 — Verify
    Action: Run the test suite to confirm generated tests pass.
            TypeScript: npm run test:cov -- --coverage-reporters=json-summary || true
            Python: pytest --cov=. --cov-report=xml || true
    Output: Test run result (pass count, fail count, coverage %).

  Step 2.5 — Assess iteration result
    Action: Check if generated tests are passing.
    IF >20% of newly generated tests fail:
      Pause and report: "High failure rate in generated tests ([N] failing).
                         This may indicate a mock setup issue or incorrect test generation.
                         Review before continuing."
      Ask: "Fix failing tests manually and continue? Or stop the sprint?"
      If stop → EXIT LOOP: CHECKPOINT STOP

  Step 2.6 — Increment iteration counter and return to Step 2.1

  --- ITERATION END ---
```

## Outputs

### On SUCCESS exit
```
Quality Sprint — Completed
Iterations: N
Stack: [stack]

Coverage progression:
  Iteration 1: [starting decision] → [modules fixed]
  Iteration 2: [decision] → [modules fixed]  [CHECKPOINT REVIEWED]
  Iteration 3: NO ACTION NEEDED ← exit

Final state:
  [Coverage summary table from last governor run]

Files created: [list of new spec files]
Files updated: [list of updated spec files]

Recommended next step:
  Run /tw-contract-coverage to check integration coverage gaps.
```

### On MAX REACHED exit
```
Quality Sprint — Max Iterations Reached ([N])
Stack: [stack]

Last governor decision: [decision]
Remaining gaps: [list of modules still needing action]

Coverage progression:
  [table per iteration]

Recommended action:
  - Review remaining gaps manually
  - Consider raising max_iterations for next sprint
  - Or investigate why coverage is not converging (systemic issue?)
```

### On CHECKPOINT STOP exit
```
Quality Sprint — Stopped at User Request (Iteration [N])
Stack: [stack]

State at checkpoint:
  [Coverage summary table]
  [Remaining gaps]

To resume: /tw-quality-sprint (will start fresh from current state)
To review generated tests: [list of files created so far]
```

## Notes

- This agent does not skip the human checkpoint at iteration 2. It is mandatory.
- Generated tests from the remediator are not guaranteed to be high quality — always review.
- Coverage % is a lagging indicator. If tests reach the target via trivial assertions,
  the sprint exits successfully but quality is still low. Use the checkpoint to review.
- Do not set max_iterations above 3 for a first run on a new codebase.
- If the sprint is not converging after 2 iterations, the root cause is likely a systemic issue
  (broken mocks, missing fixtures, wrong test framework config) — fix that first.
