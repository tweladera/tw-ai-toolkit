# Rules Snapshot (L3)

> Auto-generated on 2026-10-14 20:42 UTC. Do not edit manually.
> For a quick overview of all types, load `context/snapshot.md` (L2).

---

## claude-base

**Description:** Base behavioral rules for Claude Code when working in a repo that uses tw-ai-toolkit.

**Compatibility:** Claude Code: `full` | Cursor: `—` | Codex: `—`

**Tags:** `claude-code`, `base`, `context-loading`

**Added in:** v0.1.0

**Definition file:** `rules/claude-base/rule.md`

---

## consultant-mindset

**Description:** Behavioral rule that instructs AI assistants to operate with a consulting mindset when joining a new project — assess before assuming, make findings visible, generate artifacts that communicate value, and adapt recommendations to the client's context and constraints.

**Compatibility:** Claude Code: `—` | Cursor: `—` | Codex: `—`

**Tags:** `consulting`, `onboarding`, `communication`, `assessment`, `mindset`, `rule`

**Added in:** v0.5.0

**Definition file:** `rules/consultant-mindset/rule.md`

---

## cursor-base

**Description:** Base behavioral rules for Cursor when working in a repo that uses tw-ai-toolkit.

**Compatibility:** Claude Code: `—` | Cursor: `full` | Codex: `—`

**Tags:** `cursor`, `base`, `context-loading`

**Added in:** v0.1.0

**Definition file:** `rules/cursor-base/rule.md`

---

## performance-budget

**Description:** Behavioral rule that instructs AI assistants to flag potential performance regressions at design time — before implementing queries, loops, API calls, or data transformations that could silently degrade P95 latency.

**Compatibility:** Claude Code: `—` | Cursor: `—` | Codex: `—`

**Tags:** `performance`, `n-plus-one`, `latency`, `database`, `optimization`, `mindset`, `rule`

**Added in:** v0.5.0

**Definition file:** `rules/performance-budget/rule.md`

---

## security-first

**Description:** Behavioral rule that instructs AI assistants to surface security implications proactively — before implementing features that handle sensitive data, before suggesting third-party integrations, and before any code that touches auth, payments, PII, or external APIs.

**Compatibility:** Claude Code: `—` | Cursor: `—` | Codex: `—`

**Tags:** `security`, `owasp`, `pii`, `auth`, `mindset`, `rule`

**Added in:** v0.5.0

**Definition file:** `rules/security-first/rule.md`

---

## spec-first

**Description:** Establishes a spec-first quality mindset for AI assistants — surface test scenarios before implementation, treat the spec as the product, and apply the QA perspective that individual developers typically miss.

**Compatibility:** Claude Code: `—` | Cursor: `—` | Codex: `—`

**Tags:** `spec-first`, `qa`, `bdd`, `quality-mindset`, `pre-implementation`

**Added in:** v0.2.0

**Definition file:** `rules/spec-first/rule.md`

---

