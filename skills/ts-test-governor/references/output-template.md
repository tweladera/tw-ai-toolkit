# Output Template

Use this template for ALL test governance reports. Every section is REQUIRED unless explicitly marked optional.

---

## Executive Summary

**REQUIRED** - Start every report with this section

- **Repository analyzed**: Full path or name of the repo/directory
- **Overall decision**: One of:
  - `HALT` - Critical blockers prevent any test work
  - `FIX TESTS FIRST` - Existing specs broken, must fix before new tests
  - `CREATE TESTS` - No blockers, proceed with new test creation
  - `UPDATE TESTS` - Focus on updating existing specs
  - `NO ACTION NEEDED` - Coverage adequate
- **Primary risk**: One sentence describing the biggest threat (e.g., "Zero test coverage on core service logic", "Use case modules lack unit tests", "Specs exist but mocks are broken")

---

## Findings

**REQUIRED** - Tabular summary of all issues found

| Area | File or module | Finding | Severity | Action |
| --- | --- | --- | --- | --- |
| Dependencies | `package.json` | Description of dependency issue | CRITICAL / HIGH / MEDIUM / LOW | Specific action needed |
| Unit Tests | `module.service.spec.ts` | What's broken or missing | CRITICAL / HIGH / MEDIUM / LOW | Fix / Create / Update |
| Coverage Gaps | `module.service.ts` | Why this gap matters | CRITICAL / HIGH / MEDIUM / LOW | Create test / No action |

**Severity guide**:
- **CRITICAL**: Blocks all testing, runtime failures, zero coverage on critical paths
- **HIGH**: Missing tests for core business logic, broken specs blocking CI
- **MEDIUM**: Missing tests for secondary logic, incomplete coverage
- **LOW**: Nice-to-have tests for simple DTOs, config modules

**Minimum 3 findings** - If fewer, explain why in section

---

## Impacted Modules

**REQUIRED** - Map every production module to its test status

| Module | Test status | Coverage signal | Decision | Notes |
| --- | --- | --- | --- | --- |
| `module.service.ts` | BROKEN / PASSING / UNMAPPED / N/A | Coverage %, test count, or "No spec" | create-test / update-test / no-change / no-test-needed | Brief context |

**Test status values**:
- `BROKEN`: Spec exists but failing
- `PASSING`: Spec exists and passing
- `UNMAPPED`: No spec file exists
- `N/A`: Not applicable (DTO, entity without logic, module file, etc.)

**Decision values**:
- `create-test`: New spec needed
- `update-test`: Existing spec needs fixes
- `no-change`: Spec adequate as-is
- `no-test-needed`: Module doesn't merit unit test

**Include all modules** from inventory script output

---

## Root Cause Analysis

**CONDITIONAL** - Required when tests are failing or there's a systemic issue

Provide detailed analysis when:
- Specs fail at runtime
- Multiple specs share same failure pattern
- Dependency conflicts exist
- Framework/version compatibility issues

Structure:
```
**Problem**: One-sentence summary
**Evidence**: Error messages, stack traces, or patterns
**Diagnosis**: Why this is happening (mocks, config, dependencies, etc.)
**Impact**: What can't be done because of this
```

Example:
```
**Problem**: Jest fails to resolve NestJS module dependencies at test runtime
**Evidence**:
  - Nest can't resolve dependencies of InventoryService (?). Please make sure that the argument Repository<InventoryEntity> at index [0] is available in the RootTestModule context.
  - 8 spec files failing with same DI error
**Diagnosis**: TestingModule.createTestingModule() is missing the TypeORM repository mock provider
**Impact**: Zero functional test coverage on repository layer, cannot verify DB queries
```

**Omit this section** if no systemic issues

---

## Suggested or Generated Tests

**REQUIRED** - What tests should be created/updated

| Target | Type | Why it matters | Status |
| --- | --- | --- | --- |
| `InventoryService.findById` | unit | Core lookup with fallback to 404 | BLOCKED / READY / GENERATED |

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
- **Zero coverage risk**: Cannot detect regressions in InventoryService logic
- **CI/CD risk**: Coverage threshold (95% lines) will fail if new code is untested
- **Deployment risk**: Recent bug fixes unverified before production
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

### Post-Fix Actions (Priority 2)
**HIGH** priority items after blockers cleared

3. **Create unit tests** for:
   - `module.service.ts`: Focus on [specific behavior]
   - `mapper.ts`: Cover [edge cases]

4. **Review test quality** for:
   - `module.service.spec.ts`: Already good, keep pattern
   - `controller.spec.ts`: Refactor to avoid [anti-pattern]

### Continuous Improvement (Priority 3)
**MEDIUM** priority items for ongoing work

5. **Add coverage gating** to CI:
   ```yaml
   # Example configuration for jest --coverage
   ```

6. **Monitor [metric]** and iterate

**Always end with question**: "Would you like me to: 1) [option], 2) [option], 3) [option]?"

---

## RULES FOR CONSISTENCY

1. **Always use markdown tables** - Never plain text lists for structured data
2. **Always use code blocks** for commands, configs, errors
3. **Always use `backticks`** for module names, file paths, technical terms
4. **Always bold** decision keywords: HALT, CRITICAL, create-test, etc.
5. **Always include line counts** when referencing specific code locations (e.g., `module.service.ts:42`)
6. **Always provide exact commands** - no "run the tests" without showing the command
7. **Always explain WHY** - don't just say "create test", say "create test to verify retry logic handles transient failures"
8. **Numbers over adjectives** - "12 spec files failing" not "many specs failing"
9. **Concrete over vague** - "Cannot read properties of undefined (reading 'find')" not "mock issue"
10. **Action-oriented** - Every finding maps to a decision, every decision maps to a recommendation
