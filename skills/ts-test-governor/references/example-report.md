# TypeScript Unit Test Governance Report - Example

**Generated**: 2026-05-26 10:00:00
**Skill version**: 1.0
**Analysis tool**: `.claude/skills/ts-unit-test-governor`

---

## Executive Summary

- **Repository analyzed**: `/workspace/run-service-api`
- **Overall decision**: **CREATE TESTS**
- **Primary risk**: Core service and use case modules have zero unit test coverage, making it impossible to verify business logic or detect regressions before production deployment.

---

## Findings

| Area | File or module | Finding | Severity | Action |
| --- | --- | --- | --- | --- |
| Unit Tests | `src/app/supply/inventory/inventory.service.ts` | Core service with 5 public methods — no spec file | **CRITICAL** | Create comprehensive spec |
| Unit Tests | `src/infra/rest/replay/filters/replay-filters.builder.ts` | Builder with branching logic — unmapped | **HIGH** | Create unit tests |
| Coverage Gaps | `src/infra/rest/mappers/application-exception.mapper.ts` | Exception mapping logic with 6 branches — no spec | **HIGH** | Create tests for all exception types |
| Unit Tests | `src/infra/repo/replay/strategies/supply.strategy.spec.ts` | Spec exists but failing — mock for DataSource missing | **HIGH** | Update mock in beforeEach |
| Dependencies | `package.json` | `--coverage-reporters=json-summary` not in default test:cov script | **MEDIUM** | Add reporter for governance script |
| Test Quality | `src/infra/logging/logging.spec.ts` | Spec has no `expect()` assertions — only calls | **MEDIUM** | Add meaningful assertions |

---

## Impacted Modules

| Module | Test status | Coverage signal | Decision | Notes |
| --- | --- | --- | --- | --- |
| `src/app/supply/inventory/inventory.service.ts` | **UNMAPPED** | No spec | **create-test** | Test all public methods and error paths |
| `src/infra/rest/replay/filters/replay-filters.builder.ts` | **UNMAPPED** | No spec | **create-test** | Cover builder branching and edge cases |
| `src/infra/rest/mappers/application-exception.mapper.ts` | **UNMAPPED** | No spec | **create-test** | Test all 6 exception type mappings |
| `src/infra/repo/replay/strategies/supply.strategy.ts` | **BROKEN** | Spec failing | **update-test** | Fix DataSource mock in TestingModule |
| `src/infra/repo/replay/strategies/maintenance.strategy.ts` | **BROKEN** | Spec failing | **update-test** | Same fix as supply.strategy.spec.ts |
| `src/infra/metric/metric.service.ts` | **PASSING** | ~85% lines | **no-change** | Good spec, keep pattern |
| `src/infra/rest/pipes/parse-date.pipe.ts` | **PASSING** | ~92% lines | **no-change** | Edge cases well covered |
| `src/infra/rest/http-exception.filter.ts` | **PASSING** | ~90% lines | **no-change** | Exception handling well tested |
| `src/infra/logging/logging.ts` | **PASSING** | ~70% lines | **update-test** | Add assertions to logging.spec.ts |
| `src/infra/infrastructure.module.ts` | **N/A** | N/A | **no-test-needed** | NestJS module wiring only |
| `src/infra/replay.module.ts` | **N/A** | N/A | **no-test-needed** | NestJS module wiring only |

---

## Root Cause Analysis

**Problem**: Two strategy spec files fail because the DataSource mock is missing from the TestingModule provider list.

**Evidence**:
- `Nest can't resolve dependencies of SupplyStrategy (?). Please make sure that the argument DataSource at index [0] is available in the RootTestModule context.`
- Same error in `supply.strategy.spec.ts` and `maintenance.strategy.spec.ts`
- 2 spec files failing with identical root cause

**Diagnosis**:
- Both strategy classes inject TypeORM `DataSource` directly in the constructor
- The `TestingModule.createTestingModule()` in both specs provides only `SupplyStrategy` / `MaintenanceStrategy` but omits the `DataSource` provider mock
- Fix requires adding `{ provide: DataSource, useValue: mockDataSource }` to the providers array

