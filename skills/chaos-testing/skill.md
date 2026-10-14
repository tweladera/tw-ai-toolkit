---
name: chaos-testing
description: Generates resilience tests for circuit breakers, retry logic, timeout handling, and graceful degradation — verifying that the application behaves correctly when downstream services fail. Stack-agnostic with support for Spring Boot (Resilience4j), NestJS, FastAPI, and generic HTTP clients.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: source
    type: string
    required: false
    default: ""
    description: "Path to service client files or directory. If omitted, auto-detects HTTP clients and downstream integrations from the codebase."
  - name: framework
    type: string
    required: false
    default: ""
    description: "Resilience framework: 'resilience4j' (Spring Boot), 'nestjs', 'fastapi', 'generic'. Auto-detected."
  - name: scenarios
    type: string
    required: false
    default: "all"
    description: "Comma-separated resilience scenarios: 'circuit-breaker', 'timeout', 'retry', 'fallback', 'bulkhead', 'rate-limit'. Default: all."
tags:
  - resilience
  - chaos-testing
  - circuit-breaker
  - fault-tolerance
  - timeout
  - retry
  - microservices
  - qa
invocation: tw-chaos-testing
---

# chaos-testing

## Description

Functional tests verify what the system does when everything works.
Resilience tests verify what the system does when things go wrong.

In a microservices architecture, partial failure is the normal operating condition —
a downstream payment service might be slow, a notification service might be unavailable,
a database might be overloaded. The question is not "will something fail?" but
"does the application handle failures gracefully?"

**What chaos-testing verifies:**

| Failure Mode | What to verify |
|---|---|
| Circuit breaker | After N failures, stops calling the service and uses fallback |
| Timeout | Requests exceeding threshold are cancelled, not left hanging |
| Retry | Transient failures are retried with backoff — but not permanently |
| Fallback | When primary service is down, degraded response is served |
| Bulkhead | Slow service does not exhaust the connection pool for other services |
| Rate limiting | Upstream throttling is handled without cascading failure |

**Principle:** resilience tests inject faults (via mocks, WireMock, Testcontainers,
or tools like Toxiproxy) and assert on the system's response to those faults.
They run as part of integration tests — no running chaos platform required.

## When to Use

- When adding a new downstream service integration
- When implementing circuit breakers, retries, or timeouts for the first time
- Before a high-traffic event (Black Friday, product launch) — verify the system degrades gracefully
- When an incident reveals unexpected behavior under downstream failure

Triggers: "test circuit breaker", "resilience tests", "what happens when the payment service
is down", "test retry logic", "timeout handling tests", "chaos engineering".

## Instructions

### Step 1 — Detect Downstream Integrations

```bash
# HTTP clients (Node.js)
rg "axios\.|fetch\(|got\.|HttpService\.|httpClient\." src/ --type ts | \
  grep -oP "https?://[^'\"]*|baseURL.*['\"][^'\"]*['\"]" | sort -u | head -20

# HTTP clients (Python)
rg "requests\.(get|post|put|delete)|httpx\.(get|post|put)|aiohttp" \
  src/ --type py | head -20

# HTTP clients (Java/Spring)
rg "RestTemplate\.|WebClient\.|FeignClient\|@FeignClient" \
  src/ --type java | head -20

# Queue/event consumers
rg "SqsClient\|KafkaConsumer\|RabbitMQ\|@KafkaListener\|@SqsListener" \
  src/ --type ts --type java | head -10
```

### Step 2a — Circuit Breaker Tests (Spring Boot / Resilience4j)

