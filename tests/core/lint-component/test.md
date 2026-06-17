---
component: lint-component
component_type: skill
version_tested: v0.1.0
---

# Tests — lint-component

## Test Cases

### TC-01 — Happy path: valid skill passes

**Setup:** Create a temporary component directory using the valid fixture:
```bash
mkdir -p skills/test-fixture
cp tests/_fixtures/valid-skill.md skills/test-fixture/skill.md
```

**Input:**
```
/tw-lint-component path=skills/test-fixture
```

**Expected output:**
```
lint-component: skills/test-fixture
─────────────────────────────────
No issues found.
Status: PASS
```

**Pass criteria:** Output contains "Status: PASS" and no ERROR lines.

**Cleanup:** `rm -rf skills/test-fixture`

---

### TC-02 — Invalid skill: multiple errors detected

**Setup:** Create a temporary component directory using the invalid fixture:
```bash
mkdir -p skills/test-invalid
cp tests/_fixtures/invalid-skill.md skills/test-invalid/skill.md
```

**Input:**
```
/tw-lint-component path=skills/test-invalid
```

**Expected output contains ALL of the following errors:**
- `frontmatter.name` mismatch (`wrong-name-intentional` vs `test-invalid`)
- `frontmatter.status` invalid value (`unknown-status`)
- `frontmatter.version_added` invalid format (`1.0.0` missing `v` prefix)
- `frontmatter.compatible_with.claude_code` invalid value (`maybe`)
- Contains placeholder text (`example-skill`, `One sentence describing`, `[REQUIRED]`)
- Missing required section `## When to Use`
- Missing required section `## Examples`

**Pass criteria:** Output contains "Status: FAIL" and reports at least 5 distinct ERRORs.

**Cleanup:** `rm -rf skills/test-invalid`

---

### TC-03 — Missing definition file

**Setup:**
```bash
mkdir -p skills/test-empty
```

**Input:**
```
/tw-lint-component path=skills/test-empty
```

**Expected behavior:**
- Model reports that `skill.md` was not found
- Status: FAIL

**Pass criteria:** Output contains "not found" and "Status: FAIL". Does not crash.

**Cleanup:** `rm -rf skills/test-empty`

---

### TC-04 — Unknown component type path

**Input:**
```
/tw-lint-component path=unknown/my-component
```

**Expected behavior:**
- Model reports that the path prefix is not a recognized component type
- Status: FAIL
- Does not attempt to read any files

**Pass criteria:** Output contains a clear "unrecognized type" or similar message.

---

### TC-05 — Agent with invalid skill reference

**Setup:** Create a temporary agent that references a non-existent skill:
```bash
mkdir -p agents/test-bad-agent
cat > agents/test-bad-agent/agent.md << 'EOF'
---
name: test-bad-agent
description: Test agent with bad skill reference.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: none
  codex: none
tags:
  - test
---
# test-bad-agent
## Description
Test agent.
## Trigger
Testing.
## Skills Used
- /tw-nonexistent-skill — does not exist
## Flow
Step 1 — does nothing
## Outputs
Nothing.
EOF
```

**Input:**
```
/tw-lint-component path=agents/test-bad-agent
```

**Expected behavior:**
- Model detects that `/tw-nonexistent-skill` is referenced but not in registry.json
- Reports this as an ERROR

**Pass criteria:** Output contains ERROR about `nonexistent-skill` reference.

**Cleanup:** `rm -rf agents/test-bad-agent`

---

### TC-06 — Valid component: warning only (no README)

**Setup:** Same as TC-01 but without a README.md (the valid fixture has no README).

**Input:**
```
/tw-lint-component path=skills/test-fixture
```

**Expected behavior:**
- No ERRORs
- One WARNING about missing README.md
- Status: PASS (warnings do not cause FAIL)

**Pass criteria:** Output contains "Status: PASS" and one WARNING line.

---

## Fixtures

| File | Used in |
|---|---|
| `tests/_fixtures/valid-skill.md` | TC-01, TC-06 |
| `tests/_fixtures/invalid-skill.md` | TC-02 |
