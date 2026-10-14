---
name: client-bootstrap
description: Autonomous agent that executes the full Day 1 consultant workflow — stack health check, QA strategy generation, initial test governance, security baseline, and CI pipeline setup. Produces a complete engagement starter kit that establishes quality foundations from the first day.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: project_name
    type: string
    required: false
    default: ""
    description: "Project or client name for the generated documents. Defaults to git repo name."
  - name: depth
    type: string
    required: false
    default: "standard"
    description: "'quick' for a 2-hour engagement starter (health check + strategy only), 'standard' for full bootstrap (default), 'deep' for standard + compliance + security scan."
  - name: regulatory
    type: string
    required: false
    default: ""
    description: "Known regulatory requirements: 'gdpr', 'hipaa', 'pci-dss', 'sox'. Auto-detected if omitted."
  - name: team_size
    type: string
    required: false
    default: ""
    description: "Team size: 'small' (1-5), 'medium' (6-15), 'large' (16+). Affects strategy recommendations."
tags:
  - consulting
  - onboarding
  - bootstrap
  - day-one
  - engagement
  - autonomous
  - qa
invocation: tw-client-bootstrap
---

# client-bootstrap

## Description

Every consultant engagement starts with the same challenge: **understand the current state,
establish credibility, and deliver value quickly** — all before the client starts wondering
why they hired you.

`client-bootstrap` is the Day 1 workflow compressed into a single agent invocation.
It runs the full assessment stack, generates the initial deliverables, and produces an
**Engagement Starter Kit** — a set of documents that:

1. Show the client what their codebase actually looks like (health check)
2. Define a clear path to quality improvement (strategy)
3. Measure what tests exist today and what's missing (governance report)
4. Identify security risks that need immediate attention (security baseline)
5. Add quality gates to their CI pipeline (pipeline update)

**What gets produced (standard depth):**

| Deliverable | Skill used | Audience |
|---|---|---|
| `HEALTH_CHECK_EXECUTIVE.md` | stack-health-check | Client management |
| `HEALTH_CHECK_TECHNICAL.md` | stack-health-check | Engineering team |
| `QA_STRATEGY_{{project}}.md` | test-strategy-generator | All |
| `TEST_GOVERNANCE_REPORT_*.md` | ts/python/java-test-governor | QA + Engineering |
| `SECURITY_AUDIT_*.md` | security-audit | Tech lead + management |
| Updated CI pipeline | pipeline-generator | Engineering |

**For the consultant:** Run this on Day 1 or Day 2 before the first team meeting.
The documents become the agenda for that meeting — you walk in with evidence, not questions.

## When to Use

- Day 1 or Day 2 of any new client engagement
- When taking over QA responsibility for an existing project
- When proposing a quality improvement initiative — generate the evidence base first
- Quarterly: re-run to measure how much has improved

Triggers: "bootstrap the project", "day one setup", "start quality assessment",
"onboard new client", "generate engagement kit", "first week deliverables".

## Agent Instructions

The agent executes in 5 sequential phases. Each phase builds on the previous.

---

### Phase 0 — Context Collection

Before running any tools, collect:

1. **Git remote URL** → infer project name if not provided
   ```bash
   git remote get-url origin 2>/dev/null | sed 's/.*\/\|\.git//g'
   ```

2. **Team information** (ask if not provided via parameter):
   - Team size (small/medium/large)
   - Known regulatory requirements
   - Primary delivery model (agile/kanban/other)

3. **CI platform** → detect automatically:
   ```bash
   ls .github/workflows/ .gitlab-ci.yml azure-pipelines.yml \
      Jenkinsfile .circleci/config.yml 2>/dev/null | head -3
   ```

Announce: "Starting client bootstrap for **{{project_name}}**. This will take approximately
10-15 minutes. I will announce each phase as it starts."

---

### Phase 1 — Stack Health Check

**Invoke:** `/tw-stack-health-check depth={{depth}} output=both`

