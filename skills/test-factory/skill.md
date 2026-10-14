---
name: test-factory
description: Generates test data factory classes from domain models (TypeORM entities, SQLAlchemy models, JPA entities) with cleanup strategies, ensuring E2E and integration tests are isolated, deterministic, and leave no pollution between runs.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: source
    type: string
    required: true
    default: ""
    description: Path to entity/model file or directory (e.g. 'src/entities/' or 'src/orders/order.entity.ts').
  - name: framework
    type: string
    required: false
    default: ""
    description: "Factory framework: 'fishery' (TypeScript), 'factory-boy' (Python), 'instancio' (Java). Auto-detected."
  - name: cleanup
    type: string
    required: false
    default: "afterEach"
    description: "Cleanup strategy: 'afterEach' (delete after each test), 'transaction' (rollback after each test), 'truncate' (truncate tables in afterAll)."
  - name: output_dir
    type: string
    required: false
    default: ""
    description: "Output directory for factory files. Defaults to 'src/test/factories/' or 'tests/factories/'."
tags:
  - test-data
  - factories
  - fishery
  - factory-boy
  - instancio
  - test-isolation
  - qa
invocation: tw-test-factory
---

# test-factory

## Description

Generates test data factories that create deterministic, isolated test objects for any
test layer (unit, integration, E2E). Solves the two biggest test data problems in mature
test suites:

1. **Pollution between tests**: Test A creates an order, Test B finds it and breaks
2. **Coupling to production data**: Tests depend on specific IDs or states that may not exist

**Factory pattern:** Instead of creating test objects with fixed data scattered across tests,
a factory encapsulates defaults and makes variations explicit. Each test creates exactly
what it needs and gets a unique, isolated dataset.

```typescript
// Before: fragile, coupled, no cleanup
const order = { id: 1, amount: 100, status: 'PENDING' };

// After: isolated, deterministic, self-cleaning
const order = await OrderFactory.create({ amount: 100 });  // creates in DB, cleans up after
```

## When to Use

- Before writing integration or E2E tests that need real database objects
- When tests are failing due to leftover data from previous runs
- When test setup code is duplicated across many test files
- When E2E fixtures (JSON files) are becoming stale or environment-dependent

Triggers: "test data factory", "generate test fixtures", "tests are polluting each other",
"create test builders", "factory-boy setup".

## Instructions

### Step 1 — Scan Entity/Model Files

```bash
# TypeORM entities
rg "@Entity\(\)" --type ts -l | sort

# SQLAlchemy models
rg "class.*Base\)|class.*Model\)|declarative_base" --type py -l | sort

# JPA entities
rg "@Entity" --type java -l | sort
```

For each entity, extract:
- Class name and table name
- Fields with types (`@Column`, `name`, `type`)
- Relationships (`@ManyToOne`, `@OneToMany`, `ForeignKey`)
- Nullable fields vs required
- Constraints (unique, min/max length)

### Step 2 — Generate Factories

**TypeScript — Fishery:**

```typescript
// tests/factories/order.factory.ts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { getDataSource } from '../helpers/data-source';
import { Order, OrderStatus } from '../../src/entities/order.entity';

export const OrderFactory = Factory.define<Order>(({ sequence, onCreate }) => {
  // onCreate: persist to DB when .create() is called
  onCreate(async (order) => {
    const repo = getDataSource().getRepository(Order);
    return repo.save(order);
  });

  return {
    id:        sequence,               // unique per test
    amount:    faker.number.float({ min: 1, max: 10000, fractionDigits: 2 }),
    currency:  'USD',
    status:    OrderStatus.PENDING,
    createdAt: new Date('2026-01-01'), // fixed date — deterministic
    updatedAt: new Date('2026-01-01'),
    // Relations — composed with other factories
    user: undefined,  // set explicitly: OrderFactory.create({ user: await UserFactory.create() })
  };
});

// Usage in tests:
// const order = await OrderFactory.create();                      // DB insert + cleanup
// const draftOrder = OrderFactory.build({ status: 'DRAFT' });   // no DB — unit tests
// const orders = await OrderFactory.createList(3);               // 3 orders
```

**Python — factory-boy:**

```python
# tests/factories/order_factory.py
import factory
from factory.django import DjangoModelFactory  # or SQLAlchemyModelFactory
from factory import Faker, LazyFunction, SubFactory
from datetime import date
from src.models import Order, OrderStatus

class UserFactory(DjangoModelFactory):
    class Meta:
        model = 'auth.User'

    username = factory.Sequence(lambda n: f'test-user-{n}')
    email = factory.LazyAttribute(lambda o: f'{o.username}@example.com')
    is_active = True

class OrderFactory(DjangoModelFactory):
    class Meta:
        model = Order

    amount    = factory.Faker('pydecimal', left_digits=4, right_digits=2, positive=True)
    currency  = 'USD'
    status    = OrderStatus.PENDING
    user      = SubFactory(UserFactory)
    created_at = factory.LazyFunction(lambda: date(2026, 1, 1))  # deterministic

# Usage:
# order = OrderFactory()                          # creates in DB
# order = OrderFactory.build()                    # no DB — unit tests
# orders = OrderFactory.create_batch(3)           # 3 orders
# draft = OrderFactory(status=OrderStatus.DRAFT)  # override one field
```

