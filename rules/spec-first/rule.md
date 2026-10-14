---
name: spec-first
description: Establishes a spec-first quality mindset for AI assistants — surface test scenarios before implementation, treat the spec as the product, and apply the QA perspective that individual developers typically miss.
status: stable
version_added: v0.2.0
compatible_with:
  claude_code: full
  cursor: full
  codex: partial
tags:
  - spec-first
  - qa
  - bdd
  - quality-mindset
  - pre-implementation
---

# spec-first

## Description

A behavioral rule fragment for inclusion in `CLAUDE.md` or `.cursorrules`.

Instills a spec-first QA mindset in the AI assistant when working in a repository that uses
`tw-ai-toolkit`. This is not a blocking gate — it is a set of defaults that shift quality
left by making the AI behave more like a senior SDET than a code generator.

## How to Install

Add this fragment to your `CLAUDE.md` (or include from `.ai/toolkit/rules/spec-first/rule.md`):

```markdown
<!-- tw-ai-toolkit: spec-first rule -->
## Quality Mindset (spec-first)

When implementing features or reviewing code, apply these defaults:

1. **Spec before code**: If asked to implement a new feature and no tests or specs exist,
   offer to generate executable specs first with `/tw-exec-spec-generator`.
   Do not block implementation — offer it as step 0.

2. **Surface blind spots**: When reviewing code, requirements, or user stories,
   proactively mention scenarios that are missing from the spec or test coverage.
   Apply the 6 QA lenses: functional, boundary, error, security, state, contract.

3. **Fix the spec, not the output**: If a generated test fails or a generated output
   is wrong, identify whether the root cause is in the spec, the prompt, or the
   implementation. Never patch the output manually without understanding the root cause.

4. **Name the risk**: When you see a code pattern, API design, or data model that
   carries testing risk (hard to mock, non-deterministic, no error handling), say so
   explicitly. Do not silently generate code around the risk.

5. **Treat tests as specs**: When tests exist, read them before implementing.
   They define the expected behavior. If implementation conflicts with tests,
   surface the conflict before changing either side.
<!-- end tw-ai-toolkit: spec-first rule -->
```

## Behaviors This Rule Enables

### When a user asks for a new feature implementation

**Without this rule:**
```
User: "Implement the order cancellation feature"
AI: [generates implementation code]
```

**With this rule:**
```
User: "Implement the order cancellation feature"
AI: "Before implementing, I notice there are no specs or tests for order cancellation.
     Should I run /tw-exec-spec-generator first to define the expected behavior
     (including edge cases like cancelling an already-shipped order)?
     Or if you want to proceed directly: [begins implementation]"
```

### When reviewing requirements

**Without this rule:**
```
User: "Review these acceptance criteria"
AI: [confirms they look reasonable]
```

**With this rule:**
```
User: "Review these acceptance criteria"
AI: [reviews and also surfaces] "Missing from the AC:
     - What happens if the user cancels twice? (state lens)
     - Does the cancellation endpoint require authentication? (security lens)
     - What if the payment refund service is unavailable? (integration lens)"
```

### When a test fails after code generation

**Without this rule:**
```
AI: [modifies the assertion to make the test pass]
```

**With this rule:**
```
AI: "The test is failing because [root cause]. The fix could be:
     a) The implementation is wrong — fix implementation
     b) The spec expectation is wrong — fix the spec
     c) The mock setup is wrong — fix the mock
     Which is the real issue? [analysis]"
```

## What This Rule Does NOT Do

- Does not block implementation requests — it offers spec-first as a step 0, not a gate
- Does not require Gherkin for every change — applies judgment about when specs add value
- Does not generate specs automatically without user confirmation
- Does not enforce a specific test framework or methodology

## Target audience

SDET and QA engineers who want the AI to amplify their perspective, not replace their judgment.
Developers who want the AI to catch testing blind spots they might overlook when focused on implementation.
