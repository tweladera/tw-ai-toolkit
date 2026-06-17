# Testing Strategy

tw-ai-toolkit has two testing layers. Understanding both is important before contributing.

---

## The Core Challenge

Skills and agents are prompt-based — their "logic" lives in natural language instructions
that an AI model interprets. You cannot `assert output == expected` on a language model.

**What we CAN automate:**
- Schema validation (correct frontmatter fields and values)
- Reference integrity (agents reference skills that actually exist)
- Registry consistency (registry.json matches the actual component files)
- Snapshot freshness (context snapshots are up to date)

**What requires human review:**
- Whether the instructions produce the intended behavior
- Whether examples are accurate
- Whether edge cases are handled correctly

---

## Layer 1 — Automated (CI)

Runs on every PR via `scripts/validate.sh` and `.github/workflows/ci.yml`.
**Blocks merges if it fails.**

### What it checks

| Check | What it validates |
|---|---|
| Registry sync | `registry.json` matches current component files (no drift) |
| Frontmatter schema | All required fields present, correct types, no placeholder values |
| Name consistency | Component `name` field matches its directory name |
| Agent references | Skills listed in `## Skills Used` exist in `registry.json` |
| Snapshot freshness | `context/CHECKPOINT.md` git hash matches repo HEAD |
| No template leftovers | No `example-skill`, `[REPLACE:`, or unfilled `[REQUIRED]` markers |

### Running locally

```bash
bash scripts/validate.sh
```

Expected output on a clean repo:
```
[tw-ai-toolkit] Validating...
  Syncing registry...          OK
  Schema: skills/sync-context  PASS
  Schema: skills/lint-component PASS
  Schema: agents/onboard-repo  PASS
  ...
  Agent references             PASS
  Snapshot freshness           PASS
──────────────────────────────────
  7 components checked, 0 errors, 0 warnings
  Status: PASS
```

---

## Layer 2 — Manual (test.md files)

Each component has a `tests/<component-name>/test.md` with documented test cases.
These are run manually or by asking Claude Code to execute them.

### Structure of a test case

```
TC-01 — Happy path
Input:    /tw-skill-name param=value
Expected: [specific verifiable output properties]
Pass if:  [concrete pass criteria]
```

### Running manual tests

Ask Claude Code:
```
Run the test cases in tests/sync-context/test.md and report which pass and which fail.
```

The model will execute each test case and compare the output against the expected behavior.

### When to run manual tests

- Before marking a new component as `stable` (move from `experimental`)
- After significant changes to a component's instructions
- When a user reports unexpected behavior

---

## Test Files for Core Components

| Component | Test file | Status |
|---|---|---|
| `skills/sync-context` | `tests/core/sync-context/test.md` | Available |
| `skills/lint-component` | `tests/core/lint-component/test.md` | Available |
| `skills/install-toolkit` | `tests/core/install-toolkit/test.md` | Available |
| `agents/scaffold-component` | `tests/core/scaffold-component/test.md` | Available |
| `agents/onboard-repo` | `tests/core/onboard-repo/test.md` | Pending |

---

## Adding Tests for a New Component

1. Scaffold the test file:
   ```bash
   cp -r tests/_template/ tests/<component-name>/
   ```

2. Fill in test cases covering:
   - Happy path (normal usage)
   - Optional parameters
   - Edge cases (missing input, invalid input, not found)
   - Expected failure behavior

3. New components must have at least 3 test cases before moving from `experimental` to `stable`.

---

## Fixtures

Reusable test files live in `tests/_fixtures/`:

| File | Purpose |
|---|---|
| `valid-skill.md` | Complete valid skill — used to test lint-component PASS |
| `invalid-skill.md` | Skill with deliberate errors — used to test lint-component FAIL |

---

## CI Pipeline Overview

```
PR opened or updated
        │
        ▼
.github/workflows/ci.yml
        │
        ├── scripts/validate.sh
        │       ├── sync-registry (check for drift)
        │       ├── lint all components (schema)
        │       ├── validate agent references
        │       └── check snapshot freshness
        │
        └── Results posted to PR as check
                ├── PASS → PR can be merged
                └── FAIL → PR blocked until fixed
```