**Impact**:
- Cannot verify strategy selection logic
- Coverage for both strategy files reports 0% (specs don't run)
- CI will block merge if coverage threshold is enforced

---

## Suggested or Generated Tests

| Target | Type | Why it matters | Status |
| --- | --- | --- | --- |
| `InventoryService.findAll` | unit | Paginated query with optional filters — branching logic | **READY** |
| `InventoryService.findById` | unit | Returns 404 when not found — regression-critical | **GENERATED** |
| `ReplayFiltersBuilder.build` | unit | Filter object construction with optional date ranges | **READY** |
| `ApplicationExceptionMapper.toHttpException` | unit | Maps 6 domain exceptions to HTTP status codes | **READY** |
| `SupplyStrategy` mock fix | update | Fix DataSource mock in beforeEach | **GENERATED** |

### Generated Test — InventoryService.findById

```typescript
// src/infra/repo/supply/warehouse-inventory/inventory/adapters/inventory.repository.postgres.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { InventoryRepositoryPostgres } from './inventory.repository.postgres';
import { InventoryEntity } from '../entities/inventory.entity.postgres';

describe('InventoryRepositoryPostgres', () => {
  let repository: InventoryRepositoryPostgres;

  const mockTypeOrmRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryRepositoryPostgres,
        {
          provide: getRepositoryToken(InventoryEntity),
          useValue: mockTypeOrmRepository,
        },
      ],
    }).compile();

    repository = module.get<InventoryRepositoryPostgres>(InventoryRepositoryPostgres);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findById', () => {
    it('should return mapped domain model when entity is found', async () => {
      // Arrange
      const entityId = 'inv-001';
      const mockEntity = { id: entityId, productCode: 'PROD-001', quantity: 10 };
      mockTypeOrmRepository.findOne.mockResolvedValue(mockEntity);

      // Act
      const result = await repository.findById(entityId);

      // Assert
      expect(result).toBeDefined();
      expect(mockTypeOrmRepository.findOne).toHaveBeenCalledWith({
        where: { id: entityId },
      });
    });

    it('should return null when entity is not found', async () => {
      // Arrange
      mockTypeOrmRepository.findOne.mockResolvedValue(null);

      // Act
      const result = await repository.findById('nonexistent');

      // Assert
      expect(result).toBeNull();
    });
  });
});
```

### Generated Fix — SupplyStrategy mock

```typescript
// src/infra/repo/replay/strategies/supply.strategy.spec.ts (fix)
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { SupplyStrategy } from './supply.strategy';

describe('SupplyStrategy', () => {
  let strategy: SupplyStrategy;

  const mockDataSource = {
    query: jest.fn(),
    createQueryRunner: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SupplyStrategy,
        {
          provide: DataSource,  // <-- This was missing
          useValue: mockDataSource,
        },
      ],
    }).compile();

    strategy = module.get<SupplyStrategy>(SupplyStrategy);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(strategy).toBeDefined();
  });
});
```

---

## Risks and Limitations

- **Zero coverage risk**: `InventoryService` and `ReplayFiltersBuilder` process critical business logic with no unit test protection
- **CI/CD risk**: Coverage threshold (95% lines) will block future PRs when new untested code is added
- **Deployment risk**: Strategy selection logic (`SupplyStrategy`, `MaintenanceStrategy`) is untested due to broken specs
- **Maintenance risk**: `logging.spec.ts` has no assertions — spec passes but provides zero regression protection
- **Regression risk**: `ApplicationExceptionMapper` maps 6 domain exceptions to HTTP codes — any change is undetected

---

## Recommendations

### Immediate Actions (Priority 1)

1. **Fix broken strategy specs** (2 files, same fix):
   ```bash
   # Add DataSource mock provider to TestingModule in both spec files
   # supply.strategy.spec.ts and maintenance.strategy.spec.ts
   npx jest src/infra/repo/replay/strategies/ --forceExit
   ```
   - Expected outcome: 2 spec files go from BROKEN to PASSING

2. **Create spec for InventoryService** (CRITICAL coverage gap):
   ```bash
   touch src/app/supply/warehouse-inventory/inventory/inventory.service.spec.ts
   npx jest src/app/supply/warehouse-inventory/inventory/inventory.service.spec.ts --forceExit
   ```

### Post-Fix Actions (Priority 2)

3. **Create unit tests** for:
   - `replay-filters.builder.ts`: Cover optional date range and filter combinations
   - `application-exception.mapper.ts`: Test all 6 exception type mappings to HTTP status codes

4. **Fix test quality** in:
   - `logging.spec.ts`: Replace empty calls with `expect(logger.log).toHaveBeenCalledWith(...)` assertions

### Continuous Improvement (Priority 3)

5. **Add `json-summary` reporter** to default coverage script:
   ```json
   "test:cov": "jest --coverage --coverage-reporters=text --coverage-reporters=json-summary"
   ```

6. **Add pre-commit spec check** for changed source files:
   ```bash
   npx jest --findRelatedTests $CHANGED_FILES --passWithNoTests --bail
   ```

---

**Would you like me to:**
1. **Generate the complete spec** for `InventoryService` with all public method scenarios?
2. **Apply the DataSource mock fix** to both failing strategy spec files?
3. **Create specs** for `ReplayFiltersBuilder` and `ApplicationExceptionMapper` with full branch coverage?
