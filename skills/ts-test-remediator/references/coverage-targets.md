# Coverage targets after remediation

These are **default targets** for **line coverage on the module under test** (Istanbul via `jest --coverage`, unit test execution). The project-level threshold in `package.json` defines the global floor; these tier targets apply per-module during remediation.

## Tiers (assign before generating tests)

| Tier | Typical production modules | Line coverage target | Rationale |
|------|---------------------------|----------------------|-----------|
| **A** | Business logic services, use cases, domain processors, validators, mappers with branching | **≥ 90%** | Core business logic; regressions are expensive. |
| **B** | Repository adapters, REST controllers, filters, guards, interceptors, pipes with real logic | **≥ 80%** | Real logic, but some branches may require integration tests. |
| **C** | Thin helpers, simple delegation classes, low branching utilities | **≥ 70%** | Meaningful behavior covered; chasing 90% yields brittle tests. |

## Modules out of tier chasing

Do **not** inflate coverage artificially for:

- NestJS module files (`*.module.ts`)
- TypeORM entity files with only column decorators
- DTO files with only class-validator decorators
- Enum or type definition files (`*.enum.ts`, `*.type.ts`)
- Barrel re-export files (`index.ts`)
- Entry point (`main.ts`)
- Code marked `no-test-needed` by the governor

For those, follow the report; do not apply tier A/B targets.

## When targets are not reachable in one pass

Document in the remediation summary:

- **Unreachable branch:** e.g. defensive catch block that only triggers on real DB error — requires integration test
- **Partial mock:** TypeORM behavior cannot be exercised without a real connection — recommend integration follow-up
- **review-test:** halt numeric target until ambiguity is resolved

## Verification commands (Jest + Istanbul)

After changing specs for module `src/app/supply/inventory/inventory.service.ts`:

```bash
# Full suite with coverage
npm run test:cov

# Only the affected spec with module-level coverage
npx jest src/app/supply/inventory/inventory.service.spec.ts \
  --coverage \
  --collectCoverageFrom="src/app/supply/inventory/inventory.service.ts" \
  --coverageDirectory=coverage-check \
  --coverageReporters=text \
  --forceExit
```

Then inspect:
- Terminal: Shows line/branch/function/statement % with missing lines
- `coverage/index.html` → navigate to the module for line-by-line view
- `coverage/coverage-summary.json` → machine-readable per-module percentages

## Istanbul configuration

Already in `package.json` (do not duplicate):

```json
"jest": {
  "collectCoverageFrom": [
    "**/*.(t|j)s",
    "!**/*.module.ts",
    "!main.ts",
    "!**/*.command.ts",
    "!**/*.enum.ts",
    "!**/*.type.ts",
    "!**/entities/index.ts",
    "!**/usecases/index.ts",
    "!config/**",
    "!infra/telemetry/**",
    "!**/*.spec.ts"
  ],
  "coverageThreshold": {
    "global": {
      "lines": 95,
      "functions": 95,
      "branches": 90,
      "statements": 95
    }
  }
}
```

Use `/* istanbul ignore next */` for unreachable defensive branches:

```typescript
/* istanbul ignore next */
if (process.env.NODE_ENV === 'debug') {
  // debug-only code
}
```

## Reporting in the remediation output

For each remediated production module, add one line:

`Module` | `Tier` | `Line coverage (after)` | `Meets target?` | `Notes`

If jest --coverage was not run, state `not verified` and the reason.

## Example output table

| Module | Tier | Line coverage (after) | Meets target? | Notes |
|--------|------|----------------------|---------------|-------|
| `src/app/supply/inventory/inventory.service.ts` | A | 92% | Yes | All branches covered |
| `src/infra/repo/inventory/inventory.repository.postgres.ts` | B | 83% | Yes | Exception paths tested |
| `src/infra/rest/pipes/parse-date.pipe.ts` | B | 95% | Yes | Edge cases covered |
| `src/infra/repo/replay/strategies/supply.strategy.ts` | B | 74% | No (target 80%) | Network error path needs integration test |
