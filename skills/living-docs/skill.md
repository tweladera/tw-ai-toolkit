---
name: living-docs
description: Reads passing Gherkin feature files and test results to generate living documentation — human-readable reports showing what behavior is verified, what is pending, and what has failed. Publishes to Confluence, generates HTML, or produces structured Markdown.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: source
    type: string
    required: false
    default: ""
    description: "Path to .feature files or directory. Defaults to 'features/' or 'specs/'. Can also be a test results directory (JUnit XML, Playwright JSON, Cypress JSON)."
  - name: output
    type: string
    required: false
    default: "markdown"
    description: "'markdown' for .md files, 'html' for standalone HTML report, 'confluence' for Confluence wiki markup ready to publish."
  - name: output_dir
    type: string
    required: false
    default: "docs/living/"
    description: "Directory where documentation files are saved."
  - name: include_pending
    type: boolean
    required: false
    default: "true"
    description: "When true, includes pending/unimplemented scenarios marked as 'not yet automated'. Default: true."
tags:
  - documentation
  - living-docs
  - gherkin
  - bdd
  - confluence
  - reporting
  - qa
invocation: tw-living-docs
---

# living-docs

## Description

Tests are the most accurate documentation a system has — they cannot lie, because they run.
But only engineers read them. Business stakeholders, product owners, and clients cannot extract
value from a Jest spec file or a Playwright test.

`living-docs` bridges this gap: it reads your passing Gherkin feature files and test results,
and generates **human-readable documentation** that non-technical stakeholders can use to
understand what the system actually does — verified, at this moment, by automated tests.

**Living documentation answers these questions:**
- "What features are available in the application?"
- "Which user scenarios are automatically verified?"
- "What is the current pass/fail status of each feature?"
- "What scenarios exist in the spec but are not yet automated?"

**The documentation is always current** — it regenerates from the actual test results, not
from a wiki that someone wrote 6 months ago and forgot to update.

**For consultants:** This is the artifact that makes QA visible to management. Instead of
explaining what 73% coverage means, you show a page that says "Order Placement: 12 scenarios
verified ✅ | 2 scenarios pending". That's a conversation anyone can have.

## When to Use

- After a sprint review — generate a summary of what was tested and verified
- For client demos — show what the system guarantees, not what it does
- After each sprint — update the living docs as part of the Definition of Done
- When onboarding new team members — living docs explain the system's behavior faster than code
- For regulatory compliance — living docs as evidence of test coverage

Triggers: "generate documentation from tests", "living documentation", "test results report",
"what does our system do", "show verified behavior", "feature documentation".

## Instructions

### Step 1 — Collect Feature Files and Test Results

```bash
# Find all feature files
find . -name "*.feature" | grep -v node_modules | sort

# Find test results (JUnit XML — works for Jest, Playwright, Cypress, JUnit)
find . -name "*.xml" -path "*/test-results/*" -o -name "junit*.xml" | head -10

# Playwright JSON results
find . -name "*.json" -path "*/playwright-report/*" | head -5

# Cypress results
find . -name "*.json" -path "*/cypress/results/*" | head -5
```

### Step 2 — Parse Feature Files

For each `.feature` file, extract:
- Feature name and description
- Background steps (shared context)
- Scenarios (names and steps)
- Tags (`@smoke`, `@regression`, `@wip`, `@pending`)

```python
# Parse Gherkin features
import re
from pathlib import Path

def parse_feature(path):
    content = Path(path).read_text()
    feature = {}
    feature['name'] = re.search(r'Feature:\s*(.+)', content).group(1).strip()
    feature['description'] = []
    feature['scenarios'] = []

    for match in re.finditer(r'(?:Scenario|Scenario Outline):\s*(.+)', content):
        feature['scenarios'].append({
            'name': match.group(1).strip(),
            'status': 'unknown'  # to be enriched from test results
        })
    return feature
```

### Step 3 — Enrich with Test Results

