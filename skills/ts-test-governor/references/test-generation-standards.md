# Test Generation Standards

When generating Jest unit tests for TypeScript/NestJS code, follow these standards to ensure maintainability, readability, and effectiveness.

---

## Framework Selection

### Jest + @nestjs/testing (Preferred for NestJS)

Use `@nestjs/testing` when:
- Testing NestJS services, controllers, guards, interceptors, or pipes
- Need to test DI-wired classes with mocked providers
- Project already uses `@nestjs/testing` in existing specs

```typescript
// NestJS TestingModule style
import { Test, TestingModule } from '@nestjs/testing';
import { InventoryService } from './inventory.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { InventoryEntity } from './entities/inventory.entity.postgres';

describe('InventoryService', () => {
  let service: InventoryService;
  const mockRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryService,
        {
          provide: getRepositoryToken(InventoryEntity),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<InventoryService>(InventoryService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });
});
```

### Plain Jest (for non-NestJS classes)

Use plain Jest when:
- Testing pure TypeScript classes, mappers, or utilities without DI
- Class can be instantiated directly with mocked constructor arguments

```typescript
// Plain Jest style
import { InventoryMapper } from './inventory.mapper.postgres';

describe('InventoryMapper', () => {
  let mapper: InventoryMapper;

  beforeEach(() => {
    mapper = new InventoryMapper();
  });
});
```

---

## Test Structure

### Arrange / Act / Assert Pattern

Always structure tests in three clear sections:

```typescript
it('should return inventory item when found by id', async () => {
  // Arrange
  const inventoryId = 'inv-001';
  const expectedInventory = { id: inventoryId, quantity: 10 };
  mockRepository.findOne.mockResolvedValue(expectedInventory);

  // Act
  const result = await service.findById(inventoryId);

  // Assert
  expect(result).toEqual(expectedInventory);
  expect(mockRepository.findOne).toHaveBeenCalledWith({ where: { id: inventoryId } });
});
```

### One Behavior Per Test

Each test should verify a single behavior or scenario:

```typescript
// Good - focused tests
it('should return inventory when item exists', async () => { ... });
it('should throw NotFoundException when item does not exist', async () => { ... });
it('should return empty array when no items match filter', async () => { ... });

// Bad - multiple behaviors
it('should handle all inventory scenarios', async () => { ... }); // Too broad!
```

---

## Naming Conventions

### Test Function Names

Use descriptive names that indicate:
1. What is being tested
2. The scenario/condition
3. Expected outcome

```typescript
// Good naming
it('should map postgres entity to domain model when all fields are present')
it('should throw NotFoundException when inventory id does not exist')
it('should return 400 when date format is invalid in pipe')

// Bad naming
it('should work')
it('test 1')
it('edge case')
```

### Describe Blocks

Use `describe` to group related tests:

```typescript
describe('InventoryService', () => {
  describe('findById', () => {
    it('should return inventory when found', ...)
    it('should throw NotFoundException when not found', ...)
  });

  describe('save', () => {
    it('should persist inventory and return saved entity', ...)
    it('should throw on duplicate key violation', ...)
  });
});
```

### File Names

Match production module names with `.spec.ts` suffix (colocated):
- Production: `inventory.service.ts`
- Test: `inventory.service.spec.ts`

---

## Mocking and Spying

### Mock Dependencies (not the class under test)

```typescript
// Good - mock the injected dependency
const mockRepository = {
  findOne: jest.fn(),
  save: jest.fn(),
};

// Bad - mock the service itself
jest.mock('./inventory.service'); // This defeats the purpose
```

### jest.fn() for Simple Mocks

```typescript
const mockLogger = {
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
};
```

### jest.spyOn() for Partial Mocks

```typescript
const findOneSpy = jest.spyOn(repository, 'findOne').mockResolvedValue(mockEntity);
expect(findOneSpy).toHaveBeenCalledWith({ where: { id: 'inv-001' } });
```

### When to Mock

**DO mock**:
- TypeORM repositories and data sources
- External HTTP clients (axios, HttpService)
- Kafka producers/consumers
- Logger services
- Other NestJS services injected as dependencies
- `Date.now()` or `new Date()` for deterministic time tests

**DON'T mock**:
- The class/service under test
- Simple data structures
- Pure functions without side effects
- Value objects or domain models

---

## Setup and Teardown

### beforeEach for Test Isolation

```typescript
describe('InventoryService', () => {
  let service: InventoryService;
  const mockRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryService,
        { provide: getRepositoryToken(InventoryEntity), useValue: mockRepository },
      ],
    }).compile();

    service = module.get<InventoryService>(InventoryService);
  });

  afterEach(() => {
    jest.clearAllMocks(); // Reset mock call counts between tests
  });
});
```

### jest.clearAllMocks() vs jest.resetAllMocks()