**Java — Instancio:**

```java
// src/test/java/factories/OrderFactory.java
package com.example.factories;

import com.example.domain.Order;
import com.example.domain.OrderStatus;
import org.instancio.Instancio;
import org.instancio.Model;
import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.instancio.Select.field;

public class OrderFactory {

    // Base model — deterministic defaults
    public static Model<Order> baseModel() {
        return Instancio.of(Order.class)
            .set(field(Order::getStatus), OrderStatus.PENDING)
            .set(field(Order::getCurrency), "USD")
            .set(field(Order::getCreatedAt), LocalDateTime.of(2026, 1, 1, 0, 0))
            // Random but bounded amount
            .generate(field(Order::getAmount),
                gen -> gen.math().bigDecimal().min(BigDecimal.ONE).max(BigDecimal.valueOf(10000)))
            .toModel();
    }

    public static Order build() {
        return Instancio.create(baseModel());
    }

    public static Order buildWith(BigDecimal amount, OrderStatus status) {
        return Instancio.of(baseModel())
            .set(field(Order::getAmount), amount)
            .set(field(Order::getStatus), status)
            .create();
    }
}

// Usage in test:
// var order = OrderFactory.build();
// var draftOrder = OrderFactory.buildWith(BigDecimal.valueOf(100), OrderStatus.DRAFT);
```

### Step 3 — Generate Cleanup Helpers

**afterEach cleanup (TypeScript):**

```typescript
// tests/helpers/cleanup.ts
import { getDataSource } from './data-source';
import { Order } from '../../src/entities/order.entity';

const createdIds: Map<string, number[]> = new Map();

export function trackCreated(entity: string, id: number) {
  if (!createdIds.has(entity)) createdIds.set(entity, []);
  createdIds.get(entity)!.push(id);
}

export async function cleanupAll() {
  const ds = getDataSource();
  // Delete in reverse dependency order to avoid FK violations
  for (const id of createdIds.get('Order') ?? []) {
    await ds.getRepository(Order).delete(id);
  }
  createdIds.clear();
}

// In test file:
// afterEach(async () => { await cleanupAll(); });
```

**Transaction rollback (fastest cleanup — TypeScript):**

```typescript
// tests/helpers/transaction-cleanup.ts
import { DataSource, EntityManager } from 'typeorm';

export async function withTransactionCleanup(
  dataSource: DataSource,
  testFn: (manager: EntityManager) => Promise<void>
) {
  const queryRunner = dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();
  try {
    await testFn(queryRunner.manager);
    // Rollback regardless — no data persists after test
  } finally {
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
  }
}
```

### Step 4 — Generate Usage Examples

For each factory, generate a usage snippet showing:
1. Unit test (`.build()` — no DB)
2. Integration test (`.create()` — DB with cleanup)
3. E2E test (`.create()` with `afterEach` cleanup)

### Step 5 — Confirm and Save

```
Test factories generated
Framework: [fishery|factory-boy|instancio]
Cleanup strategy: [afterEach|transaction|truncate]

Files created:
  tests/factories/order.factory.ts
  tests/factories/user.factory.ts
  tests/helpers/cleanup.ts

Entities covered: Order, User, [...]
Relations handled: Order.user (SubFactory)

Usage pattern:
  Unit:        const order = OrderFactory.build({ amount: 100 })
  Integration: const order = await OrderFactory.create()
  Cleanup:     afterEach(async () => cleanupAll())

Next step: import factories in your test files and replace hardcoded test data
```

## Examples

### Example 1 — Generate factories for all TypeORM entities

```
/tw-test-factory source=src/entities/ framework=fishery cleanup=transaction
```

### Example 2 — Single entity with afterEach cleanup

```
/tw-test-factory source=src/orders/order.entity.ts cleanup=afterEach
```

### Example 3 — Python SQLAlchemy with factory-boy

```
/tw-test-factory source=src/models/ framework=factory-boy cleanup=transaction
```

## Dependencies

- **TypeScript:** `fishery` + `@faker-js/faker` installable (`npm install -D fishery @faker-js/faker`)
- **Python:** `factory-boy` + `Faker` installable (`pip install factory-boy Faker`)
- **Java:** `instancio-junit5` in test dependencies
- TypeORM / SQLAlchemy / JPA entity files accessible

## Notes

- Use `.build()` in unit tests (no DB) and `.create()` in integration/E2E (with DB)
- Transaction rollback is the fastest cleanup strategy but requires the test to run within a transaction
- afterEach deletion is simpler but slower — use for E2E tests where transactions aren't available
- Never use `factory.random()` for IDs or dates that appear in assertions — always set deterministic values
- Relations (ManyToOne, ForeignKey) should use SubFactory — never hardcode related IDs
