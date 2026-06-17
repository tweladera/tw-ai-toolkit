---
component: install-toolkit
component_type: skill
version_tested: v0.1.0
---

# Tests — install-toolkit

> Note: These tests require a separate test consumer repo to avoid modifying real repos.
> Create a temp git repo for each test case: `git init /tmp/test-consumer-repo`

## Test Cases

### TC-01 — Happy path: fresh installation

**Setup:**
```bash
git init /tmp/test-consumer-repo
cd /tmp/test-consumer-repo
```

**Input (from Claude Code, inside the tw-ai-toolkit repo):**
```
/tw-install-toolkit repo_path="/tmp/test-consumer-repo"
```

**Expected behavior:**
1. Skill verifies `/tmp/test-consumer-repo` is a git repo ✓
2. Skill resolves the latest version tag
3. Skill asks for confirmation before proceeding
4. Skill adds `.ai/toolkit` as a git submodule
5. Skill creates `.ai/config.json` with correct `toolkit_version`
6. Skill creates `.ai/AGENTS.md` with toolkit context pointer
7. Skill asks whether to create/update `CLAUDE.md`
8. Skill copies `.env.toolkit.example`
9. Skill asks whether to configure Dependabot
10. Skill validates: all expected files exist
11. Skill shows final success message with next steps

**Pass criteria:**
- `.ai/toolkit/` exists and contains `AGENTS.md`
- `.ai/config.json` exists with correct `toolkit_version`
- `.ai/AGENTS.md` exists
- `CLAUDE.md` exists (if user confirmed)

**Cleanup:** `rm -rf /tmp/test-consumer-repo`

---

### TC-02 — Already installed: graceful skip

**Setup:** `/tmp/test-consumer-repo` with toolkit already installed (from TC-01).

**Input:**
```
/tw-install-toolkit repo_path="/tmp/test-consumer-repo"
```

**Expected behavior:**
- Skill detects `.ai/toolkit/` already exists
- Reports current installed version
- Points user to `update.sh` for upgrading
- Does NOT attempt reinstallation

**Pass criteria:** "Already installed" message shown. No files modified.

---

### TC-03 — Non-git directory

**Setup:**
```bash
mkdir /tmp/not-a-git-repo
```

**Input:**
```
/tw-install-toolkit repo_path="/tmp/not-a-git-repo"
```

**Expected behavior:**
- Skill detects no `.git/` directory
- Reports: "not a git repository"
- Does NOT create any files

**Pass criteria:** Clear error. No files created.

**Cleanup:** `rm -rf /tmp/not-a-git-repo`

---

### TC-04 — Specific version install

**Setup:** Fresh git repo at `/tmp/test-version-install`.

**Input:**
```
/tw-install-toolkit repo_path="/tmp/test-version-install" version="v0.1.0"
```

**Expected behavior:**
- Skill pins to `v0.1.0` specifically (does not resolve latest)
- `toolkit_version` in `.ai/config.json` is `"v0.1.0"`

**Pass criteria:** Submodule HEAD matches `v0.1.0` tag.

**Cleanup:** `rm -rf /tmp/test-version-install`

---

### TC-05 — Existing CLAUDE.md: append without overwrite

**Setup:**
```bash
git init /tmp/test-append
echo "# My Project\n\nExisting content." > /tmp/test-append/CLAUDE.md
```

**Input (confirm yes to CLAUDE.md update):**
```
/tw-install-toolkit repo_path="/tmp/test-append"
```

**Expected behavior:**
- Skill detects existing `CLAUDE.md`
- Asks to append (not overwrite)
- Existing content is preserved
- Toolkit fragment is added at the end

**Pass criteria:** `CLAUDE.md` contains both "Existing content." AND the toolkit fragment.

**Cleanup:** `rm -rf /tmp/test-append`

---

## Fixtures

None — uses temporary git repos created per test case.

## Notes

- These tests interact with the filesystem and git. Clean up temp repos after each test.
- TC-01 requires network access to resolve the latest version tag.
