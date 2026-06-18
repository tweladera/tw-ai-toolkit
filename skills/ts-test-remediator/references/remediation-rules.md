# Remediation Rules

Apply **`references/coverage-targets.md`** for tier assignment and post-remediation Istanbul checks.

---

## When the report says `create-test`

- Create `module-name.spec.ts` **colocated** with the production module (same directory).
- Assign a **coverage tier (A / B / C)** from `coverage-targets.md` before writing tests.
- Cover the smallest set of behaviors that provide meaningful regression protection **and** move line coverage toward the tier target:
  - happy path
  - branch or fallback path
  - error path (exceptions, validation failures)
- Test **public methods** first; test private methods only if they have complex logic and cannot be reached via public surface.
- Prefer one focused spec file over many fragmented ones.
- Use **`it.each`** when several cases share the same arrange/act shape.

## When the report says `update-test`

- Read the failing spec and the production module side by side.
- Look first for:
  - new constructor dependency added to the class
  - new method calls or collaborators
  - changed return types, interfaces, or DTOs
  - changed exception types or error shapes
  - mock returning wrong type after refactor
- Repair `beforeEach` setup before changing assertions.
- If all failures stem from one missing mock provider in `TestingModule`, fix that in `beforeEach` first.

## When the report says `review-test`

- Explain the ambiguity.
- Identify what evidence is missing.
- Prefer manual review to speculative code generation.

## Verification

- Run the narrowest possible spec first.
- If the new or updated specs pass, optionally run the containing package.
- **After** all edits for a batch, run `npm run test:cov` and record **line coverage per remediated module** vs tier target (`coverage-targets.md`).
- For `update-test`, prefer **no regression**: specs green; module coverage should not drop without justification.
- Report when verification or Istanbul could not be completed (environment, time, or skipped by user).

## File naming conventions

### Colocated spec (default — matches this project)

```
src/app/supply/inventory/inventory.service.ts
→ src/app/supply/inventory/inventory.service.spec.ts

src/infra/repo/inventory/inventory.repository.postgres.ts
→ src/infra/repo/inventory/inventory.repository.postgres.spec.ts

src/infra/rest/pipes/parse-date.pipe.ts
→ src/infra/rest/pipes/parse-date.pipe.spec.ts
```

Match the existing project convention — all specs are colocated with source files.

## NestJS TestingModule patterns

### Standard mock-everything pattern

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { InventoryService } from './inventory.service';
import { InventoryEntity } from './entities/inventory.entity.postgres';

describe('InventoryService', () => {
  let service: InventoryService;

  const mockRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
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

### Mocking another NestJS service

```typescript
const mockOtherService = {
  findById: jest.fn(),
  save: jest.fn(),
};

providers: [
  InventoryService,
  {
    provide: OtherService,
    useValue: mockOtherService,
  },
]
```

### Mocking TypeORM DataSource directly

```typescript
const mockDataSource = {
  query: jest.fn(),
  createQueryRunner: jest.fn().mockReturnValue({
    connect: jest.fn(),
    startTransaction: jest.fn(),
    commitTransaction: jest.fn(),
    rollbackTransaction: jest.fn(),
    release: jest.fn(),
    manager: { save: jest.fn(), find: jest.fn() },
  }),
};

providers: [
  StrategyClass,
  {
    provide: DataSource,
    useValue: mockDataSource,
  },
]
```

## Common update-test scenarios

### New constructor dependency added

**Before:**
```typescript
@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryEntity)
    private readonly repo: Repository<InventoryEntity>,
  ) {}
}
```

**After (new dependency added):**
```typescript
@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryEntity)
    private readonly repo: Repository<InventoryEntity>,
    private readonly logger: Logger,  // NEW
  ) {}
}
```

**Spec update:**
```typescript
const mockLogger = { log: jest.fn(), error: jest.fn(), warn: jest.fn() };

providers: [
  InventoryService,
  { provide: getRepositoryToken(InventoryEntity), useValue: mockRepository },
  { provide: Logger, useValue: mockLogger },  // ADD THIS
]
```

### Method signature changed

**Before:**
```typescript
async findById(id: string): Promise<InventoryEntity>
```

**After:**
```typescript
async findById(id: string, warehouseId: string): Promise<InventoryEntity>
```

**Spec update:**
```typescript
// Before
const result = await service.findById('inv-001');

// After
const result = await service.findById('inv-001', 'wh-001');
```

### Changed exception type

**Before:**
```typescript
it('should throw when not found', async () => {
  await expect(service.findById('x')).rejects.toThrow(Error);
});
```

**After:**
```typescript
it('should throw NotFoundException when not found', async () => {
  await expect(service.findById('x')).rejects.toThrow(NotFoundException);
});
```

## Mock and spy patterns

### jest.fn() for simple value returns

```typescript
mockRepository.findOne.mockResolvedValue({ id: 'inv-001', quantity: 10 });
mockRepository.findOne.mockResolvedValueOnce(null); // Only for next call
mockRepository.findOne.mockRejectedValue(new Error('DB error'));
```

### jest.spyOn() for partial mocks

```typescript
const findSpy = jest.spyOn(repository, 'findOne').mockResolvedValue(mockEntity);
expect(findSpy).toHaveBeenCalledWith({ where: { id: 'inv-001' } });
```

### Verifying mock calls

```typescript
// Called exactly once
expect(mockRepository.save).toHaveBeenCalledTimes(1);

// Called with specific arguments
expect(mockRepository.save).toHaveBeenCalledWith(
  expect.objectContaining({ id: 'inv-001' })
);

// NOT called
expect(mockRepository.delete).not.toHaveBeenCalled();
```