Match feature scenarios to test results to determine pass/fail/pending status:

```python
# Parse JUnit XML results
from xml.etree import ElementTree as ET

def parse_junit(xml_path):
    results = {}
    tree = ET.parse(xml_path)
    for tc in tree.findall('.//testcase'):
        name = tc.get('name', '')
        failure = tc.find('failure')
        skipped = tc.find('skipped')
        if failure is not None:
            results[name] = 'FAIL'
        elif skipped is not None:
            results[name] = 'PENDING'
        else:
            results[name] = 'PASS'
    return results
```

**Status mapping:**
- `PASS` ✅ — scenario ran and passed
- `FAIL` ❌ — scenario ran and failed (regression or bug)
- `PENDING` ⏳ — scenario exists in feature file but no test implementation
- `SKIPPED` ⚪ — test exists but was skipped (e.g., environment not available)

### Step 4 — Generate Living Documentation

**Output: Markdown**

```markdown
# Living Documentation — {{project_name}}

> **Auto-generated from verified test results**
> Last updated: YYYY-MM-DD HH:MM
> Generated by: /tw-living-docs | v0.5.0
> Source: 12 feature files | 89 scenarios

---

## Summary

| Status | Count | % |
|---|---|---|
| ✅ Passing | 67 | 75% |
| ❌ Failing | 4 | 4% |
| ⏳ Pending | 18 | 20% |
| ⚪ Skipped | 0 | 0% |

**Verified features: 8 of 12**
**Fully automated: 4 features (all scenarios pass)**

---

## Feature: Order Placement

> A buyer can browse the catalog and place an order for one or more items.
> Orders are validated, priced, and sent to the warehouse for fulfillment.

**Status: ✅ Fully verified (7/7 scenarios pass)**

| Scenario | Status |
|---|---|
| Successfully place a single-item order | ✅ Pass |
| Successfully place a multi-item order | ✅ Pass |
| Apply a valid discount code | ✅ Pass |
| Reject order when item is out of stock | ✅ Pass |
| Reject order with invalid payment method | ✅ Pass |
| Reject order for suspended user account | ✅ Pass |
| Show order confirmation with summary | ✅ Pass |

---

## Feature: Payment Processing

> The system processes payments via multiple providers and handles
> success, failure, and retry scenarios.

**Status: ⚠️ Partially verified (5/8 scenarios pass, 3 pending)**

| Scenario | Status |
|---|---|
| Process successful credit card payment | ✅ Pass |
| Process successful PayPal payment | ✅ Pass |
| Handle card decline — insufficient funds | ✅ Pass |
| Handle card decline — expired card | ✅ Pass |
| Retry failed payment after 30 seconds | ✅ Pass |
| Handle payment provider timeout | ⏳ Pending |
| Process partial refund | ⏳ Pending |
| Handle double-charge prevention | ⏳ Pending |

*3 scenarios are defined in the specification but not yet automated.*

---

## Feature: User Authentication

**Status: ❌ Regression detected (3/5 scenarios pass, 2 failing)**

| Scenario | Status | Detail |
|---|---|---|
| Register with valid email and password | ✅ Pass | |
| Login with valid credentials | ✅ Pass | |
| Reset password via email | ✅ Pass | |
| Login with expired session token | ❌ Fail | Expected 401, got 200 — **regression** |
| Block account after 5 failed attempts | ❌ Fail | Rate limiter not enforced — **regression** |

**Action required:** 2 authentication scenarios are failing. This is a security regression.
Review recent changes to `auth.service.ts` and `session.middleware.ts`.

---

## Pending Scenarios (Not Yet Automated)

The following scenarios exist in the specification but have no automated test yet.
These represent gaps in the automated regression safety net.

| Feature | Scenario | Priority |
|---|---|---|
| Payment Processing | Handle payment provider timeout | HIGH |
| Payment Processing | Process partial refund | HIGH |
| Payment Processing | Handle double-charge prevention | CRITICAL |
| User Management | Export personal data (GDPR Art. 20) | HIGH |
| Notifications | Send SMS for order status change | MEDIUM |

---

## Test Coverage by Business Domain

```
Order Domain:      ████████████████████ 100% (7/7 scenarios)
Payment Domain:    █████████████░░░░░░░  62% (5/8 scenarios)
User Domain:       ████████████████░░░░  80% (4/5 — 2 failing)
Catalog Domain:    ██████████░░░░░░░░░░  50% (3/6 scenarios)
Admin Domain:      ░░░░░░░░░░░░░░░░░░░░   0% (0/8 scenarios)
```

---

## What Living Documentation Does NOT Cover

Automated tests verify **expected** behavior. The following require human review:
- Business logic edge cases not described in feature files
- Usability and UX quality
- Performance under production-scale load
- Security vulnerabilities (use `/tw-security-audit`)
- Accessibility beyond axe-core automated checks

---

*This document is generated automatically. To update it, run `/tw-living-docs`.*
*To add new verified behaviors, write Gherkin scenarios + automated tests.*
```

