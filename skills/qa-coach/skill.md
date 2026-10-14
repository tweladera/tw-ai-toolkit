---
name: qa-coach
description: Analyzes source code, pull requests, or module designs for testability anti-patterns, explains WHY each pattern makes testing harder, and proposes concrete refactoring paths — bridging the gap between developer decisions and QA consequences.
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
    description: "Path to file, directory, or 'git-diff' to analyze the current staged/unstaged changes."
  - name: mode
    type: string
    required: false
    default: "analyze"
    description: "'analyze' to report testability issues and refactoring suggestions. 'pr-review' to produce a QA-focused PR review comment. 'score' to output a numeric testability score (0–100) per module."
  - name: stack
    type: string
    required: false
    default: ""
    description: "Tech stack context: 'spring', 'nestjs', 'express', 'django', 'fastapi'. Auto-detected from imports."
tags:
  - testability
  - refactoring
  - code-review
  - design
  - coaching
  - qa
invocation: tw-qa-coach
---

# qa-coach

## Description

Most testability problems are design problems in disguise. A class with 12 constructor
dependencies, a service that calls the file system directly, a repository that embeds business
logic — these are not test problems. They are design signals that tests expose.

`qa-coach` reads source code through the lens of a senior SDET and surfaces:

1. **Testability anti-patterns** — what makes the code hard to test and why
2. **Design signals** — what the anti-pattern reveals about the underlying design
3. **Refactoring path** — the minimum change that restores testability without over-engineering
4. **Test cost estimate** — how many extra test lines each anti-pattern adds

**The QA coaching philosophy:** Developers don't write untestable code maliciously.
They often don't see the testing consequence of a design choice made for speed.
This skill provides the vocabulary and the "why" — not just "this is bad" but
"this forces every test to spin up a database when it doesn't need to."

## When to Use

- During a PR review where the governance report flags a module as untestable
- When a developer asks "why is this so hard to test?"
- Before a refactoring sprint — identify which modules will have the highest testability ROI
- After adding a new module — validate its design before it accumulates test debt

Triggers: "why is this untestable", "testability review", "how do I make this easier to test",
"code is hard to test", "qa review", "test design feedback".

## Instructions

### Step 1 — Detect Stack and Scan Files

```bash
# Auto-detect stack from imports
rg "import.*spring|@SpringBootApplication" --type java -l | head -3
rg "import.*nestjs|@Module\(" --type ts -l | head -3
rg "from django|from fastapi" --type py -l | head -3
```

If `source=git-diff`:
```bash
git diff --name-only HEAD | grep -E "\.(ts|js|py|java)$"
```

### Step 2 — Classify Testability Anti-Patterns

Scan each file for the following patterns:

---

#### Anti-Pattern 1: Hidden Dependencies (Static Calls / Singletons)

```typescript
// ANTI-PATTERN — static call hides a dependency
class OrderService {
  createOrder(data: CreateOrderDto) {
    const date = Date.now();           // hidden clock dependency
    Logger.log('Creating order...');   // hidden logger dependency
    const id = UUID.generate();        // hidden ID generator dependency
    return this.repo.save({ ...data, id, createdAt: date });
  }
}
```

**Why this breaks testing:**
- `Date.now()` makes every test time-sensitive — tests written at 9am fail at midnight
- `UUID.generate()` produces a different ID each run — impossible to assert the ID in tests
- `Logger.log()` couples the test environment to a logging system

**Refactoring path:**
```typescript
// TESTABLE — all dependencies are injected and mockable
class OrderService {
  constructor(
    private readonly repo: OrderRepository,
    private readonly clock: ClockService,  // injectable clock
    private readonly idGen: IdGenerator,   // injectable ID generator
  ) {}

  createOrder(data: CreateOrderDto) {
    return this.repo.save({
      ...data,
      id: this.idGen.generate(),
      createdAt: this.clock.now(),
    });
  }
}
```

**Test cost without fix:** Every test needs `jest.useFakeTimers()` + `jest.spyOn(UUID, 'generate')` — 6–10 extra setup lines per test.

---

#### Anti-Pattern 2: God Class / Single Responsibility Violation

**Detection heuristic:**
- Class > 300 lines
- Constructor with > 5 injected dependencies
- Method count > 15
- Mixed concerns: business logic + persistence + HTTP + email in the same class

```java
// ANTI-PATTERN — OrderService does everything
@Service
public class OrderService {
  // 8 injected dependencies
  public OrderService(OrderRepo repo, UserRepo userRepo, EmailService email,
                      PaymentGateway payment, InventoryService inventory,
                      NotificationService notif, AuditService audit,
                      MetricsService metrics) { ... }

  public Order createOrder(...) { /* 80 lines */ }
  public void cancelOrder(...) { /* 60 lines */ }
  public void refundOrder(...) { /* 70 lines */ }  // calls PaymentGateway directly
  public void notifyUser(...) { /* 30 lines */ }   // calls EmailService + NotifService
  public void auditOrder(...) { /* 40 lines */ }   // calls AuditService + MetricsService
}
```