```java
// src/test/java/resilience/PaymentServiceCircuitBreakerTest.java
package resilience;

import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class PaymentServiceCircuitBreakerTest {

    @RegisterExtension
    static WireMockExtension wireMock = WireMockExtension.newInstance()
        .options(wireMockConfig().port(8089))
        .build();

    @Autowired PaymentGatewayClient paymentClient;
    @Autowired CircuitBreakerRegistry circuitBreakerRegistry;

    @BeforeEach
    void resetCircuitBreaker() {
        circuitBreakerRegistry.circuitBreaker("paymentGateway").reset();
    }

    @Test
    @Order(1)
    @DisplayName("Circuit breaker opens after threshold failures")
    void opensAfterThresholdFailures() {
        // Arrange — simulate payment service returning 500 repeatedly
        wireMock.stubFor(post(urlEqualTo("/api/charges"))
            .willReturn(serverError()));

        // Act — trigger failures until threshold (configured: 5 failures)
        for (int i = 0; i < 5; i++) {
            assertThatThrownBy(() -> paymentClient.charge(100.00, "USD"))
                .isInstanceOf(PaymentGatewayException.class);
        }

        // Assert — circuit is now OPEN
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("paymentGateway");
        assertThat(cb.getState()).isEqualTo(CircuitBreaker.State.OPEN);
    }

    @Test
    @Order(2)
    @DisplayName("Circuit breaker returns fallback when OPEN — does not call downstream")
    void returnsFallbackWhenOpen() {
        // Force circuit open
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("paymentGateway");
        cb.transitionToOpenState();

        // Act — call while circuit is open
        PaymentResult result = paymentClient.chargeWithFallback(100.00, "USD");

        // Assert — fallback was used, NO call to WireMock (downstream not called)
        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getReason()).isEqualTo("PAYMENT_SERVICE_UNAVAILABLE");
        wireMock.verify(0, postRequestedFor(urlEqualTo("/api/charges")));
    }

    @Test
    @Order(3)
    @DisplayName("Circuit breaker transitions to HALF_OPEN after wait duration")
    void transitionsToHalfOpenAfterWait() throws InterruptedException {
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("paymentGateway");
        cb.transitionToOpenState();

        // Wait for configured open state duration (test config: 2 seconds)
        Thread.sleep(2100);

        assertThat(cb.getState()).isEqualTo(CircuitBreaker.State.HALF_OPEN);
    }

    @Test
    @DisplayName("Timeout — request exceeding threshold is cancelled")
    void timeoutCancelsSlowRequest() {
        // Arrange — simulate slow payment service (5s response)
        wireMock.stubFor(post(urlEqualTo("/api/charges"))
            .willReturn(aResponse().withFixedDelay(5000).withStatus(200)));

        // Act + Assert — configured timeout is 2s, so this should throw
        assertThatThrownBy(() -> paymentClient.charge(100.00, "USD"))
            .isInstanceOf(PaymentTimeoutException.class)
            .hasMessageContaining("timeout");
    }
}
```

### Step 2b — Resilience Tests (NestJS / TypeScript)

```typescript
// tests/resilience/notification.resilience.spec.ts
import { Test } from '@nestjs/testing';
import nock from 'nock';
import { NotificationService } from '../../src/notifications/notification.service';
import { HttpModule } from '@nestjs/axios';

describe('NotificationService — Resilience', () => {
  let service: NotificationService;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [HttpModule],
      providers: [NotificationService],
    }).compile();
    service = module.get(NotificationService);
  });

  afterEach(() => nock.cleanAll());

  it('retries on transient failure — succeeds after 2 attempts', async () => {
    // First 2 calls fail with 503, third succeeds
    nock('https://notifications.internal')
      .post('/send').reply(503)
      .post('/send').reply(503)
      .post('/send').reply(200, { id: 'notif-001' });

    const result = await service.send({ userId: 'user-1', message: 'Order placed' });

    expect(result.success).toBe(true);
    expect(nock.pendingMocks()).toHaveLength(0); // all 3 calls made
  });

  it('stops retrying after max attempts — returns graceful error', async () => {
    // All 3 retry attempts fail
    nock('https://notifications.internal')
      .post('/send').reply(503)
      .post('/send').reply(503)
      .post('/send').reply(503);

    const result = await service.sendWithFallback({ userId: 'user-1', message: 'Order placed' });

    // Fallback: log to dead letter queue instead of throwing
    expect(result.queued).toBe(true);  // sent to DLQ
    expect(result.notified).toBe(false);
  });

  it('timeout — slow notification service does not block order completion', async () => {
    // Simulate 10-second response (configured timeout: 2s)
    nock('https://notifications.internal')
      .post('/send').delay(10000).reply(200);

    const startTime = Date.now();
    await service.sendNonBlocking({ userId: 'user-1', message: 'Order placed' });
    const elapsed = Date.now() - startTime;

    // Should not wait more than 2.5s (2s timeout + buffer)
    expect(elapsed).toBeLessThan(2500);
  });

  it('fallback response when notification service is completely down', async () => {
    nock('https://notifications.internal')
      .post('/send').replyWithError('ECONNREFUSED');

    const order = await service.placeOrderWithNotification({
      itemId: 'item-001',
      userId: 'user-1',
    });

    // Order should succeed even if notification fails
    expect(order.status).toBe('CONFIRMED');
    expect(order.notificationStatus).toBe('QUEUED_FOR_RETRY');
  });
});
```

### Step 2c — Resilience Tests (Python / FastAPI)

