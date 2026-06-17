---
component: scaffold-component
component_type: agent
version_tested: v0.1.0
---

# Tests — scaffold-component

## Test Cases

### TC-01 — Happy path: scaffold a new skill

**Input:**
```
/tw-scaffold-component type=skill name=test-scaffolded-skill
```

**Expected behavior:**
1. Agent validates inputs (type and name are valid)
2. Agent copies `skills/_template/` to `skills/test-scaffolded-skill/`
3. Agent updates frontmatter: `name` → `test-scaffolded-skill`, `version_added` from registry
4. Agent runs `/tw-lint-component skills/test-scaffolded-skill` — expects errors (placeholders)
5. Agent reports the list of fields the user still needs to fill

**Expected output contains:**
- Confirmation that `skills/test-scaffolded-skill/` was created
- A "Next steps" list naming the unfilled required fields
- No claim that the component is ready to use

**Pass criteria:** Directory exists, frontmatter `name` field matches, user gets actionable next steps.

**Cleanup:** `rm -rf skills/test-scaffolded-skill`

---

### TC-02 — Happy path: scaffold an agent

**Input:**
```
/tw-scaffold-component type=agent name=test-scaffolded-agent
```

**Expected behavior:**
- `agents/test-scaffolded-agent/` created from `agents/_template/`
- `name` field in `agent.md` is `test-scaffolded-agent`

**Pass criteria:** Directory exists with correct `name` in frontmatter.

**Cleanup:** `rm -rf agents/test-scaffolded-agent`

---

### TC-03 — Invalid type

**Input:**
```
/tw-scaffold-component type=widget name=my-widget
```

**Expected behavior:**
- Agent reports that `widget` is not a valid component type
- Lists valid types: skill, agent, prompt, rule, hook, mcp
- Does NOT create any directory

**Pass criteria:** No directory created. Clear error listing valid types.

---

### TC-04 — Name with tw- prefix (auto-strip)

**Input:**
```
/tw-scaffold-component type=skill name=tw-my-skill
```

**Expected behavior:**
- Agent detects the `tw-` prefix in the name
- Strips it automatically: uses `my-skill` as the component name
- Warns the user: "Stripped 'tw-' prefix from name — components are stored without it"

**Pass criteria:** Directory `skills/my-skill/` created (NOT `skills/tw-my-skill/`). Warning shown.

**Cleanup:** `rm -rf skills/my-skill`

---

### TC-05 — Component already exists

**Setup:** `skills/sync-context/` already exists (it's a real component).

**Input:**
```
/tw-scaffold-component type=skill name=sync-context
```

**Expected behavior:**
- Agent detects `skills/sync-context/` already exists
- Does NOT overwrite it
- Reports clearly: "Component already exists at skills/sync-context/"

**Pass criteria:** Existing directory is untouched. No overwrite.

---

### TC-06 — Invalid name format

**Input:**
```
/tw-scaffold-component type=skill name=My New Skill
```

**Expected behavior:**
- Agent rejects the name (contains spaces, not kebab-case)
- Suggests the corrected form: `my-new-skill`
- Does NOT create any directory

**Pass criteria:** No directory created. Corrected name suggested.

---

## Fixtures

None required — uses existing templates as source.