**Why this breaks testing:**
- Testing `createOrder` requires mocking 8 dependencies — setup is longer than the assertion
- A change to `PaymentGateway` breaks tests for `createOrder` even if payment isn't called
- High cognitive load: which mock controls which behavior?

**Refactoring path:**
```java
// OrderCreationService — single responsibility: create orders
// OrderCancellationService — single responsibility: cancel/refund
// OrderNotificationHandler — event-driven notification
// Each is independently testable with 1–2 mocks
```

**Test cost without fix:** 8-mock setup per test × 30 test cases = 240 lines of mock boilerplate.

---

#### Anti-Pattern 3: Direct Infrastructure Access

```python
# ANTI-PATTERN — service reads from file system directly
class ReportService:
    def generate_report(self, order_id: str) -> str:
        # Direct file system access — impossible to unit test without real files
        template_path = f"/etc/app/templates/report_{order_id}.html"
        with open(template_path, 'r') as f:
            template = f.read()
        return template.replace('{{order_id}}', order_id)
```

**Why this breaks testing:**
- Unit tests need the real file system to exist
- CI runners may not have `/etc/app/templates/`
- File content changes break tests without touching the service code

**Refactoring path:**
```python
# Inject a template loader — mockable in tests
class ReportService:
    def __init__(self, template_loader: TemplateLoader):
        self._loader = template_loader

    def generate_report(self, order_id: str) -> str:
        template = self._loader.load(f"report_{order_id}.html")
        return template.replace('{{order_id}}', order_id)

# Test:
# loader = Mock(); loader.load.return_value = "<html>{{order_id}}</html>"
# service = ReportService(loader)
# assert service.generate_report("123") == "<html>123</html>"
```

---

#### Anti-Pattern 4: Business Logic in Persistence Layer

```typescript
// ANTI-PATTERN — repository contains business rules
@Injectable()
export class OrderRepository {
  async findActiveOrders(userId: string) {
    // Business rule (max 5 active) embedded in query
    return this.db.query(
      `SELECT * FROM orders WHERE user_id = $1 AND status = 'ACTIVE'
       AND created_at > NOW() - INTERVAL '30 days'
       LIMIT 5`,
      [userId]
    );
  }
}
```

**Why this breaks testing:**
- Testing the "max 5 active orders" rule requires a real database
- Changing the rule requires touching the repository — breaks separation of concerns
- Integration tests run slower than unit tests — this forces all rule tests to be integration tests

**Refactoring path:**
```typescript
// Repository: pure data access — no business rules
async findActiveOrdersByUser(userId: string): Promise<Order[]> {
  return this.db.query(
    `SELECT * FROM orders WHERE user_id = $1 AND status = 'ACTIVE'`,
    [userId]
  );
}

// Service: business rule — testable with a mock repository
async getRecentActiveOrders(userId: string): Promise<Order[]> {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const orders = await this.repo.findActiveOrdersByUser(userId);
  return orders
    .filter(o => o.createdAt > thirtyDaysAgo)
    .slice(0, 5);  // rule lives in service — unit testable
}
```

---

#### Anti-Pattern 5: Non-Deterministic Behavior

```typescript
// ANTI-PATTERN — output depends on environment/time/random
async function assignOrderToAgent(orderId: string): Promise<Agent> {
  const agents = await this.agentRepo.findAvailable();
  // Random assignment — test can never assert which agent is selected
  return agents[Math.floor(Math.random() * agents.length)];
}
```

**Refactoring path:** Inject a `Randomizer` or `AssignmentStrategy` — allows deterministic tests by injecting a fixed-return mock.

---

#### Anti-Pattern 6: Missing Ports/Interfaces for External Systems

```python
# ANTI-PATTERN — direct SDK call, not behind an interface
import boto3

class NotificationService:
    def send(self, user_id: str, message: str):
        client = boto3.client('sns')  # hardcoded AWS SDK
        client.publish(TopicArn='arn:aws:sns:...', Message=message)
```

**Refactoring path:**
```python
# Define a port (interface)
class NotificationPort(ABC):
    @abstractmethod
    def send(self, user_id: str, message: str): ...

# Inject the adapter in production, a mock in tests
class SnsNotificationAdapter(NotificationPort):
    def send(self, user_id: str, message: str):
        boto3.client('sns').publish(...)
```

---

### Step 3 — Compute Testability Score (mode=score)

Score each module from 0–100 using penalty deductions:

