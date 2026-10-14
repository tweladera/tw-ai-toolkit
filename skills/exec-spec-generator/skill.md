---
name: exec-spec-generator
description: Transforms user stories, acceptance criteria, or existing code into executable Gherkin specs with a QA-first blind spots report surfacing scenarios that developers and BAs typically miss.
status: stable
version_added: v0.2.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: story
    type: string
    required: true
    default: ""
    description: User story text, acceptance criteria, or feature description. Paste inline or provide a file path.
  - name: artifact
    type: string
    required: false
    default: ""
    description: Path to existing code, OpenAPI/AsyncAPI spec, or JSON schema that contextualizes the story. Optional but improves scenario quality significantly.
  - name: stack
    type: string
    required: false
    default: ""
    description: Target test framework for generated step stubs (jest/pytest/junit5). If omitted, auto-detected from the repo.
  - name: output_dir
    type: string
    required: false
    default: "specs/"
    description: Directory where the .feature file and blind spots report are saved.
tags:
  - bdd
  - gherkin
  - spec-first
  - qa
  - testing
  - requirements
invocation: tw-exec-spec-generator
---

# exec-spec-generator

## Description

Generates executable Gherkin specs from user stories or requirements before any implementation
exists. Applies 6 QA lenses to surface test scenarios that developers and business analysts
consistently overlook. The primary output is not just the feature file — it is the
**Blind Spots Report**, a structured list of scenarios absent from the original requirements
that carry real production risk.

This skill embodies the SDET perspective: code is a derived asset; the spec is the product.

**Use this skill before implementation begins.** When invoked on existing code, it performs
reverse-spec analysis and identifies what behaviors are unspecified or untested.

## When to Use

- A new feature is about to be implemented and no test scenarios exist yet
- A BA or PM has written acceptance criteria and needs QA review before dev starts
- You want to define the test corset before asking AI to generate implementation code
- You are reviewing a PR and want to know what scenarios the code doesn't cover
- You are doing reverse-spec analysis on legacy code with no tests

Triggers: user pastes a story or AC, says "write tests for this feature", "what are the
test cases for X", "review these requirements", or provides a Jira description.

## Instructions

Follow these steps **in order**. Do not skip or reorder.

### Step 1 — Parse Inputs

If `story` is a file path, read the file. Otherwise treat it as inline text.

If `artifact` is provided, read it:
- `.feature` → existing Gherkin (extend, do not duplicate)
- `*.yaml` / `*.json` → OpenAPI or AsyncAPI schema (extract endpoints, request/response shapes)
- Source code file → extract public interface, method signatures, return types, exceptions raised
- `*.md` → treat as supplementary requirements

Extract from `story`:
1. **Actor** — who performs the action
2. **Goal** — what they want to achieve
3. **Acceptance criteria** — the explicit conditions of satisfaction
4. **Implicit constraints** — infer from domain context (e.g., "amount" implies non-negative)
5. **System boundaries** — what external systems or services are involved

### Step 2 — Apply 6 QA Lenses

For each lens, generate test scenarios that are NOT already captured in the original AC.
Mark each scenario with its lens tag.

#### Lens 1: Functional / Happy Path (`@happy`)
The standard success scenarios. Cover each explicit AC exactly once.
State if AC is ambiguous or contradictory — do not invent behavior.

#### Lens 2: Boundary & Equivalence (`@boundary`)
- Exact boundary values: min, min-1, max, max+1
- Empty collections, zero, null, whitespace-only strings
- Maximum field lengths
- Type coercion edge cases (string "0" vs integer 0, "true" vs boolean true)

#### Lens 3: Error & Failure Modes (`@error`)
- Invalid input that should return a clear error (not a 500)
- Missing required fields
- Malformed data formats (invalid date, bad UUID, non-numeric where numeric expected)
- Partial failure: what if the third step of five fails?
- Retry semantics: is the operation idempotent?

#### Lens 4: Security & Authorization (`@security`)
- Authenticated user accessing another user's resource (IDOR)
- Unauthenticated request to a protected endpoint
- Privilege escalation (regular user performing admin action)
- Injection payloads in string fields (SQL, XSS, path traversal)
- Sensitive data exposure in responses or logs

#### Lens 5: State & Concurrency (`@state`)
- Duplicate request / double submission
- Operation on a resource in an invalid state (e.g., cancel an already-cancelled order)
- Race condition: two users modifying the same resource simultaneously
- Stale data: operation based on data that changed since the user loaded it

#### Lens 6: Integration & Contract (`@contract`)
- What happens when a downstream service is slow (timeout)?
- What happens when a downstream service returns an unexpected response shape?
- Message ordering: does the consumer handle out-of-order events?
- Schema compatibility: does the event/payload break existing consumers?

