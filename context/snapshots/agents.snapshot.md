# Agents Snapshot (L3)

> Auto-generated on 2026-10-14 16:47 UTC. Do not edit manually.
> For a quick overview of all types, load `context/snapshot.md` (L2).

---

## client-bootstrap

**Description:** Autonomous agent that executes the full Day 1 consultant workflow — stack health check, QA strategy generation, initial test governance, security baseline, and CI pipeline setup. Produces a complete engagement starter kit that establishes quality foundations from the first day.

**Invocation:** `tw-client-bootstrap`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_name` | string | False |  | Project or client name for the generated documents. Defaults to git repo name. |
| `depth` | string | False | standard | 'quick' for a 2-hour engagement starter (health check + strategy only), 'standard' for full bootstrap (default), 'deep' for standard + compliance + security scan. |
| `regulatory` | string | False |  | Known regulatory requirements: 'gdpr', 'hipaa', 'pci-dss', 'sox'. Auto-detected if omitted. |
| `team_size` | string | False |  | Team size: 'small' (1-5), 'medium' (6-15), 'large' (16+). Affects strategy recommendations. |

**Tags:** `consulting`, `onboarding`, `bootstrap`, `day-one`, `engagement`, `autonomous`, `qa`

**Added in:** v0.5.0

**Definition file:** `agents/client-bootstrap/agent.md`

---

## onboard-repo

**Description:** Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project.

**Invocation:** `/tw-onboard-repo`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Tags:** `onboarding`, `setup`, `initialization`

**Added in:** v0.1.0

**Definition file:** `agents/onboard-repo/agent.md`

---

## quality-sprint

**Description:** Autonomous bounded loop that chains test governance and remediation until coverage targets are met or a human checkpoint is reached. Max 3 iterations with mandatory review at iteration 2.

**Invocation:** `/tw-quality-sprint`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Tags:** `testing`, `coverage`, `autonomous`, `governance`, `remediation`, `qa`

**Added in:** v0.2.0

**Definition file:** `agents/quality-sprint/agent.md`

---

## release-readiness

**Description:** Autonomous agent that orchestrates all quality gates — unit coverage, mutation score, flakiness, performance, accessibility, security, visual regression, and contract tests — and produces a single GO / NO-GO decision with a full evidence matrix. The consolidated release quality checkpoint.

**Invocation:** `tw-release-readiness`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `stack` | string | False |  | Tech stack: 'typescript', 'python', 'java', 'multi'. Auto-detected. |
| `gates` | string | False | all | Comma-separated quality gates to check: coverage, mutation, flakiness, performance, a11y, security, visual, contracts. Default: all. |
| `coverage_threshold` | number | False | 70 | Minimum line coverage % for Tier-A modules. Default: 70%. |
| `mutation_threshold` | number | False | 70 | Minimum mutation score % for Tier-A modules. Default: 70%. |
| `environment` | string | False | staging | Environment to validate against: 'local', 'staging', 'production'. Affects which gates are run. |

**Tags:** `release`, `quality-gate`, `autonomous`, `go-no-go`, `governance`, `qa`

**Added in:** v0.5.0

**Definition file:** `agents/release-readiness/agent.md`

---

## scaffold-component

**Description:** Creates a new toolkit component from the appropriate template given a type and name.

**Invocation:** `/tw-scaffold-component`

**Compatibility:** Claude Code: `full` | Cursor: `partial` | Codex: `none`

**Tags:** `scaffolding`, `development`, `maintenance`

**Added in:** v0.1.0

**Definition file:** `agents/scaffold-component/agent.md`

---

