---
name: java-test-remediator
description: Consumes a Java/Spring Boot test governance report, assigns Jacoco coverage tiers per class, then generates or updates maintainable JUnit 5 + Mockito test classes to meet tiered line-coverage targets.
status: stable
version_added: v0.4.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: report_file
    type: string
    required: false
    default: ""
    description: Path to the governance report produced by /tw-java-test-governor. If omitted, uses the most recent TEST_GOVERNANCE_REPORT_*.md.
  - name: base_ref
    type: string
    required: false
    default: ""
    description: Git ref used by /tw-java-test-governor. Used to regenerate the report if no report file is provided.
  - name: build_tool
    type: string
    required: false
    default: ""
    description: "Build tool: 'maven' or 'gradle'. Auto-detected."
tags:
  - java
  - spring-boot
  - junit5
  - mockito
  - testing
  - coverage
  - remediation
invocation: tw-java-test-remediator
---

# java-test-remediator

## Description

Turns a Java/Spring Boot test governance report into code. Reads the output of
`/tw-java-test-governor`, assigns a Jacoco coverage tier (A / B / C) to each class,
then generates new test classes (`create-test`) or repairs broken ones (`update-test`).
Runs the targeted tests after each change and produces a Jacoco coverage summary table.

**This skill is for remediation only — not for discovery.** Run `/tw-java-test-governor` first.

**Spring Boot conventions respected:**
- `@Service` classes → `@ExtendWith(MockitoExtension.class)` + `@InjectMocks` + `@Mock`
- `@RestController` classes → `@WebMvcTest` slice test with `MockMvc`
- `@Repository` classes → `@DataJpaTest` with H2 in-memory database
- Domain classes with no Spring → plain JUnit 5 with no extensions

## Instructions

### Step 1 — Parse Governance Report

```bash
report=$(ls TEST_GOVERNANCE_REPORT_*.md 2>/dev/null | tail -1)
```

Extract `create-test` and `update-test` targets. For each, identify:
- Full class name and package
- Spring stereotype (from the report or by reading the class)
- Number of methods and branches
- Existing test file (for `update-test`)

### Step 2 — Assign Coverage Tiers

| Tier | Class type | Line coverage target |
|---|---|---|
| **A** | @Service with @Transactional, domain logic, validators, mappers | ≥ 90% |
| **B** | @RestController, adapters, repository adapters, error handlers | ≥ 80% |
| **C** | @Component helpers, simple transformers, low branching | ≥ 70% |

### Step 3 — Read Source Before Writing

For each class to remediate:
1. Read the production class — understand public methods, injected dependencies, exception types
2. Read the existing test file (if `update-test`) — understand what is already tested
3. Read `pom.xml` or `build.gradle` — verify Mockito, AssertJ, and Spring Test versions

### Step 4 — Generate Tests by Spring Pattern

#### Pattern A — @Service with Mockito

```java
// OrderServiceTest.java
package com.example.orders;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderService unit tests")
class OrderServiceTest {

    @InjectMocks
    private OrderService orderService;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private PaymentGateway paymentGateway;

    // Test data — deterministic, no random values
    private static final Long VALID_ORDER_ID   = 1L;
    private static final BigDecimal VALID_AMOUNT = BigDecimal.valueOf(150.00);

    @Nested
    @DisplayName("placeOrder")
    class PlaceOrder {

        @Test
        @DisplayName("should create order when inputs are valid")
        void shouldCreateOrderWhenValid() {
            // Arrange
            var request = new OrderRequest(VALID_AMOUNT, "USD");
            var savedOrder = new Order(VALID_ORDER_ID, VALID_AMOUNT, OrderStatus.CONFIRMED);
            when(orderRepository.save(any(Order.class))).thenReturn(savedOrder);

            // Act
            var result = orderService.placeOrder(request);

            // Assert
            assertThat(result.getId()).isEqualTo(VALID_ORDER_ID);
            assertThat(result.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
            verify(orderRepository).save(any(Order.class));
            verify(paymentGateway).authorize(VALID_AMOUNT, "USD");
        }

        @Test
        @DisplayName("should throw when amount is zero")
        void shouldThrowWhenAmountIsZero() {
            var request = new OrderRequest(BigDecimal.ZERO, "USD");

            assertThatThrownBy(() -> orderService.placeOrder(request))
                .isInstanceOf(InvalidOrderException.class)
                .hasMessageContaining("Amount must be positive");

            verifyNoInteractions(orderRepository, paymentGateway);
        }

        @ParameterizedTest(name = "should reject negative amount: {0}")
        @ValueSource(doubles = {-1.0, -100.0, -0.001})
        @DisplayName("should reject negative amounts")
        void shouldRejectNegativeAmounts(double negativeAmount) {
            var request = new OrderRequest(BigDecimal.valueOf(negativeAmount), "USD");

            assertThatThrownBy(() -> orderService.placeOrder(request))
                .isInstanceOf(InvalidOrderException.class);
        }
    }
}
```

