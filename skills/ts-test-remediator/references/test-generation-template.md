# Test Generation Template

Align naming, assertions, and setup with **`ts-unit-test-governor` → `references/test-generation-standards.md`** when in doubt.

---

## New spec module outline (NestJS service)

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';

import { ClassName } from './class-name.service';
import { SomeEntity } from './entities/some.entity.postgres';

describe('ClassName', () => {
  let service: ClassName;

  const mockRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClassName,
        {
          provide: getRepositoryToken(SomeEntity),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<ClassName>(ClassName);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('methodName', () => {
    it('should return result when condition is met', async () => {
      // Arrange
      const input = 'test-id';
      mockRepository.findOne.mockResolvedValue({ id: input, value: 'data' });

      // Act
      const result = await service.methodName(input);

      // Assert
      expect(result).toBeDefined();
      expect(result.id).toBe(input);
      expect(mockRepository.findOne).toHaveBeenCalledWith({ where: { id: input } });
    });

    it('should throw NotFoundException when entity does not exist', async () => {
      // Arrange
      mockRepository.findOne.mockResolvedValue(null);

      // Act & Assert
      await expect(service.methodName('nonexistent'))
        .rejects
        .toThrow(NotFoundException);
    });
  });
});
```

---

## Plain class (no NestJS DI)

For mappers, utilities, or pure TypeScript classes:

```typescript
import { InventoryMapper } from './inventory.mapper.postgres';
import { InventoryEntity } from './entities/inventory.entity.postgres';

describe('InventoryMapper', () => {
  let mapper: InventoryMapper;

  beforeEach(() => {
    mapper = new InventoryMapper();
  });

  describe('toDomain', () => {
    it('should map all fields from entity to domain model', () => {
      // Arrange
      const entity: InventoryEntity = {
        id: 'inv-001',
        productCode: 'PROD-001',
        quantity: 10,
        warehouseId: 'wh-001',
      } as InventoryEntity;

      // Act
      const result = mapper.toDomain(entity);

      // Assert
      expect(result.id).toBe('inv-001');
      expect(result.productCode).toBe('PROD-001');
      expect(result.quantity).toBe(10);
    });

    it('should handle null optional fields without throwing', () => {
      // Arrange
      const entity = { id: 'inv-001', productCode: 'PROD-001', quantity: null } as any;

      // Act
      const result = mapper.toDomain(entity);

      // Assert
      expect(result.quantity).toBeNull();
    });
  });
});
```

---

## Controller spec outline

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { InventoryController } from './inventory.controller';
import { InventoryService } from '../../application/inventory.service';
import { NotFoundException } from '@nestjs/common';

describe('InventoryController', () => {
  let controller: InventoryController;

  const mockInventoryService = {
    findAll: jest.fn(),
    findById: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [InventoryController],
      providers: [
        {
          provide: InventoryService,
          useValue: mockInventoryService,
        },
      ],
    }).compile();

    controller = module.get<InventoryController>(InventoryController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getInventory', () => {
    it('should return list of inventory items', async () => {
      // Arrange
      const items = [{ id: 'inv-001' }, { id: 'inv-002' }];
      mockInventoryService.findAll.mockResolvedValue(items);

      // Act
      const result = await controller.getInventory();

      // Assert
      expect(result).toHaveLength(2);
      expect(mockInventoryService.findAll).toHaveBeenCalledTimes(1);
    });
  });
});
```

---

## Pipe spec outline

```typescript
import { ParseDatePipe } from './parse-date.pipe';
import { BadRequestException } from '@nestjs/common';

describe('ParseDatePipe', () => {
  let pipe: ParseDatePipe;

  beforeEach(() => {
    pipe = new ParseDatePipe();
  });

  it('should transform valid ISO date string to Date object', () => {
    const result = pipe.transform('2024-01-15', {} as any);
    expect(result).toBeInstanceOf(Date);
    expect(result.toISOString()).toContain('2024-01-15');
  });

  it('should throw BadRequestException for invalid date string', () => {
    expect(() => pipe.transform('not-a-date', {} as any))
      .toThrow(BadRequestException);
  });

  it.each([
    [''],
    ['2024-13-01'],
    ['abc'],
    ['2024/01/15'],
  ])('should throw for invalid input "%s"', (input) => {
    expect(() => pipe.transform(input, {} as any)).toThrow(BadRequestException);
  });
});
```

---

## Branch and error coverage (tier A / B)

- For each **non-trivial** `if` / conditional expression / early return, add a test that exercises the alternate path.
- For methods that **throw** or reject, add at least one test with `rejects.toThrow()` or `expect(() => ...).toThrow()`.
- Verify **mock calls** only when the contract matters:
  ```typescript
  expect(mockRepo.save).toHaveBeenCalledTimes(1);
  expect(mockRepo.save).toHaveBeenCalledWith(expect.objectContaining({ id: 'inv-001' }));
  ```
- Avoid over-specifying incidental calls (e.g., logger calls are usually not important to assert).

---

## Parameterized outline

When cases share structure:

```typescript
it.each([
  ['2024-01-01', true, 'valid ISO date'],
  ['2024-13-01', false, 'invalid month'],
  ['', false, 'empty string'],
  ['not-a-date', false, 'non-date string'],
])('should validate "%s" → %s (%s)', (input, expected, _description) => {
  const result = pipe.isValidDate(input);
  expect(result).toBe(expected);
});
```

Error cases parameterized:

```typescript
it.each([
  [null, 'null input'],
  [undefined, 'undefined input'],
  ['', 'empty string'],
])('should throw BadRequestException for %s', (input, _description) => {
  expect(() => pipe.transform(input as any, {} as any))
    .toThrow(BadRequestException);
});
```

---

## Testing async code

### Resolved promises

```typescript
it('should return saved entity', async () => {
  const saved = { id: 'inv-001', quantity: 10 };
  mockRepository.save.mockResolvedValue(saved);

  const result = await service.save({ quantity: 10 });

  expect(result.id).toBe('inv-001');
});
```

### Rejected promises

```typescript
it('should propagate DB error', async () => {
  mockRepository.save.mockRejectedValue(new Error('connection refused'));

  await expect(service.save({ quantity: 10 }))
    .rejects
    .toThrow('connection refused');
});
```

---

## update-test checklist

When updating existing specs:

- [ ] Add any newly required mock providers to `beforeEach` TestingModule
- [ ] Update `mockResolvedValue` / `mockReturnValue` to match new return types
- [ ] Update method call arguments to match new signatures
- [ ] Remove assertions that depended on prior implementation details
- [ ] Add assertions for new branches or exception types
- [ ] Run spec + coverage and confirm line coverage meets or improves toward the assigned tier
- [ ] `jest.clearAllMocks()` is in `afterEach` to prevent state leakage

---

## Fixture patterns

### Shared mock factory

```typescript
// Create a reusable mock factory in the spec file
const createMockRepository = () => ({
  findOne: jest.fn(),
  find: jest.fn(),
  save: jest.fn(),
  delete: jest.fn(),
});

describe('InventoryService', () => {
  let mockRepository: ReturnType<typeof createMockRepository>;

  beforeEach(async () => {
    mockRepository = createMockRepository();
    // ... TestingModule setup
  });
});
```

### beforeAll for expensive setup

```typescript
describe('InventoryMapper (stateless)', () => {
  let mapper: InventoryMapper;

  // Mapper has no side effects — create once per describe
  beforeAll(() => {
    mapper = new InventoryMapper();
  });

  it('...', () => { ... });
  it('...', () => { ... });
});
```
