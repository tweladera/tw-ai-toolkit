---
name: integration-discovery
description: Scans OpenAPI/AsyncAPI specs, Spring controllers, NestJS routes, or Express routers to auto-discover API contracts, generates framework-agnostic Gherkin scenarios for each contract, and produces ready-to-run integration tests — without requiring any manual user story authoring.
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
    description: "Path to OpenAPI/AsyncAPI YAML/JSON, or source directory for annotation scanning (e.g. 'openapi/orders.yaml', 'src/controllers/', 'src/main/java/')."
  - name: output
    type: string
    required: false
    default: "both"
    description: "'gherkin' for Gherkin .feature files only, 'tests' for framework-specific test files only, 'both' for Gherkin + tests."
  - name: framework
    type: string
    required: false
    default: ""
    description: "Test framework: 'supertest' (NestJS/Express), 'rest-assured' (Spring), 'httpx' (FastAPI/Django). Auto-detected."
  - name: focus
    type: string
    required: false
    default: "all"
    description: "Comma-separated HTTP methods to focus on: 'GET,POST' limits generation to read and create scenarios. Default: all."
  - name: contract_mode
    type: string
    required: false
    default: "happy+error"
    description: "'happy' for 200/201 flows only, 'error' for 4xx/5xx flows only, 'happy+error' for both (default), 'full' adds boundary and auth scenarios."
tags:
  - integration
  - autodiscovery
  - openapi
  - asyncapi
  - gherkin
  - contract
  - spring
  - nestjs
  - express
  - fastapi
  - qa
invocation: tw-integration-discovery
---

# integration-discovery

## Description

The traditional integration test workflow is manual: a developer writes a controller,
a QA engineer reads the spec, writes scenarios in Gherkin, then writes test code.
Three people, three artifacts, three opportunities for drift.

`integration-discovery` collapses this into one step: **give it the spec or the
controllers, and it produces Gherkin + integration tests automatically.**

The Gherkin layer is the **agnostic contract** — not tied to any framework, readable
by product owners, and the source of truth for what the API promises.
The test layer is the **executable verification** — supertest, REST Assured, or httpx —
derived from the Gherkin, not written separately.

**Autodiscovery sources (in priority order):**
1. `openapi.yaml` / `openapi.json` — most complete; includes request/response schemas
2. `asyncapi.yaml` — for event-driven APIs (Kafka, SQS, SNS topics)
3. Spring `@RestController` / `@RequestMapping` annotations — scanned from Java source
4. NestJS `@Controller` / `@Get` / `@Post` decorators — scanned from TypeScript source
5. Express / Fastify router declarations — scanned from JavaScript/TypeScript source

**What makes this "agnostic":** The Gherkin `.feature` files describe behavior in
business language. The framework-specific test file is a derived artifact — swap
supertest for REST Assured by re-generating tests from the same Gherkin.

## When to Use

- When a new API is delivered without integration tests
- When a spec (OpenAPI/AsyncAPI) exists but no Gherkin or integration tests do
- After a major API refactoring — regenerate tests from the updated spec
- When onboarding a legacy service — reverse-engineer its contract from its controllers
- When the `e2e-test-governor` flags missing contract coverage for API endpoints

Triggers: "generate integration tests", "autodiscover API tests", "create tests from openapi",
"integration test coverage from spec", "no tests for the API", "test my controllers".

## Instructions

### Step 1 — Detect and Parse Source

**OpenAPI spec:**
```bash
# Validate spec exists and is parseable
python3 -c "
import sys, yaml, json
with open('{{source}}') as f:
    spec = yaml.safe_load(f) if '{{source}}'.endswith('.yaml') else json.load(f)

paths = spec.get('paths', {})
print(f'Endpoints found: {len(paths)}')
for path, methods in paths.items():
    for method in methods:
        if method in ['get','post','put','patch','delete']:
            responses = list(methods[method].get('responses', {}).keys())
            print(f'  {method.upper()} {path} -> {responses}')
"
```

**Spring Boot controllers (annotation scan):**
```bash
rg "@RestController|@Controller" src/main/ -l | while read f; do
  echo "=== $f ==="
  rg "@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|RequestMapping)" "$f" -o
done
```

**NestJS controllers:**
```bash
rg "@Controller\(|@Get\(|@Post\(|@Put\(|@Delete\(|@Patch\(" src/ --type ts -l | while read f; do
  echo "=== $f ===" && grep -E "@(Controller|Get|Post|Put|Delete|Patch)\(" "$f"
done
```

