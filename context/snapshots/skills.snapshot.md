# Skills Snapshot (L3)

> Auto-generated on 2026-06-18 00:33 UTC. Do not edit manually.
> For a quick overview of all types, load `context/snapshot.md` (L2).

---

## install-toolkit

**Description:** Guides the user through installing tw-ai-toolkit into a consumer repository.

**Invocation:** `/tw-install-toolkit`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `repo_path` | string | false | "." | Absolute or relative path to the consumer repo root (defaults to current directory) |
| `version` | string | false | "latest" | Toolkit version tag to install (e.g. v1.0.0). Defaults to latest stable tag. |

**Tags:** `setup`, `installation`, `onboarding`

**Added in:** v0.1.0

**Definition file:** `skills/install-toolkit/skill.md`

---

## lint-component

**Description:** Validates that a toolkit component follows all required conventions and schema rules.

**Invocation:** `/tw-lint-component`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | true | "" | Relative path to the component directory (e.g. skills/lint-component) |

**Tags:** `validation`, `quality`, `maintenance`

**Added in:** v0.1.0

**Definition file:** `skills/lint-component/skill.md`

---

## sync-context

**Description:** Regenerates the toolkit registry and context snapshots from current component files.

**Invocation:** `/tw-sync-context`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `force` | boolean | false | "false" | Force regeneration even if no component files appear to have changed |

**Tags:** `context`, `maintenance`, `registry`

**Added in:** v0.1.0

**Definition file:** `skills/sync-context/skill.md`

---