| Issue | Penalty |
|---|---|
| Each hidden static dependency (Date, UUID, Logger, etc.) | -5 pts |
| Each direct infrastructure call (file, DB, HTTP, cloud SDK) | -10 pts |
| Constructor with > 5 dependencies | -15 pts |
| Business logic in persistence layer | -20 pts |
| Non-deterministic behavior without injectable strategy | -10 pts |
| No interfaces for external systems | -10 pts |
| Class > 300 lines with mixed concerns | -15 pts |

Score bands:
- **80–100**: Highly testable — minimal setup required per test
- **60–79**: Testable with moderate effort — some mocking needed
- **40–59**: Significant test debt — refactoring before new tests recommended
- **0–39**: Critical — writing effective tests is not feasible without redesign

### Step 4 — Generate Report

#### mode=analyze output:

```markdown
# QA Testability Report

**File:** src/orders/order.service.ts
**Testability Score:** 45/100
**Generated by:** /tw-qa-coach | v0.4.0

## Anti-Patterns Found

### CRITICAL — Hidden Dependencies (3 instances)
- Line 12: `Date.now()` — forces jest.useFakeTimers() in every test
- Line 14: `UUID.generate()` — non-deterministic IDs break snapshot assertions
- Line 31: `Logger.error()` — static call couples tests to log output

**Refactoring effort:** Low (30 min) — inject ClockService, IdGenerator
**Test debt eliminated:** ~8 lines of mock setup per test × estimated 15 tests = 120 lines

### HIGH — God Class (constructor has 7 dependencies)
- Lines 1–45: OrderService has mixed responsibilities: order creation, payment processing, email dispatch
- Recommended split: OrderCreationService + PaymentProcessor + OrderNotifier

**Refactoring effort:** Medium (2–3h) — extract classes, keep existing tests passing
**Test debt eliminated:** Reduces from 7-mock setup to 1–2 mocks per test

### MEDIUM — No Interface for EmailService
- Line 28: `this.emailClient.send()` — depends on concrete EmailClient, not an interface
- Add `EmailPort` interface → allows `FakeEmailPort` in tests

## Testability Score: 45/100

Score breakdown:
- Hidden deps ×3:   -15 pts
- Constructor >5:   -15 pts
- No email port:    -10 pts
- No file issues:     0 pts
- Base:            +95 pts (no DB-embedded logic, no non-determinism)

## Recommended Refactoring Order

1. Extract ClockService + IdGenerator (30 min) — immediate test unlock
2. Add EmailPort interface (15 min) — enables FakeEmailPort in tests
3. Split OrderService (2–3h) — reduces mock surface per test dramatically

## Next Step

Run `/tw-ts-test-remediator` after refactoring to generate tests for the new structure.
```

#### mode=pr-review output:

```markdown
## QA Review — Testability

**PR impact on testability:** Negative (-15 pts from baseline)

### Changes that introduce test debt:

**`src/orders/order.service.ts` (lines 45–67):**
The new `assignAgent()` method calls `Math.random()` directly. This makes the assignment
logic non-deterministic — unit tests cannot assert which agent was selected without
mocking the global `Math` object, which is fragile.

**Suggested fix:** Inject an `AgentAssignmentStrategy` interface.
`RandomAssignmentStrategy` in production, `FixedAssignmentStrategy([agentA])` in tests.

**`src/notifications/email.service.ts` (lines 12–15):**
Direct `nodemailer.createTransport()` call — no injection point for test doubles.
Add `TransportPort` interface or use NestJS `@Inject(MAIL_TRANSPORT)` token.

These are not blocking, but they will increase test setup cost for anyone writing
tests for the affected paths.
```

## Examples

### Example 1 — Analyze a service file

```
/tw-qa-coach source=src/orders/order.service.ts
```

### Example 2 — QA-focused PR review of staged changes

```
/tw-qa-coach source=git-diff mode=pr-review
```

### Example 3 — Score all services for testability

```
/tw-qa-coach source=src/services/ mode=score
```

### Example 4 — Spring Boot controller analysis

```
/tw-qa-coach source=src/main/java/com/example/controllers/ stack=spring
```

## Dependencies

- Source code accessible in the working directory
- For `git-diff` mode: git repository with staged or unstaged changes
- No additional packages required — this is a static analysis skill

## Notes

- Testability score is an indicator, not a mandate — a score of 60 is not a blocker, it is a backlog item
- Hidden dependencies are the highest ROI fix: low effort, immediate unit test unlock
- God classes signal a domain model problem — splitting them often reveals missing domain concepts
- This skill complements `ts-test-governor` and `java-test-governor`: governor says "coverage is low",
  qa-coach explains "here's why writing tests is so hard"
- Run after governance reports flag a module as CRITICAL or HIGH gap
