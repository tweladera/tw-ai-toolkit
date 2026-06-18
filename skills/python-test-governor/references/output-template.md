# Output Template

Use this template for ALL test governance reports. Every section is REQUIRED unless explicitly marked optional.

---

## Executive Summary

**REQUIRED** - Start every report with this section

- **Repository analyzed**: Full path or name of the repo/directory
- **Overall decision**: One of:
  - `HALT` - Critical blockers prevent any test work
  - `FIX TESTS FIRST` - Existing tests broken, must fix before new tests
  - `CREATE TESTS` - No blockers, proceed with new test creation
  - `UPDATE TESTS` - Focus on updating existing tests
  - `NO ACTION NEEDED` - Coverage adequate
- **Primary risk**: One sentence describing the biggest threat (e.g., "Zero test coverage on core business logic", "Data processing modules lack unit tests", "Integration tests exist but unit coverage missing")

---

## Findings

**REQUIRED** - Tabular summary of all issues found

| Area | File or module | Finding | Severity | Action |
| --- | --- | --- | --- | --- |
| Dependencies | `requirements.txt` | Description of dependency issue | CRITICAL / HIGH / MEDIUM / LOW | Specific action needed |
| Unit Tests | `test_module.py` | What's broken or missing | CRITICAL / HIGH / MEDIUM / LOW | Fix / Create / Update |
| Coverage Gaps | `module.py` | Why this gap matters | CRITICAL / HIGH / MEDIUM / LOW | Create test / No action |

**Severity guide**:
- **CRITICAL**: Blocks all testing, runtime failures, zero coverage on critical paths
- **HIGH**: Missing tests for core business logic, broken tests blocking CI
- **MEDIUM**: Missing tests for secondary logic, incomplete coverage
- **LOW**: Nice-to-have tests for simple models, config modules

**Minimum 3 findings** - If fewer, explain why in section

---

## Impacted Modules

**REQUIRED** - Map every production module to its test status

| Module | Test status | Coverage signal | Decision | Notes |
| --- | --- | --- | --- | --- |
| `module_name.py` | BROKEN / PASSING / UNMAPPED / N/A | Coverage %, test count, or "No test" | create-test / update-test / no-change / no-test-needed | Brief context |

**Test status values**:
- `BROKEN`: Test exists but failing
- `PASSING`: Test exists and passing
- `UNMAPPED`: No test exists
- `N/A`: Not applicable (simple dataclass, config, etc.)

**Decision values**:
- `create-test`: New test needed
- `update-test`: Existing test needs fixes
- `no-change`: Test adequate as-is
- `no-test-needed`: Module doesn't merit unit test

**Include all modules** from inventory script output

---

## Root Cause Analysis

**CONDITIONAL** - Required when tests are failing or there's a systemic issue

Provide detailed analysis when:
- Tests fail at runtime
- Multiple tests share same failure pattern
- Dependency conflicts exist
- Framework/version compatibility issues

Structure:
```
**Problem**: One-sentence summary
**Evidence**: Error messages, stack traces, or patterns
**Diagnosis**: Why this is happening (dependencies, config, etc.)
**Impact**: What can't be done because of this
```

Example:
```
**Problem**: pytest collection failure due to missing dependencies
**Evidence**:
  - ModuleNotFoundError: No module named 'pandas'
  - 15 tests failing with import errors
**Diagnosis**: requirements.txt may be out of date, or virtual environment not activated
**Impact**: Zero functional test coverage, cannot verify recent bug fixes
```

**Omit this section** if no systemic issues

---

## Suggested or Generated Tests

**REQUIRED** - What tests should be created/updated

| Target | Type | Why it matters | Status |
| --- | --- | --- | --- |
| `module.function` or `Class.method` | unit / integration / parameterized | Business reason for this test | BLOCKED / READY / GENERATED |

**Status values**:
- `BLOCKED`: Cannot proceed (runtime issue, missing dependencies)
- `READY`: Can be implemented now
- `GENERATED`: Test code provided in this report

**Prioritize** by business impact, not coverage percentage

If status is `GENERATED`, include test code in code block below table

---

## Risks and Limitations

**REQUIRED** - At least 3 risks

List concrete risks from current state:
- What could go wrong in production?
- What can't be verified without these tests?
- What technical debt is accumulating?
- What assumptions are we making?

Format as bullet list with **bold risk type**:
- **Zero coverage risk**: Cannot detect regressions in data processor X
- **CI/CD risk**: Pipeline may be failing if tests are gated
- **Deployment risk**: Recent bug fixes unverified
- **Maintenance risk**: Team velocity slows without test safety net

---

## Recommendations

**REQUIRED** - Actionable next steps organized by priority

### Immediate Actions (Priority 1)
**CRITICAL** blockers that must be resolved first

1. **Fix [specific issue]**:
   ```bash
   # Exact command to diagnose or fix
   ```
   - Why this matters
   - Expected outcome

2. **[Next critical action]**:
   - Steps to take
   - Success criteria

### Post-Fix Actions (Priority 2)
**HIGH** priority items after blockers cleared

3. **Create unit tests** for:
   - `module1.py`: Focus on [specific behavior]
   - `module2.py`: Cover [edge cases]

4. **Review test quality** for:
   - `test_module1.py`: Already good, keep pattern
   - `test_module2.py`: Refactor to avoid [anti-pattern]

### Continuous Improvement (Priority 3)
**MEDIUM** priority items for ongoing work

5. **Add coverage gating** to CI:
   ```yaml
   # Example configuration for pytest-cov
   ```

6. **Monitor [metric]** and iterate

**Always end with question**: "Would you like me to: 1) [option], 2) [option], 3) [option]?"

---

## RULES FOR CONSISTENCY

1. **Always use markdown tables** - Never plain text lists for structured data
2. **Always use code blocks** for commands, configs, errors
3. **Always use `backticks`** for module names, file paths, technical terms
4. **Always bold** decision keywords: HALT, CRITICAL, create-test, etc.
5. **Always include line counts** when referencing specific code locations (e.g., `module.py:42`)
6. **Always provide exact commands** - no "run the tests" without showing the command
7. **Always explain WHY** - don't just say "create test", say "create test to verify retry logic handles transient failures"
8. **Numbers over adjectives** - "39 tests failing" not "many tests failing"
9. **Concrete over vague** - "ModuleNotFoundError for pandas" not "dependency issue"
10. **Action-oriented** - Every finding maps to a decision, every decision maps to a recommendation