This produces:
- Executive summary (management-ready, ≤ 2 pages)
- Technical report (full detail for engineering team)
- Populates the health score that informs the strategy

**What to announce to user:**
```
Phase 1/5 — Stack Health Check
Analyzing: stack, coverage, CI, dependencies, technical debt
This takes ~2 minutes...
```

After completion, save:
- `HEALTH_CHECK_EXECUTIVE_{{date}}.md`
- `HEALTH_CHECK_TECHNICAL_{{date}}.md`

---

### Phase 2 — QA Strategy Generation

**Invoke:** `/tw-test-strategy-generator project_name={{project_name}} team_size={{team_size}} regulatory={{regulatory}}`

Uses findings from Phase 1 to tailor:
- Test pyramid ratios for detected stack
- Tool recommendations for detected frameworks
- Coverage targets based on detected risk profile
- Phased roadmap adjusted to team capacity

**What to announce:**
```
Phase 2/5 — QA Strategy Document
Generating tailored strategy based on health check findings...
```

Save: `QA_STRATEGY_{{project_name}}_{{date}}.md`

---

### Phase 3 — Test Governance Baseline

Based on auto-detected stack, run the appropriate governor(s):

**TypeScript/NestJS:**
```
/tw-ts-test-governor
```

**Python:**
```
/tw-python-test-governor
```

**Java/Spring Boot:**
```
/tw-java-test-governor
```

**Multi-stack:** run all applicable governors sequentially.

**What to announce:**
```
Phase 3/5 — Test Governance Baseline
Running coverage audit for {{stack}} project...
This establishes the current test coverage baseline.
```

The governance report becomes the "Before" measurement. The team will use
`/tw-quality-sprint` to improve from this baseline.

---

### Phase 4 — Security Baseline

**Invoke:** `/tw-security-audit mode=scan`

Performs SAST code pattern scan + dependency vulnerability scan.
Does not require a running application.

**What to announce:**
```
Phase 4/5 — Security Baseline
Scanning for OWASP Top 10 patterns and known CVEs in dependencies...
Note: This is an automated baseline scan, not a penetration test.
```

If any CRITICAL or HIGH findings are detected:
- Flag them prominently in the engagement kit
- Add them to Phase 5 (CI pipeline) as a blocking quality gate

---

### Phase 5 — CI Pipeline Quality Gates

**Invoke:** `/tw-pipeline-generator stages=lint,unit,coverage,security`

Adds quality gates to the existing CI pipeline (or creates one if none exists).

Key gates added:
- Unit test execution (was it already there?)
- Coverage threshold enforcement (usually missing on day 1)
- Dependency vulnerability scan (almost always missing)
- Build artifact generation

**What to announce:**
```
Phase 5/5 — CI Pipeline Quality Gates
Adding coverage and security gates to {{ci_platform}} pipeline...
```

---

### Phase 6 — Generate Engagement Starter Kit

Compile all outputs into a structured package:

