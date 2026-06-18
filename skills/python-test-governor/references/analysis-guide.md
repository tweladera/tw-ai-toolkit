# Analysis Guide

This guide ensures consistent severity classification, decision-making, and report quality across all test governance analyses.

---

## Severity Matrix

Use this matrix to classify findings consistently.

### CRITICAL

**Runtime blockers or zero coverage on critical paths**

- All tests failing due to dependency/runtime issue
- Import errors preventing test execution
- Core business logic modules have zero unit tests
- Service layer or data processing with no coverage
- Test suite hasn't run successfully in >1 week
- Production code deployed without any test verification

**Language**: "BLOCKS all testing", "Zero coverage", "Cannot verify"

### HIGH

**Missing or broken tests for core business logic**

- Business logic functions missing unit tests
- Data transformation/processing modules unmapped
- Broken tests blocking CI/CD pipeline
- Changed code adds branches/exceptions without test update
- Critical edge cases untested (null handling, retries, error paths)
- Integration tests exist but unit tests missing for testable logic

**Language**: "Core logic untested", "Regression risk", "Must fix before deployment"

### MEDIUM

**Incomplete coverage or missing tests for secondary logic**

- Utility functions without tests
- Helper modules missing some test coverage
- Configuration modules with conditional logic untested
- Low-priority adapter/wrapper functions without tests
- Parameterized test could replace 5+ similar tests
- Test exists but coverage <50% on module

**Language**: "Incomplete coverage", "Should add", "Recommended"

### LOW

**Nice-to-have tests for simple structures**

- Simple dataclasses with only attributes
- Configuration holders without logic
- Empty __init__.py files
- Simple exception classes with no custom behavior
- Type definitions (TypedDict, NamedTuple)
- Simple property getters/setters

**Language**: "Optional", "Low priority", "Not required"

---

## Decision Matrix

### create-test

**When to use**:
- New module added with business logic and no matching test
- Production module exists, no test file exists, and module has:
  - Functions with branching (`if`, conditional expressions)
  - Exception handling (`try/except`, `raise`)
  - Data transformations or processing logic
  - Multiple function/class interactions
  - Side effects (file I/O, API calls, DB operations)

**Evidence needed**:
- Inventory shows `unmapped` status
- Module matches priority patterns (services, processors, utilities, validators, transformers)

**Output**:
- Mark as `create-test` in Impacted Modules table
- Add to Suggested Tests with Type = `unit`
- Explain in "Why it matters" what behavior needs verification

### update-test

**When to use**:
- Test file exists but is failing
- Git diff shows changes to module and test needs update:
  - Function signature changed
  - New branch/exception added
  - Dependencies modified
  - Function arguments changed
- Test output shows specific errors:
  - `AttributeError` - new attribute needed
  - `TypeError` - signature mismatch
  - `AssertionError` concentrated in one test file

**Evidence needed**:
- Inventory shows `covered` with matching test file
- Test output shows failures, OR
- Git diff shows behavioral change in production module

**Output**:
- Mark as `update-test` in Impacted Modules table
- Cite specific error from test output in Findings
- Explain what changed and why test needs update

### no-change

**When to use**:
- Test exists and passing
- Coverage adequate for module complexity
- Git diff changes don't affect behavior (formatting, docstrings, comments)
- Test quality meets standards (see test-generation-standards.md)

**Evidence needed**:
- Test passing in pytest/unittest results
- Coverage shows reasonable coverage (>70% for logic-heavy modules)
- No behavioral changes in recent diff

**Output**:
- Mark as `no-change` in Impacted Modules table
- May highlight as good example in Recommendations if well-written

### no-test-needed

**When to use**:
- Simple dataclass with only attributes
- TypedDict or NamedTuple definition
- Simple exception wrapper with no custom logic
- Empty __init__.py file
- Configuration module with only constants
- Simple property wrapper with no logic

**Evidence needed**:
- File inspection shows no branching, no logic, no transformations
- Module is data structure or constant definition

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
- [Quantify: "39 tests failing", "12 modules", etc.]

**Diagnosis**: [Why this is happening - dependencies, versions, config]
- Check [specific file/config]
- [Hypothesis about root cause]
- [Alternative explanation if uncertain]