**Express/Fastify routes:**
```bash
rg "router\.(get|post|put|patch|delete)\(" src/ --type ts --type js -o | head -40
```

**AsyncAPI (event-driven):**
```bash
python3 -c "
import yaml
with open('{{source}}') as f:
    spec = yaml.safe_load(f)
channels = spec.get('channels', {})
for channel, config in channels.items():
    ops = [k for k in config if k in ['publish','subscribe','send','receive']]
    print(f'{channel}: {ops}')
"
```

### Step 2 — Build Contract Model

For each discovered endpoint, extract:

```
Endpoint: POST /api/orders
Request schema:
  - amount: number (required, >0)
  - currency: string (required, enum: USD|EUR|CLP)
  - itemId: string (required)
  - notes: string (optional)
Responses:
  201: { id: string, status: 'PENDING', createdAt: datetime }
  400: { error: string, details: ValidationError[] }
  401: { error: 'Unauthorized' }
  409: { error: 'Duplicate order' }
Auth: Bearer token required
```

For AsyncAPI, extract:
```
Channel: orders.created
Operation: publish
Payload schema: { orderId: string, userId: string, amount: number, timestamp: datetime }
```

### Step 3 — Generate Gherkin Scenarios (Agnostic Layer)

For each endpoint, generate `.feature` files following behavior-first naming:

```gherkin
# features/integration/orders/create-order.feature
# Generated by /tw-integration-discovery from openapi/orders.yaml
# DO NOT EDIT manually — regenerate from spec if API changes

Feature: Create Order API
  As a client application
  I want to submit a new order via POST /api/orders
  So that the order is registered and returns a confirmation

  Background:
    Given the API is running
    And I have a valid authentication token

  # ── Happy Path ───────────────────────────────────────────────

  Scenario: Successfully create a valid order
    Given a valid order payload with amount 100.00, currency "USD", itemId "item-001"
    When I POST to "/api/orders"
    Then the response status is 201
    And the response body contains a field "id" of type string
    And the response body contains "status" equal to "PENDING"
    And the response body contains "createdAt" of type datetime

  Scenario: Create order with minimum valid amount
    Given a valid order payload with amount 0.01, currency "CLP", itemId "item-002"
    When I POST to "/api/orders"
    Then the response status is 201

  # ── Validation Errors (400) ───────────────────────────────────

  Scenario: Reject order with missing required field
    Given an order payload without the "itemId" field
    When I POST to "/api/orders"
    Then the response status is 400
    And the response body contains "error"
    And the response body contains "details" as an array

  Scenario: Reject order with invalid currency
    Given an order payload with currency "INVALID"
    When I POST to "/api/orders"
    Then the response status is 400

  Scenario: Reject order with amount zero
    Given an order payload with amount 0
    When I POST to "/api/orders"
    Then the response status is 400

  # ── Authentication Errors (401) ───────────────────────────────

  Scenario: Reject unauthenticated request
    Given I have no authentication token
    When I POST to "/api/orders"
    Then the response status is 401

  Scenario: Reject expired token
    Given I have an expired authentication token
    When I POST to "/api/orders"
    Then the response status is 401

  # ── Business Rule Errors (409) ────────────────────────────────

  Scenario: Reject duplicate order within the same session
    Given I have already submitted an order with itemId "item-dup"
    When I POST to "/api/orders" again with the same itemId "item-dup"
    Then the response status is 409
    And the response body contains "error" equal to "Duplicate order"
```

For AsyncAPI channels:
```gherkin
# features/integration/events/order-created.feature
Feature: Order Created Event
  As a downstream consumer
  I want to receive well-formed order.created events
  So that I can process them reliably

  Scenario: Order creation publishes a valid event
    Given an order is successfully created
    When I consume from the "orders.created" channel
    Then the event payload contains "orderId" of type string
    And the event payload contains "userId" of type string
    And the event payload contains "amount" of type number
    And the event payload contains "timestamp" of type datetime
```

### Step 4 — Generate Integration Tests

**NestJS + Supertest (TypeScript):**