```markdown
# Engagement Starter Kit — {{project_name}}

**Date:** YYYY-MM-DD
**Consultant:** [Name]
**Generated by:** /tw-client-bootstrap | v0.5.0

---

## Documents Generated

| Document | Purpose | Audience |
|---|---|---|
| `HEALTH_CHECK_EXECUTIVE.md` | Current state — management summary | Client management |
| `HEALTH_CHECK_TECHNICAL.md` | Full technical assessment | Engineering team |
| `QA_STRATEGY_{{project}}.md` | QA roadmap and tooling recommendations | All |
| `TEST_GOVERNANCE_REPORT_*.md` | Current coverage baseline | QA + Engineering |
| `SECURITY_AUDIT_*.md` | Security findings and CVEs | Tech lead |
| `.github/workflows/ci.yml` (updated) | Quality gate CI pipeline | Engineering |

---

## Executive Summary — Key Findings

### 🔴 Immediate Action Required

1. **Low test coverage (22%)** — business logic changes carry high regression risk
2. **3 high-severity CVEs** — security vulnerabilities in production dependencies
3. **No CI quality gates** — pipeline passes regardless of test coverage or security

### 🟡 Short-Term Priorities (Sprint 1-2)

4. **No E2E tests** — critical user journeys not automated
5. **No contract tests** — inter-service integrations unverified
6. **No performance baseline** — regressions cannot be detected

### 🟢 Strengths (Build on These)

7. **OpenAPI spec exists** — foundation for integration test autodiscovery
8. **GitHub Actions pipeline exists** — add quality gates without rebuilding
9. **TypeScript throughout** — strong ecosystem for Jest, Playwright, Stryker

---

## Recommended First Sprint (2 weeks)

| Priority | Task | Toolkit Command | Effort |
|---|---|---|---|
| P0 | Fix CVSS ≥ 7.0 CVEs | (manual npm install) | 1h |
| P0 | Add coverage gate to CI | Already done in Phase 5 | done |
| P1 | Run quality sprint for Tier-A | `/tw-quality-sprint` | 2-3 days |
| P1 | Generate integration tests from OpenAPI | `/tw-integration-discovery source=openapi/` | 2h |
| P2 | Establish performance baseline | `/tw-performance-baseline mode=baseline` | 1h |
| P2 | Capture visual baseline | `/tw-visual-baseline mode=capture` | 1h |

---

## Toolkit Quick Reference

This project now has tw-ai-toolkit installed. Available commands:

\`\`\`
Quality loop:        /tw-quality-sprint
Integration tests:   /tw-integration-discovery source=openapi/api.yaml
Security scan:       /tw-security-audit
Release check:       /tw-release-readiness
Quality dashboard:   /tw-quality-trend since=30d
Living docs:         /tw-living-docs
\`\`\`

---

## Next Steps

1. **Today:** Share `HEALTH_CHECK_EXECUTIVE.md` with client management
2. **This week:** Review `QA_STRATEGY_{{project}}.md` with the engineering team
3. **Sprint 1:** Execute the recommended first sprint tasks
4. **End of Sprint 1:** Re-run `/tw-ts-test-governor` to measure progress
5. **Monthly:** Run `/tw-quality-trend since=30d` to show improvement to management
```

---

**deep depth** adds after Phase 5:

- **Phase 6:** `/tw-compliance-audit framework={{regulatory}}` — compliance gap report
- **Phase 7:** `/tw-test-strategy-generator` updated with compliance requirements
- **Additional deliverable:** `COMPLIANCE_AUDIT_{{date}}.md`

---

## Examples

### Example 1 — Standard Day 1 bootstrap

```
/tw-client-bootstrap project_name="OrderFlow Platform"
```

### Example 2 — Quick bootstrap (health check + strategy only)

```
/tw-client-bootstrap depth=quick project_name="RetailApp"
```

### Example 3 — Healthcare client with HIPAA requirement

```
/tw-client-bootstrap regulatory=hipaa depth=deep project_name="PatientPortal"
```

### Example 4 — Small team fintech

```
/tw-client-bootstrap team_size=small regulatory=gdpr,pci-dss project_name="PayService"
```

## Dependencies

- Source code accessible in working directory
- Git repository (for project name auto-detection)
- CI platform detected from config files (GitHub Actions, GitLab CI, Azure DevOps, etc.)
- For `depth=deep`: compliance framework knowledge (no additional tools needed)

## Notes

- The bootstrap takes 10-20 minutes — start it before a team meeting so results are ready when needed
- Generated documents are a **starting point** — review and personalize before sharing with clients
- The governance report will show low coverage on day 1 — that's the point: it establishes the baseline
- Always treat security findings with appropriate confidentiality — don't share SECURITY_AUDIT.md publicly
- Re-run this agent quarterly to show progress: the delta between bootstrap and current state IS the value
- Pair with `/tw-test-strategy-generator output_format=confluence` for immediate Confluence publishing
