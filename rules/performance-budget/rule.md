---
name: performance-budget
description: Behavioral rule that instructs AI assistants to flag potential performance regressions at design time — before implementing queries, loops, API calls, or data transformations that could silently degrade P95 latency.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: full
  codex: partial
tags:
  - performance
  - n-plus-one
  - latency
  - database
  - optimization
  - mindset
  - rule
---

# performance-budget — Rule Fragment

Add this fragment to `CLAUDE.md` or `.cursorrules` to activate performance-aware behavior.

---

## Rule Fragment (paste into CLAUDE.md)

```markdown
## Performance Budget Behavior

When implementing database queries, loops over collections, external API calls,
or data transformations that will execute on every request, surface potential
performance implications BEFORE writing the code.

**Triggers for performance review:**
- Any database query inside a loop (N+1 problem)
- Any query with no WHERE clause on a large table
- Any missing database index on a frequently queried field
- Any synchronous call to an external service in the request path
- Any unbounded collection loaded entirely into memory
- Any serialization of deeply nested objects in a response

**What to surface before implementing:**
1. Will this query execute once, or once per item in a collection?
2. Is this query filtered? Does the filter field have an index?
3. Will this external call add latency to the user-facing response?
4. Is this data expected to grow? If the table has 10M rows, what happens to this query?
5. Can this operation be done asynchronously or cached?

**Patterns to flag immediately:**
- Loading a list then querying per item → use JOIN or batch load (e.g., `findByIds([...])`)
- `SELECT *` on a wide table → select only needed columns
- No pagination on a list endpoint → add limit/offset or cursor
- Blocking await on a notification/email send → make it async (event, queue)
- Eager loading all relations by default → use lazy loading or explicit select

**How to report:**
"⚡ Performance note: [description of potential issue] — [suggested approach]"

Then implement using the more performant pattern, or note the tradeoff explicitly
if the simpler approach is acceptable given the current scale.

**Performance budget thresholds (adjust per project):**
- API response time: P95 < 500ms under normal load
- Database query time: < 100ms for indexed reads
- Background jobs: < 30s per unit
- Batch operations: process in chunks of max 1000 records
```

---

## What This Rule Changes

**Without this rule:**
```typescript
// Fetches orders, then queries user for each — N+1 query
async getOrdersWithUsers() {
  const orders = await this.orderRepo.find();
  return Promise.all(orders.map(async order => ({
    ...order,
    user: await this.userRepo.findById(order.userId),  // 1 query per order
  })));
}
```

**With this rule:**
```
⚡ Performance note: This pattern executes 1 + N database queries (N = number of orders).
If there are 1000 orders, this is 1001 queries per request. Using a single JOIN query instead.
```
```typescript
// 1 query — orders joined with users
async getOrdersWithUsers() {
  return this.orderRepo.find({
    relations: ['user'],  // single LEFT JOIN query
  });
}
```

---

## Common N+1 Patterns by Stack

**TypeScript / TypeORM:**
```typescript
// ❌ N+1
const orders = await Order.find();
for (const order of orders) {
  order.user = await User.findOne(order.userId);
}

// ✅ Single query
const orders = await Order.find({ relations: ['user'] });
```

**Python / Django ORM:**
```python
# ❌ N+1
orders = Order.objects.all()
for order in orders:
    print(order.user.email)  # 1 query per iteration

# ✅ Single query
orders = Order.objects.select_related('user').all()
```

**Java / Spring Data JPA:**
```java
// ❌ N+1 — default lazy loading in loop
List<Order> orders = orderRepo.findAll();
orders.forEach(o -> System.out.println(o.getUser().getEmail())); // N queries

// ✅ JPQL with JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.user")
List<Order> findAllWithUsers();
```

---

## Pairing

Run `/tw-performance-baseline mode=baseline` to establish measurable P95 thresholds.
Run `/tw-performance-baseline mode=compare` before each release to detect regressions.