**Impact**: [What cannot be done because of this]
- Cannot verify [feature/fix]
- Risk of [production issue]
- Blocks [next steps]
```

**When to include**:
- 5+ tests failing with same error
- Import/dependency failures
- Dependency conflicts (ModuleNotFoundError, version mismatches)
- Framework compatibility issues

**When to skip**:
- Individual test failures with different causes
- No systemic patterns
- Straightforward coverage gaps

---

## Common Phrases for Consistency

### Findings Table - Finding Column

**Dependencies**:
- "Missing required package: pandas not in requirements.txt"
- "Version conflict: pytest 7.x incompatible with pytest-cov 3.x"
- "ModuleNotFoundError for [package]"

**Unit Tests (broken)**:
- "12 test functions failing - ModuleNotFoundError: [module]"
- "AttributeError - function signature changed"
- "TypeError in test fixture - argument mismatch"

**Coverage Gaps**:
- "Complex data processing logic with 6 functions - unmapped"
- "Error handling logic across 6 methods - no unit test"
- "Business logic implementing core use case - zero coverage"

### Impacted Modules - Notes Column

**create-test**:
- "Test data processing functions and edge cases"
- "Cover error handling across 6 methods"
- "Verify retry behavior and exception handling"
- "Test transformation with None/empty/full inputs"

**update-test**:
- "Tests exist and well-designed, need runtime fix"
- "Fixture obsolete after function signature change"
- "New branch added, assertions incomplete"

**no-change**:
- "Core service module appears functional"
- "Tests comprehensive, good pattern to follow"

**no-test-needed**:
- "Simple dataclass with attributes only"
- "Configuration constants module"
- "Empty __init__.py file"

### Recommendations

**Priority 1 (blockers)**:
- "Fix missing dependency in requirements.txt"
- "Resolve import errors in test suite"
- "Repair broken test fixtures after signature changes"

**Priority 2 (after blockers)**:
- "Create unit tests for [module.py]"
- "Review test quality for [test_module.py] - already passing"
- "Update [test_module.py] to cover new branch logic"

**Priority 3 (continuous)**:
- "Add pytest-cov coverage gating to CI"
- "Monitor test execution time - move slow tests to separate suite"
- "Refactor [test_module.py] to reduce duplication"

---

## Report Quality Checklist

Before finalizing report, verify:

- [ ] Executive Summary has all 3 fields filled
- [ ] Findings table has minimum 3 rows
- [ ] Every production module appears in Impacted Modules table
- [ ] Severity uses CRITICAL/HIGH/MEDIUM/LOW (not "important", "urgent")
- [ ] Decision uses create-test/update-test/no-change/no-test-needed
- [ ] All module names use backticks: `module_name.py`
- [ ] All file paths use backticks: `src/module_name.py`
- [ ] All commands in code blocks with language hint
- [ ] Line numbers included when referencing specific code: `module.py:42`
- [ ] Recommendations organized in 3 priority levels
- [ ] Report ends with "Would you like me to..." question with 3 options
- [ ] Numbers used instead of adjectives: "39 tests" not "many tests"
- [ ] Root Cause Analysis included if 5+ tests failing with same error
- [ ] Each finding maps to a decision, each decision maps to a recommendation

---

## Example Patterns

### Good Severity Assignment

✅ **CRITICAL** - "All 39 unit tests failing - ModuleNotFoundError for pandas"
❌ "Tests are failing" (too vague, no numbers, no severity justification)

✅ **HIGH** - "Core data processing module with transformation logic - zero unit tests"
❌ "Missing tests" (what's missing? why does it matter?)

✅ **MEDIUM** - "Utility function snake_to_camel() lacks edge case tests"
❌ "Should test this function" (unclear priority)

### Good Decision Assignment

✅ **create-test** - `data_processor.py` "Test processing functions with various input types"
❌ "Needs tests" (what kind? why?)

✅ **update-test** - `test_transformer.py` "Tests well-designed, blocked by missing dependency"
❌ "Fix tests" (fix how? what's wrong?)

✅ **no-test-needed** - `config.py` "Simple configuration constants"
❌ "Skip" (why skip? be explicit)

### Good Root Cause Sections

✅ Shows problem, evidence (with numbers), diagnosis (with specifics), impact (with consequences)
❌ "Tests are broken because of dependencies" (too vague)

✅ Includes exact error message snippets
❌ Paraphrases error without showing actual text

✅ Suggests specific diagnostic command with code block
❌ Says "check the dependencies" without showing how