```typescript
// tests/integration/orders/create-order.integration.spec.ts
// Generated by /tw-integration-discovery from: create-order.feature
// Gherkin source: features/integration/orders/create-order.feature

import request from 'supertest';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../../src/app.module';
import { getAuthToken } from '../../helpers/auth';
import { OrderFactory } from '../../factories/order.factory';

describe('POST /api/orders — Create Order', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = module.createNestApplication();
    await app.init();
    authToken = await getAuthToken(app);
  });

  afterAll(async () => { await app.close(); });

  // ── Happy Path ─────────────────────────────────────────────────

  it('201 — creates a valid order', async () => {
    const payload = { amount: 100.00, currency: 'USD', itemId: `item-${Date.now()}` };
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    expect(typeof res.body.id).toBe('string');
    expect(res.body.status).toBe('PENDING');
    expect(res.body.createdAt).toBeDefined();
  });

  it('201 — minimum valid amount (0.01)', async () => {
    const payload = { amount: 0.01, currency: 'CLP', itemId: `item-min-${Date.now()}` };
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    expect(res.status).toBe(201);
  });

  // ── Validation Errors ──────────────────────────────────────────

  it('400 — rejects missing itemId', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: 100, currency: 'USD' });  // no itemId

    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
    expect(Array.isArray(res.body.details)).toBe(true);
  });

  it('400 — rejects invalid currency', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: 100, currency: 'INVALID', itemId: 'item-001' });

    expect(res.status).toBe(400);
  });

  it('400 — rejects zero amount', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: 0, currency: 'USD', itemId: 'item-001' });

    expect(res.status).toBe(400);
  });

  // ── Auth Errors ────────────────────────────────────────────────

  it('401 — rejects unauthenticated request', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .send({ amount: 100, currency: 'USD', itemId: 'item-001' });

    expect(res.status).toBe(401);
  });

  it('401 — rejects expired token', async () => {
    const expiredToken = 'Bearer expired.jwt.token';
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', expiredToken)
      .send({ amount: 100, currency: 'USD', itemId: 'item-001' });

    expect(res.status).toBe(401);
  });

  // ── Business Rules ─────────────────────────────────────────────

  it('409 — rejects duplicate order', async () => {
    const payload = { amount: 100, currency: 'USD', itemId: 'item-dup-unique' };
    // First request succeeds
    await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    // Second request with same itemId
    const res = await request(app.getHttpServer())
      .post('/api/orders')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('Duplicate order');
  });
});
```

**Spring Boot + REST Assured (Java):**

```java
// src/test/java/integration/orders/CreateOrderIntegrationTest.java
// Generated by /tw-integration-discovery from: create-order.feature

package integration.orders;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class CreateOrderIntegrationTest {

    @LocalServerPort
    int port;

    String authToken;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        authToken = AuthHelper.getToken();  // fetch test JWT
    }

    // ── Happy Path ────────────────────────────────────────────────

    @Test
    @DisplayName("201 — creates a valid order")
    void createValidOrder() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .contentType(ContentType.JSON)
            .body("""
                {"amount": 100.00, "currency": "USD", "itemId": "item-001"}
                """)
        .when()
            .post("/api/orders")
        .then()
            .statusCode(201)
            .body("id", notNullValue())
            .body("status", equalTo("PENDING"))
            .body("createdAt", notNullValue());
    }

    @Test
    @DisplayName("400 — rejects missing itemId")
    void rejectsMissingItemId() {
        given()
            .header("Authorization", "Bearer " + authToken)
            .contentType(ContentType.JSON)
            .body("""{"amount": 100.00, "currency": "USD"}""")
        .when()
            .post("/api/orders")
        .then()
            .statusCode(400)
            .body("error", notNullValue())
            .body("details", notNullValue());
    }

    @Test
    @DisplayName("401 — rejects unauthenticated request")
    void rejectsUnauthenticated() {
        given()
            .contentType(ContentType.JSON)
            .body("""{"amount": 100, "currency": "USD", "itemId": "item-001"}""")
        .when()
            .post("/api/orders")
        .then()
            .statusCode(401);
    }
}
```

**FastAPI + httpx (Python):**