**Output: Confluence Wiki Markup**

For Confluence, generate the same content using Confluence storage format (XHTML-based)
or Confluence wiki markup, suitable for direct paste or API publish:

```
h1. Living Documentation — {{project_name}}

{info}Auto-generated from verified test results. Last updated: YYYY-MM-DD.{info}

h2. Summary

|| Status || Count || % ||
| (/) Passing | 67 | 75% |
| (x) Failing | 4 | 4% |
| (!) Pending | 18 | 20% |

h2. Feature: Order Placement

*Status:* (/) Fully verified — 7/7 scenarios pass

|| Scenario || Status ||
| Successfully place a single-item order | (/) Pass |
| Apply a valid discount code | (/) Pass |
[...]
```

### Step 5 — Save and Optionally Publish

Save to `docs/living/`:
```
docs/living/
├── index.md          ← Feature index with status summary
├── order-placement.md
├── payment-processing.md
├── user-authentication.md  ← ❌ Contains regression alert
└── _summary.csv       ← For dashboards/import
```

For Confluence publish:
```bash
# Using Confluence REST API (requires CONFLUENCE_TOKEN env var)
# See mcp/tw-confluence/server.md for MCP-based publishing
curl -X PUT \
  -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
  -H "Content-Type: application/json" \
  "https://yourcompany.atlassian.net/wiki/rest/api/content/{pageId}" \
  -d "{\"version\":{\"number\":2},\"title\":\"Living Docs\",\"body\":{\"storage\":{\"value\":\"...\",\"representation\":\"storage\"}}}"
```

## Examples

### Example 1 — Generate Markdown docs from feature files

```
/tw-living-docs source=features/
```

### Example 2 — HTML report from Playwright test results

```
/tw-living-docs source=playwright-report/ output=html output_dir=docs/qa/
```

### Example 3 — Confluence-ready markup for wiki publishing

```
/tw-living-docs output=confluence
```

### Example 4 — Include pending scenarios in the report

```
/tw-living-docs include_pending=true output=markdown
```

## Dependencies

- Gherkin `.feature` files in the project (from `/tw-exec-spec-generator` or manually authored)
- Test results in JUnit XML, Playwright JSON, or Cypress JSON format (for pass/fail enrichment)
- For Confluence publishing: `CONFLUENCE_TOKEN` and `CONFLUENCE_BASE_URL` environment variables
  (or use the `tw-confluence` MCP server)

## Notes

- Living documentation is a snapshot — regenerate after each test run for accuracy
- A "⏳ Pending" scenario is not a failure — it is transparency that the spec is ahead of the automation
- A "❌ Failing" scenario IS a signal — it means automated regression was detected
- Add `/tw-living-docs` as the last step in your CI pipeline to always have current documentation
- For maximum impact: publish to Confluence after every successful main branch build
- Pair with `/tw-quality-trend` for longitudinal view — how has scenario coverage changed over time?
