---
component: example-skill
component_type: skill
version_tested: v0.1.0
---

# Tests — example-skill

## Test Cases

### TC-01 — Happy path: basic usage

**Input:**
```
/tw-example-skill target="path/to/file.ts"
```

**Expected behavior:**
- Model reads the file at `path/to/file.ts`
- Model produces output in the defined format
- No error messages

**Expected output structure:**
```
[Define what a passing output looks like]
```

**Pass criteria:** Output contains [specific verifiable element].

---

### TC-02 — Optional parameter: verbose mode

**Input:**
```
/tw-example-skill target="path/to/file.ts" verbose=true
```

**Expected behavior:**
- Same as TC-01 plus additional detail in output

**Pass criteria:** Output is longer than TC-01 and includes [specific element].

---

### TC-03 — Edge case: missing required parameter

**Input:**
```
/tw-example-skill
```

**Expected behavior:**
- Model asks for the missing `target` parameter
- Does NOT attempt to run without it

**Pass criteria:** Model requests the parameter clearly before proceeding.

---

### TC-04 — Edge case: target does not exist

**Input:**
```
/tw-example-skill target="nonexistent/path.ts"
```

**Expected behavior:**
- Model reports clearly that the file was not found
- Does NOT produce a partial or fabricated output

**Pass criteria:** Response contains a clear "not found" message.

---

## Fixtures

Test files used by the test cases above:

| File | Used in | Description |
|---|---|---|
| `tests/_fixtures/example.ts` | TC-01, TC-02 | A valid TypeScript file for happy path testing |

## Running Tests

Tests are verified manually or via the CI pipeline:
```bash
# Manual: invoke the skill with each test case and compare output to expected
# CI: GitHub Actions runs automated checks on PR (see .github/workflows/)
```
