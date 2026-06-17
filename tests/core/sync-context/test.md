---
component: sync-context
component_type: skill
version_tested: v0.1.0
---

# Tests — sync-context

## Test Cases

### TC-01 — Happy path: sync from toolkit root

**Input:**
```
/tw-sync-context
```

**Setup:** Run inside the `tw-ai-toolkit` repo with at least one component file present.

**Expected behavior:**
- Model runs `bash scripts/sync-registry.sh`
- Model runs `bash scripts/sync-snapshots.sh`
- Both commands complete without error
- Model reads `context/CHECKPOINT.md` and reports the result

**Expected output contains:**
- Number of components indexed (e.g. "7 components")
- A git hash (8 hex characters)
- A timestamp

**Pass criteria:** Output contains a component count, a git hash, and a sync timestamp.

---

### TC-02 — Happy path: sync from consumer repo

**Input:**
```
/tw-sync-context
```

**Setup:** Run inside a consumer repo where toolkit is installed at `.ai/toolkit/`.

**Expected behavior:**
- Model detects it is NOT inside the toolkit repo
- Model runs scripts from `.ai/toolkit/scripts/` path instead of `scripts/`
- Reports the same output as TC-01

**Pass criteria:** Scripts run from the correct path without manual correction.

---

### TC-03 — Stale snapshot detection

**Setup:** Manually modify `context/CHECKPOINT.md` to contain a fake git hash (`aaaaaaaa`).

**Input:**
```
/tw-sync-context
```

**Expected behavior:**
- Model detects the mismatch before running (optional)
- Model runs sync regardless
- After sync, CHECKPOINT.md contains the real current hash

**Pass criteria:** After invocation, `context/CHECKPOINT.md` contains the actual HEAD hash.

---

### TC-04 — Edge case: script fails

**Setup:** Temporarily make `scripts/sync-registry.sh` non-executable (`chmod -x`).

**Input:**
```
/tw-sync-context
```

**Expected behavior:**
- Model reports the exact error from the failed script
- Model does NOT attempt to run `sync-snapshots.sh` after the failure
- Model tells the user what likely caused the failure

**Pass criteria:** Clear error message. No second script run after first failure.

---

## Fixtures

None required. Uses the live toolkit repo as its own fixture.

## Notes

- TC-02 requires a consumer repo with the toolkit installed to test.
- TC-04 requires temporarily breaking a file — restore permissions after testing.