```python
# tests/integration/orders/test_create_order.py
# Generated by /tw-integration-discovery from: create-order.feature

import pytest
import httpx
from tests.helpers.auth import get_auth_token

BASE_URL = "http://localhost:8000"

@pytest.fixture(scope="module")
def auth_headers():
    token = get_auth_token()
    return {"Authorization": f"Bearer {token}"}

class TestCreateOrder:
    """POST /api/orders — Create Order"""

    def test_creates_valid_order(self, auth_headers):
        """201 — happy path"""
        payload = {"amount": 100.00, "currency": "USD", "itemId": "item-001"}
        response = httpx.post(f"{BASE_URL}/api/orders", json=payload, headers=auth_headers)

        assert response.status_code == 201
        body = response.json()
        assert isinstance(body["id"], str)
        assert body["status"] == "PENDING"
        assert "createdAt" in body

    def test_rejects_missing_itemId(self, auth_headers):
        """400 — validation error"""
        payload = {"amount": 100.00, "currency": "USD"}
        response = httpx.post(f"{BASE_URL}/api/orders", json=payload, headers=auth_headers)

        assert response.status_code == 400
        body = response.json()
        assert "error" in body
        assert isinstance(body.get("details"), list)

    def test_rejects_unauthenticated(self):
        """401 — no token"""
        payload = {"amount": 100, "currency": "USD", "itemId": "item-001"}
        response = httpx.post(f"{BASE_URL}/api/orders", json=payload)

        assert response.status_code == 401
```

### Step 5 — Generate Discovery Summary

```markdown
# Integration Discovery Report

**Source:** openapi/orders.yaml
**Generated by:** /tw-integration-discovery | v0.4.0
**Framework:** supertest (NestJS)
**Contract mode:** happy+error

## Endpoints Discovered

| Method | Path | Scenarios | Feature file | Test file |
|---|---|---|---|---|
| GET | /api/orders | 4 | create-order.feature | create-order.integration.spec.ts |
| GET | /api/orders/:id | 3 | get-order.feature | get-order.integration.spec.ts |
| POST | /api/orders | 7 | list-orders.feature | list-orders.integration.spec.ts |
| DELETE | /api/orders/:id | 3 | delete-order.feature | delete-order.integration.spec.ts |
| PATCH | /api/orders/:id/status | 4 | update-status.feature | update-status.integration.spec.ts |

**Total scenarios generated:** 21
**Files created:** 10 (5 .feature + 5 .spec.ts)

## Coverage Notes

- Auth scenarios generated for all 5 endpoints (401 coverage)
- Validation error scenarios generated where schema has required fields
- 409 Conflict scenario generated for POST /api/orders (documented in spec)
- Boundary scenarios (full mode): not included — use contract_mode=full to add

## Schema Gaps Detected

- `GET /api/orders` has no documented 401 response in spec — generated based on auth inference
- `DELETE /api/orders/:id` has no 404 response documented — added "not found" scenario with TODO

## Next Steps

1. Run tests against a running instance: `npx jest tests/integration/`
2. Add test factories for domain objects: `/tw-test-factory source=src/entities/`
3. If auth setup is complex, see `tests/helpers/auth.ts` — customize for your token strategy
4. Re-run this skill when the OpenAPI spec changes — tests are derived, not manually maintained
```

## Examples

### Example 1 — Generate from OpenAPI spec (full output)

```
/tw-integration-discovery source=openapi/orders.yaml output=both framework=supertest
```

### Example 2 — Gherkin only from Spring controllers

```
/tw-integration-discovery source=src/main/java/com/example/controllers/ output=gherkin
```

### Example 3 — REST Assured tests for specific HTTP methods

```
/tw-integration-discovery source=openapi/api.yaml framework=rest-assured focus=GET,POST
```

### Example 4 — Full contract scenarios including boundary and auth

```
/tw-integration-discovery source=src/routes/ contract_mode=full
```

### Example 5 — AsyncAPI event contracts

```
/tw-integration-discovery source=asyncapi/events.yaml output=gherkin
```

## Dependencies

- OpenAPI/AsyncAPI spec file **OR** annotated controller/route source code
- For supertest: `supertest` + `@nestjs/testing` installed
- For REST Assured: `io.rest-assured:rest-assured` in test dependencies
- For httpx: `httpx` + `pytest` installed
- Running application instance only needed for test execution — not for generation

## Notes

- The Gherkin `.feature` files are the source of truth — do not edit test files manually; regenerate from spec
- Re-run this skill when the OpenAPI spec changes to keep tests in sync with the contract
- `contract_mode=full` adds boundary testing (max/min values, string lengths) — useful but generates many more scenarios
- For complex auth flows (OAuth2, multi-tenant), customize `tests/helpers/auth.ts` after generation
- AsyncAPI support generates Gherkin only — framework-specific event consumer tests require manual scaffolding of broker connection
- This skill pairs naturally with `/tw-contract-coverage` — use contract-coverage to detect gaps, integration-discovery to fill them
