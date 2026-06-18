# Analysis Guide

This guide ensures consistent severity classification, decision-making, and report quality across all test governance analyses.

---

## Severity Matrix

Use this matrix to classify findings consistently.

### CRITICAL

**Runtime blockers or zero coverage on critical paths**

- All specs failing due to dependency/runtime issue
- Import errors or NestJS DI errors preventing test execution
- Core service or use case modules have zero unit tests
- Business logic with no coverage whatsoever
- Test suite hasn't run successfully in >1 week
- Production code deployed without any test verification

**Language**: "BLOCKS all testing", "Zero coverage", "Cannot verify"

### HIGH

**Missing or broken tests for core business logic**

- Service or use case functions missing unit tests
- Data transformation/mapping modules unmapped
- Broken specs blocking CI/CD pipeline
- Changed code adds branches/exceptions without spec update
- Critical edge cases untested (null handling, retries, error paths)
- Integration tests exist but unit tests missing for testable logic

**Language**: "Core logic untested", "Regression risk", "Must fix before deployment"

### MEDIUM

**Incomplete coverage or missing tests for secondary logic**

- Utility functions without tests
- Helper modules missing some test coverage
- Pipes or guards with conditional logic untested
- Low-priority adapter/wrapper functions without tests
- `it.each` could replace 5+ similar tests
- Spec exists but coverage <50% on module

**Language**: "Incomplete coverage", "Should add", "Recommended"

### LOW

**Nice-to-have tests for simple structures**

- Simple DTOs with only class-validator decorators
- Configuration holders without logic
- Barrel `index.ts` re-export files
- Simple exception classes with no custom behavior
- TypeORM entity files with only column decorators
- NestJS module files (`*.module.ts`)

**Language**: "Optional", "Low priority", "Not required"

---

## Decision Matrix

### create-test

**When to use**:
- New module added with business logic and no matching `*.spec.ts`
- Production module exists, no spec file exists, and module has:
  - Methods with branching (`if`, conditional expressions, ternary)
  - Exception handling (`try/catch`, `throw`)
  - Data transformations or processing logic
  - Multiple class interactions or injected dependencies
  - Side effects (HTTP calls, DB operations, event emissions)

**Evidence needed**:
- Inventory shows `unmapped` status
- Module matches priority patterns (`*.service.ts`, `*.use-case.ts`, `*.mapper.ts`, `*.repository.ts`, etc.)

**Output**:
- Mark as `create-test` in Impacted Modules table
- Add to Suggested Tests with Type = `unit`
- Explain in "Why it matters" what behavior needs verification

### update-test

**When to use**:
- Spec file exists but is failing
- Git diff shows changes to module and spec needs update:
  - Constructor dependency added or removed
  - Method signature changed
  - New branch/exception added
  - Return type or shape changed
- Jest output shows specific errors:
  - `TypeError: Cannot read properties of undefined` — mock missing
  - `expect(received).toBe(expected)` — behavioral drift
  - `Nest can't resolve dependencies` — DI provider missing in TestingModule

**Evidence needed**:
- Inventory shows `covered` with matching spec file
- Test output shows failures, OR
- Git diff shows behavioral change in production module

**Output**:
- Mark as `update-test` in Impacted Modules table
- Cite specific error from test output in Findings
- Explain what changed and why spec needs update

### no-change

**When to use**:
- Spec exists and passing
- Coverage adequate for module complexity
- Git diff changes don't affect behavior (formatting, comments, type annotations)
- Test quality meets standards (see test-generation-standards.md)

**Evidence needed**:
- Spec passing in jest output
- Coverage shows reasonable coverage (>70% for logic-heavy modules)
- No behavioral changes in recent diff

**Output**:
- Mark as `no-change` in Impacted Modules table
- May highlight as good example in Recommendations if well-written

### no-test-needed

**When to use**:
- NestJS module file (`*.module.ts`)
- DTO with only class-validator decorators and no logic
- TypeORM entity with only column decorators
- Enum or type definition file
- Barrel re-export file (`index.ts`)
- `main.ts` entry point
- Configuration module with only constants
- Simple exception wrapper with no custom logic

**Evidence needed**:
- File inspection shows no branching, no logic, no transformations
- Module is data structure, type, or wiring definition