```python
# tests/resilience/test_payment_resilience.py
import pytest
import httpx
from unittest.mock import patch, AsyncMock
from app.services.payment_service import PaymentService
from app.exceptions import PaymentUnavailableError, PaymentTimeoutError

class TestPaymentServiceResilience:
    """Resilience tests for PaymentService — downstream failure scenarios"""

    @pytest.mark.asyncio
    async def test_retries_on_transient_error(self):
        """Service retries up to 3 times on 503 before succeeding"""
        call_count = 0

        async def mock_charge(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise httpx.HTTPStatusError("503", request=None, response=None)
            return {"id": "charge-001", "status": "success"}

        with patch.object(PaymentService, '_call_gateway', side_effect=mock_charge):
            service = PaymentService()
            result = await service.charge(amount=100.00, currency="USD")

        assert result["status"] == "success"
        assert call_count == 3  # retried twice, succeeded on third

    @pytest.mark.asyncio
    async def test_fallback_after_max_retries(self):
        """After 3 failed retries, returns degraded response instead of raising"""
        with patch.object(PaymentService, '_call_gateway',
                         side_effect=httpx.ConnectError("Connection refused")):
            service = PaymentService()
            result = await service.charge_with_fallback(amount=100.00, currency="USD")

        assert result["status"] == "pending_retry"
        assert result["error"] == "PAYMENT_GATEWAY_UNAVAILABLE"

    @pytest.mark.asyncio
    async def test_timeout_raises_specific_exception(self):
        """Requests exceeding timeout raise PaymentTimeoutError, not a generic exception"""
        async def slow_gateway(*args, **kwargs):
            await asyncio.sleep(10)  # 10s — exceeds 2s timeout

        with patch.object(PaymentService, '_call_gateway', side_effect=slow_gateway):
            service = PaymentService()
            with pytest.raises(PaymentTimeoutError) as exc_info:
                await service.charge(amount=100.00, currency="USD")

        assert "2s" in str(exc_info.value)  # timeout message mentions configured threshold

    @pytest.mark.asyncio
    async def test_circuit_breaker_stops_calls_after_threshold(self):
        """After 5 consecutive failures, circuit opens and stops calling gateway"""
        call_count = 0

        async def always_fail(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            raise httpx.ConnectError("Connection refused")

        service = PaymentService()
        with patch.object(service, '_call_gateway', side_effect=always_fail):
            for _ in range(10):
                try:
                    await service.charge(100.00, "USD")
                except Exception:
                    pass

        # Circuit opened after 5 failures — calls should stop at 5
        assert call_count == 5  # not 10 — circuit breaker stopped further calls
```

### Step 3 — Generate Chaos Test Summary

```markdown
# Resilience Test Report

**Generated by:** /tw-chaos-testing | v0.5.0
**Project:** [auto-detected]
**Framework:** Resilience4j (Spring Boot)
**Downstream services analyzed:** 4

## Services Covered

| Service | Circuit Breaker | Timeout | Retry | Fallback | Status |
|---|---|---|---|---|---|
| PaymentGatewayClient | ✅ Tested | ✅ Tested | ✅ Tested | ✅ Tested | COVERED |
| NotificationClient | ❌ Missing | ✅ Tested | ✅ Tested | ❌ Missing | PARTIAL |
| InventoryClient | ❌ Missing | ❌ Missing | ❌ Missing | ❌ Missing | NOT COVERED |
| ShippingClient | ❌ Missing | ✅ Tested | ❌ Missing | ❌ Missing | PARTIAL |

## Files Generated

- `src/test/java/resilience/PaymentServiceCircuitBreakerTest.java` — 4 scenarios
- `src/test/java/resilience/NotificationServiceResilienceTest.java` — 3 scenarios (fallback gap noted)

## Gaps Detected

### HIGH — InventoryClient has no resilience tests
Direct HTTP call to inventory service with no timeout, retry, or circuit breaker configured.
If inventory service is slow, the order thread will block indefinitely.

**Recommendation:**
1. Add `@CircuitBreaker(name = "inventory")` to `InventoryClient`
2. Configure timeout (recommend 1.5s for read operations)
3. Add fallback that uses cached inventory data

## Next Steps

1. Run tests: `mvn test -pl orders-service -Dtest="*ResilienceTest*"`
2. Configure WireMock for integration test profile
3. Add resilience tests to nightly CI pipeline (not PR gate — they are slower)
```

## Examples

### Example 1 — Generate resilience tests for all detected integrations

```
/tw-chaos-testing
```

### Example 2 — Focus on circuit breaker and timeout scenarios only

```
/tw-chaos-testing scenarios=circuit-breaker,timeout
```

### Example 3 — Spring Boot service with Resilience4j

```
/tw-chaos-testing source=src/main/java/clients/ framework=resilience4j
```

### Example 4 — NestJS microservice resilience tests

```
/tw-chaos-testing source=src/integrations/ framework=nestjs
```

## Dependencies

- **Spring Boot:** `spring-cloud-starter-circuitbreaker-resilience4j`, `wiremock-jre8` in test scope
- **NestJS:** `nock` for HTTP interception (`npm install -D nock`)
- **Python:** `pytest-asyncio`, `httpx` (mock via `unittest.mock`)
- **General:** Testcontainers or WireMock for service simulation

## Notes

- Resilience tests are slower than unit tests (involve HTTP mocking) — put them in the nightly pipeline, not the PR gate
- A service without a timeout is a reliability risk — always configure and test timeouts explicitly
- Circuit breaker tests require the actual circuit breaker to be configured in the application, not just tested in isolation
- Fallback behavior must be explicitly designed — "the fallback" is not "throw an exception"
- For Kafka/SQS consumers: test dead-letter queue behavior, not just happy path consumption
- Pair with `/tw-performance-baseline` — resilience tests verify behavior under failure, performance tests verify behavior under load