#### Pattern B — @RestController with MockMvc

```java
// OrderControllerTest.java
@WebMvcTest(OrderController.class)
@DisplayName("OrderController integration tests")
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("POST /api/orders — should return 201 when order is created")
    void shouldReturn201WhenOrderCreated() throws Exception {
        var request = new OrderRequest(BigDecimal.valueOf(150), "USD");
        var response = new OrderResponse(1L, "CONFIRMED");
        when(orderService.placeOrder(any())).thenReturn(response);

        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(1L))
            .andExpect(jsonPath("$.status").value("CONFIRMED"));
    }

    @Test
    @DisplayName("POST /api/orders — should return 400 when body is missing")
    void shouldReturn400WhenBodyMissing() throws Exception {
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isBadRequest());
    }
}
```

#### Pattern C — @Repository with @DataJpaTest

```java
// OrderRepositoryTest.java
@DataJpaTest
@DisplayName("OrderRepository tests")
class OrderRepositoryTest {

    @Autowired
    private OrderRepository orderRepository;

    @Test
    @DisplayName("findByStatusAndCreatedAfter — should return only matching orders")
    void shouldReturnMatchingOrders() {
        // Arrange — use @Sql or direct save for test data
        var order = orderRepository.save(new Order(BigDecimal.valueOf(100), OrderStatus.PENDING));

        // Act
        var found = orderRepository.findByStatusAndCreatedAfter(
            OrderStatus.PENDING, LocalDateTime.now().minusHours(1));

        // Assert
        assertThat(found).hasSize(1);
        assertThat(found.get(0).getId()).isEqualTo(order.getId());
    }
}
```

### Step 5 — Verify After Each Class

**Maven:**
```bash
mvn test -pl . -Dtest=OrderServiceTest -q 2>&1 | tail -20
mvn jacoco:report -q
```

**Gradle:**
```bash
./gradlew test --tests "*.OrderServiceTest" -q
./gradlew jacocoTestReport
```

Parse Jacoco XML output for the remediated class and record line coverage %.

### Step 6 — Produce Remediation Summary

```markdown
| Class | Tier | Line coverage (after) | Meets target? | Notes |
|---|---|---|---|---|
| OrderService | A | 93% | ✅ Yes | All branches covered |
| PaymentMapper | B | 78% | ⚠️ No (80%) | Error path needs MockMvc test |
```

## Examples

### Example 1 — Remediate from latest governance report

```
/tw-java-test-remediator
```

### Example 2 — Full Java governance + remediation flow

```
/tw-java-test-governor base_ref=origin/main jacoco_xml=target/site/jacoco/jacoco.xml
/tw-java-test-remediator
```

## Dependencies

- Output from `/tw-java-test-governor`
- Java 11+ and Maven or Gradle in PATH
- JUnit 5, Mockito, AssertJ, Spring Test in project dependencies
- `ripgrep` for scanning source files

## Notes

- For `@Repository` tests, `@DataJpaTest` spins up an H2 in-memory DB by default
- For classes with real external dependencies (Kafka, S3, Redis), use `@MockBean` or WireMock
- Never use `@SpringBootTest` for unit tests — it loads the full context and slows tests 10x
- If the project uses Kotlin, adapt the generated syntax to Kotlin (data classes, extension functions)