**Output**:
- Mark as `no-test-needed` in Impacted Modules table
- Keep brief notes, don't prioritize in Recommendations

---

## Root Cause Analysis Format

Use this structure when systemic issues exist:

```markdown
## Root Cause Analysis

**Problem**: [One sentence describing what's broken]

**Evidence**:
- [Error message or pattern 1]
- [Error message or pattern 2]
- [Quantify: "8 spec files failing", "12 modules", etc.]

**Diagnosis**: [Why this is happening - mocks, DI, versions, config]
- Check [specific file/config]
- [Hypothesis about root cause]
- [Alternative explanation if uncertain]

**Impact**: [What cannot be done because of this]
- Cannot verify [feature/fix]
- Risk of [production issue]
- Blocks [next steps]
```

**When to include**:
- 5+ specs failing with same error
- NestJS DI resolution failures across multiple specs
- `jest.config` or TypeScript config issues
- Framework compatibility issues

**When to skip**:
- Individual spec failures with different causes
- No systemic patterns
- Straightforward coverage gaps

---

## Common Phrases for Consistency

### Findings Table - Finding Column

**Dependencies**:
- "Missing jest mock provider for TypeORM Repository"
- "jest.config rootDir mismatch — specs outside `src/` not collected"
- "Circular dependency detected in NestJS module graph"

**Unit Tests (broken)**:
- "8 spec files failing — Nest can't resolve dependencies of InventoryService"
- "TypeError: Cannot read properties of undefined (reading 'findOne') — mock missing"
- "expect(received).toBe(expected) — method signature changed"

**Coverage Gaps**:
- "Core service with 6 public methods — no spec file"
- "Error handling logic across 4 branches — unmapped"
- "Business use case implementing core flow — zero coverage"

### Impacted Modules - Notes Column

**create-test**:
- "Test service methods and edge cases"
- "Cover error handling across 4 branches"
- "Verify retry behavior and exception propagation"
- "Test transformation with null/undefined/empty inputs"

**update-test**:
- "Spec well-designed, needs mock update after DI change"
- "Mock obsolete after constructor signature change"
- "New branch added, assertions incomplete"

**no-change**:
- "Core service module — spec comprehensive"
- "Good pattern to follow for new specs"

**no-test-needed**:
- "NestJS module wiring file only"
- "DTO with class-validator decorators only"
- "Barrel re-export file"

---

## Report Quality Checklist

Before finalizing report, verify:

- [ ] Executive Summary has all 3 fields filled
- [ ] Findings table has minimum 3 rows
- [ ] Every production module appears in Impacted Modules table
- [ ] Severity uses CRITICAL/HIGH/MEDIUM/LOW (not "important", "urgent")
- [ ] Decision uses create-test/update-test/no-change/no-test-needed
- [ ] All module names use backticks: `module.service.ts`
- [ ] All file paths use backticks: `src/infra/repo/module.repository.ts`
- [ ] All commands in code blocks with language hint
- [ ] Line numbers included when referencing specific code: `module.service.ts:42`
- [ ] Recommendations organized in 3 priority levels
- [ ] Report ends with "Would you like me to..." question with 3 options
- [ ] Numbers used instead of adjectives: "8 specs" not "many specs"
- [ ] Root Cause Analysis included if 5+ specs failing with same error
- [ ] Each finding maps to a decision, each decision maps to a recommendation

---

## Example Patterns

### Good Severity Assignment

CRITICAL - "All 8 unit specs failing — Nest can't resolve dependencies of InventoryService"
BAD: "Tests are failing" (too vague, no numbers, no severity justification)

HIGH - "Core InventoryService with 6 public methods — zero unit tests"
BAD: "Missing tests" (what's missing? why does it matter?)

MEDIUM - "ParseDatePipe lacks edge case tests for invalid timezone strings"
BAD: "Should test this pipe" (unclear priority)

### Good Decision Assignment

**create-test** - `inventory.service.ts` "Test service methods with various input types and error paths"
BAD: "Needs tests" (what kind? why?)

**update-test** - `inventory.service.spec.ts` "Spec well-designed, blocked by missing TypeORM repository mock"
BAD: "Fix tests" (fix how? what's wrong?)

**no-test-needed** - `infrastructure.module.ts` "NestJS module wiring — no logic to test"
BAD: "Skip" (why skip? be explicit)