- `jest.clearAllMocks()` — Clears call history, keeps mock implementation
- `jest.resetAllMocks()` — Clears call history AND removes mock implementation
- `jest.restoreAllMocks()` — Restores original implementations (for spies)

---

## Parameterized Tests

### it.each for Multiple Input/Output Scenarios

```typescript
it.each([
  ['2024-01-01', true],
  ['2024-13-01', false],
  ['invalid', false],
  ['', false],
])('should validate date "%s" and return %s', (input, expected) => {
  const result = pipe.isValidDate(input);
  expect(result).toBe(expected);
});
```

### describe.each for Setup Variations

```typescript
describe.each([
  ['metric unit', MetricConfig],
  ['imperial unit', ImperialConfig],
])('with %s', (name, Config) => {
  let service: InventoryService;

  beforeEach(async () => {
    // setup with Config
  });

  it('should calculate correctly', () => { ... });
});
```

### When to Parametrize

**Good candidates**:
- Same logic, different inputs (date validation, format parsing)
- Boundary value testing
- Enum value coverage

**Bad candidates**:
- Tests with different mock setups
- Tests with different assertions
- Unrelated test scenarios

---

## Exception Testing

### Async exceptions with rejects

```typescript
it('should throw NotFoundException when inventory does not exist', async () => {
  // Arrange
  mockRepository.findOne.mockResolvedValue(null);

  // Act & Assert
  await expect(service.findById('nonexistent-id'))
    .rejects
    .toThrow(NotFoundException);
});
```

### Sync exceptions

```typescript
it('should throw when date string is invalid', () => {
  expect(() => pipe.transform('not-a-date')).toThrow(BadRequestException);
});
```

### Checking exception message

```typescript
await expect(service.findById('x'))
  .rejects
  .toThrow('Inventory with id x not found');
```

---

## Assertions

### Use Specific Assertions

```typescript
// Good - specific
expect(result).toBeDefined();
expect(result.items).toHaveLength(3);
expect(result.id).toBe('inv-001');
expect(mockRepository.save).toHaveBeenCalledTimes(1);
expect(mockRepository.save).toHaveBeenCalledWith(expect.objectContaining({ id: 'inv-001' }));

// Bad - too generic
expect(result).toBeTruthy(); // What property?
expect(true).toBe(true);     // Meaningless
```

### Partial Object Matching

```typescript
expect(mockRepository.save).toHaveBeenCalledWith(
  expect.objectContaining({
    id: 'inv-001',
    quantity: 10,
  })
);
```

---

## Test Data

### Use Realistic but Minimal Data

```typescript
// Good - minimal but realistic
const mockInventoryEntity = {
  id: 'inv-001',
  productCode: 'PROD-001',
  quantity: 10,
  warehouseId: 'wh-001',
};

// Bad - overly complex with irrelevant fields
const mockInventoryEntity = {
  id: 'inv-001',
  productCode: 'PROD-001',
  quantity: 10,
  warehouseId: 'wh-001',
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
  version: 1,
  // ... 15 more fields not used in the test
};
```

### Deterministic Data

```typescript
// Good - deterministic
it('should format date correctly', () => {
  const fixedDate = new Date('2024-01-15T10:00:00Z');
  jest.spyOn(global, 'Date').mockImplementation(() => fixedDate as any);
  const result = service.formatCurrentDate();
  expect(result).toBe('2024-01-15');
});

// Bad - non-deterministic
it('should format date correctly', () => {
  const result = service.formatCurrentDate(); // Uses current time
  expect(result).toBeTruthy(); // Weak assertion
});
```

---

## Test Independence

Each test must be isolated from others. Use `beforeEach` to reset state:

```typescript
// Good - independent tests via beforeEach
beforeEach(() => {
  jest.clearAllMocks();
  mockRepository.findOne.mockReset();
});

// Bad - shared mutable state between tests
mockRepository.findOne.mockReturnValue(something); // Affects all tests!
```

---

## Async Testing

### Always await async operations

```typescript
// Good
it('should return items', async () => {
  const result = await service.findAll();
  expect(result).toHaveLength(2);
});

// Bad - promise not awaited, assertion never runs meaningfully
it('should return items', () => {
  service.findAll().then(result => {
    expect(result).toHaveLength(2); // May not run before test ends
  });
});
```

---

## Checklist for Generated Tests

- [ ] Uses Jest with `@nestjs/testing` based on project convention
- [ ] Follows Arrange/Act/Assert pattern
- [ ] Has descriptive test name (what, condition, expected)
- [ ] Tests one behavior per `it` block
- [ ] Uses `jest.fn()` or `jest.spyOn()` for external dependencies
- [ ] Has specific, meaningful assertions
- [ ] Uses `beforeEach` for setup and `afterEach` for cleanup
- [ ] Is independent from other tests (`jest.clearAllMocks()`)
- [ ] Uses deterministic test data
- [ ] Correctly handles async with `await` and `async`
- [ ] Matches project code style and existing spec patterns
- [ ] Would actually catch regressions