### Step 3 — Generate Gherkin Feature File

Rules for the feature file:
- Feature name reflects the **business capability**, not the class or endpoint name
- Each scenario has exactly one `@tag` from the lenses above (add `@smoke` to the 3 most critical)
- `Given` = precondition and system state
- `When` = single action by the actor
- `Then` = observable outcome (HTTP status, DB state, event emitted, UI message)
- No technical implementation details in scenario steps (no class names, SQL, internal IDs)
- Minimum: 1 `@happy`, 1 `@boundary`, 1 `@error`, 1 `@security`, 1 `@state`, 1 `@contract`
- Use `Scenario Outline` + `Examples` table for scenarios that differ only in data values
- Language: English

```gherkin
Feature: [Business Capability Name]
  As a [Actor]
  I want to [Goal]
  So that [Business Value]

  Background:
    Given [common precondition shared by all scenarios]

  @happy @smoke
  Scenario: [Positive scenario title]
    Given [state]
    When [action]
    Then [outcome]

  @boundary
  Scenario Outline: [Boundary scenario title]
    Given [state]
    When [action with <param>]
    Then [outcome with <expected>]
    Examples:
      | param | expected |
      | ...   | ...      |
```

### Step 4 — Generate Blind Spots Report

This is the primary QA value-add. Document every scenario generated that was NOT present
in the original acceptance criteria.

Format:
```markdown
## Blind Spots Report — [Feature Name]
**Story analyzed:** [first line of story]
**Scenarios in original AC:** N
**Additional scenarios generated:** M
**Production risk level:** HIGH / MEDIUM / LOW

### Missing from Original AC

| Lens | Scenario | Risk | Why it matters |
|------|----------|------|----------------|
| @security | Unauthenticated user accessing order details | HIGH | Returns 403, not 200 with data |
| @state | Creating duplicate order within 1 second | HIGH | Creates orphan records in DB |
| @boundary | Amount field with value 0.001 below minimum | MEDIUM | Business rule not stated explicitly |
| @contract | Payment service timeout after 30s | HIGH | Unhandled — caller blocks indefinitely |

### Ambiguities in Original AC

List any AC statements that are vague, contradictory, or incomplete.
Each must be a concrete question that needs an answer before implementation:

- "The system should notify the user" — via email, push, in-app, or all three?
- "Invalid amounts are rejected" — is 0 invalid? Is negative invalid?
```

### Step 5 — Save Outputs

```bash
mkdir -p {{output_dir}}
```

**Feature file name:** `[feature-name]-[YYYY-MM-DD].feature`
**Blind spots file name:** `[feature-name]-blind-spots-[YYYY-MM-DD].md`

After saving, confirm:
```
Spec generation complete
Feature file: {{output_dir}}/[name]-[date].feature
Blind spots:  {{output_dir}}/[name]-blind-spots-[date].md
Scenarios generated: N total (happy: X, boundary: X, error: X, security: X, state: X, contract: X)
Blind spots found: M scenarios not in original AC
Ambiguities: K open questions requiring answer before implementation
```

### Step 6 — Recommend Next Steps

Always end with:
```
Recommended next steps:
1. Review blind spots report with the BA/PM — resolve ambiguities before dev starts
2. Use this .feature file as the test corset: implement code until all scenarios pass
3. Run /tw-ts-test-governor (or /tw-python-test-governor) after implementation to verify coverage
4. If this is a refactor: run /tw-golden-master mode=capture before changes, mode=compare after
```

## Examples

### Example 1 — From a user story (inline)

```
/tw-exec-spec-generator story="As a buyer I want to place an order so that I can purchase items.
AC:
- Items must be in stock
- Payment must be authorized before confirming order
- User receives confirmation email after order is placed"
```

### Example 2 — From a story file + OpenAPI schema

```
/tw-exec-spec-generator story=docs/stories/US-142.md artifact=openapi/orders.yaml stack=jest
```

### Example 3 — Reverse-spec on existing code

```
/tw-exec-spec-generator story="This is the orders service" artifact=src/orders/orders.service.ts
```

Claude reads the code, infers the business behavior, generates specs, and identifies
which behaviors have no coverage.

## Dependencies

- No external scripts required
- If `artifact` is an OpenAPI spec, it must be valid YAML or JSON
- For step stub generation, target framework must be installed in the project (`jest`, `pytest`, `junit5`)

## Notes

- This skill does NOT generate implementation code — only specs and test stubs
- Gherkin generated is meant to be implemented with a BDD framework (Cucumber, Behave, JUnit 5 Gherkin)
- When invoked on existing code, it performs reverse-spec and may surface untested behaviors — this is intentional
- The Blind Spots Report is the primary artifact, not a byproduct
